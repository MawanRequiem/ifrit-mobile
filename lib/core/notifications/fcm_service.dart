import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/core/network/api_endpoints.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';
import 'package:agniraksha_mobile/core/notifications/notification_service.dart';
import 'package:agniraksha_mobile/core/alarm/alarm_service.dart';
import 'package:agniraksha_mobile/core/router/app_router.dart';
import 'package:agniraksha_mobile/features/alerts/presentation/fire_alert_overlay.dart';

/// Firebase Cloud Messaging service that handles push notifications
/// in all app states: foreground, background, and terminated.
///
/// Architecture:
///   Backend → FCM/APNs → Device OS → onMessage/onBackgroundMessage
///                                         │
///                                         ▼
///                               Local notification tray
///                                         │
///                                         ▼
///                                   User tap → deep link

final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService(ref);

  // Watch auth state to register token after login or session restore
  ref.listen<AuthState>(
    authProvider,
    (prev, next) {
      if (next.status == AuthStatus.unauthenticated) {
        service._tokenRegistered = false;
      } else if (next.status == AuthStatus.authenticated &&
          (prev?.status != AuthStatus.authenticated || !service._tokenRegistered)) {
        debugPrint('[FCM] Auth state authenticated — ensuring token is registered');
        service.registerTokenIfNeeded();
      }
    },
    fireImmediately: true,
  );

  return service;
});

class FcmService {
  final Ref _ref;
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  FcmService(this._ref);

  bool _initialized = false;
  bool _tokenRegistered = false;

  /// Initialize Firebase and FCM — call once in main().
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await Firebase.initializeApp();

    // Initialize local notifications with tap handler
    await _ref.read(notificationServiceProvider).initialize(
      onNotificationTap: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            _handleNotificationTap(data);
          } catch (_) {}
        }
      },
    );

    // Request notification permission (iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
      provisional: false,
    );

    // Listen for token refreshes — auto re-register
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCM] Token refreshed: ${token.substring(0, 20)}...');
      _sendTokenToBackend(token);
    });

    // ── Foreground messages — show overlay immediately ──
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ── App opened from terminated via native FCM notification tap ──
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }

    // ── App opened from terminated via local notification (e.g. fullScreenIntent) ──
    final launchDetails = await _ref.read(notificationServiceProvider).getLaunchDetails();
    if (launchDetails != null && 
        launchDetails.didNotificationLaunchApp && 
        launchDetails.notificationResponse?.payload != null) {
      try {
        final data = jsonDecode(launchDetails.notificationResponse!.payload!);
        _handleNotificationTap(data);
      } catch (_) {}
    }

    // ── App in background → user taps notification ──
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data);
    });

  }

  /// Register device token with the backend — call after user is authenticated.
  Future<void> registerTokenIfNeeded() async {
    await _registerTokenWithRetry();
  }

  Future<void> _registerTokenWithRetry() async {
    if (_tokenRegistered) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('[FCM] No FCM token available yet');
        return;
      }
      debugPrint('[FCM] Got token: ${token.substring(0, 20)}...');
      await _sendTokenToBackend(token);
      _tokenRegistered = true;
    } catch (e) {
      debugPrint('[FCM] Failed to register token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    debugPrint('[FCM] Sending token to backend...');
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.dio.post(
        '${ApiEndpoints.apiPrefix}/device-tokens/register',
        data: {
          'fcm_token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        },
      );
      debugPrint('[FCM] Token registered — status ${response.statusCode}: ${response.data}');
    } catch (e) {
      debugPrint('[FCM] Failed to send token to backend: $e');
      // Retry once after 2s in case of transient failure
      await Future.delayed(const Duration(seconds: 2));
      try {
        final apiClient = _ref.read(apiClientProvider);
        await apiClient.dio.post(
          '${ApiEndpoints.apiPrefix}/device-tokens/register',
          data: {
            'fcm_token': token,
            'platform': defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
          },
        );
        debugPrint('[FCM] Token registered on retry');
        _tokenRegistered = true;
      } catch (e2) {
        debugPrint('[FCM] Retry also failed: $e2');
      }
    }
  }

  /// Handle foreground FCM message — show local notification + alarm + overlay.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    if (data['type'] == 'FIRE_ALERT') {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('app_lang') ?? 'en';

      final title = notification?.title ?? data['title_$lang'] ?? data['title'] ?? '🚨 Fire Alert';
      final body = notification?.body ?? data['body_$lang'] ?? data['body'] ?? 'Fire detected';

      // Start alarm siren + vibration (foreground app IS running)
      try {
        _ref.read(alarmServiceProvider).startAlarm(
          severity: data['severity'] ?? 'high',
        );
      } catch (_) {}

      // Also show local notification so user can tap if they minimize
      try {
        _ref.read(notificationServiceProvider).showFireAlert(
          title: title,
          body: body,
          payload: jsonEncode(data),
        );
      } catch (_) {}

      // Show the full-screen overlay immediately since the app IS in foreground
      _showOverlayWhenContextReady(data);
    }
  }

  /// Handle notification tap → navigate to relevant screen and show overlay.
  void _handleNotificationTap(Map<String, dynamic> data) {
    if (data['type'] == 'FIRE_ALERT') {
      final severity = data['severity'] as String? ?? 'critical';

      // Navigate and start alarm on next frame (after app is fully ready)
      _runWhenFrameReady(() {
        try {
          _ref.read(routerProvider).go('/alerts');
        } catch (_) {}
        try {
          _ref.read(alarmServiceProvider).startAlarm(severity: severity);
        } catch (_) {}
      });

      // Show overlay popup robustly (wait for context to be available if app just booted)
      _showOverlayWhenContextReady(data);
    }
  }

  /// Show the fire alert overlay once the navigator context is ready.
  /// Retries every 300ms for up to 15 seconds before giving up.
  void _showOverlayWhenContextReady(Map<String, dynamic> data, {int attempts = 0}) {
    const maxAttempts = 50; // 50 × 300ms = 15 seconds
    if (attempts > maxAttempts) {
      debugPrint('[FCM] Gave up waiting for navigator context after $maxAttempts attempts');
      return;
    }

    final navigator = rootNavigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      // Schedule after current frame so we never interfere with an in-progress build
      _runWhenFrameReady(() {
        try {
          navigator.push(
            DialogRoute(
              context: rootNavigatorKey.currentContext!,
              barrierDismissible: false,
              barrierColor: Colors.black87,
              builder: (_) => FireAlertOverlay(alertData: data),
            ),
          );
          debugPrint('[FCM] 🔴 FireAlertOverlay mounted successfully');
        } catch (e) {
          debugPrint('[FCM] FireAlertOverlay push failed: $e — retrying...');
          Future.delayed(const Duration(milliseconds: 300), () {
            _showOverlayWhenContextReady(data, attempts: attempts + 1);
          });
        }
      });
    } else {
      debugPrint('[FCM] Navigator not ready (attempt $attempts), retrying in 300ms...');
      Future.delayed(const Duration(milliseconds: 300), () {
        _showOverlayWhenContextReady(data, attempts: attempts + 1);
      });
    }
  }

  /// Execute a callback after the current frame (or immediately if scheduler is idle).
  void _runWhenFrameReady(VoidCallback callback) {
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.idle ||
        scheduler.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      callback();
    } else {
      scheduler.addPostFrameCallback((_) => callback());
    }
  }
}

/// Top-level background message handler — runs even when app is killed.
/// Must be a top-level function (not a method) for platform channel registration.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;
  final notification = message.notification;

  if (data['type'] == 'FIRE_ALERT') {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_lang') ?? 'en';

    final title = notification?.title ?? data['title_$lang'] ?? data['title'] ?? '🚨 Fire Alert';
    final body = notification?.body ?? data['body_$lang'] ?? data['body'] ?? 'Fire detected';

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidDetails = AndroidNotificationDetails(
      'fire_alerts',
      'Fire & Gas Alerts',
      channelDescription: 'Critical notifications for fire and gas leak detection',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
      payload: jsonEncode(data),
    );
  }
}
