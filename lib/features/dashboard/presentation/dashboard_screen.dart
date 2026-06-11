import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:agniraksha_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';
import 'package:agniraksha_mobile/features/subscriptions/providers/subscriptions_provider.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';
import 'package:agniraksha_mobile/core/theme/app_typography.dart';
import 'package:agniraksha_mobile/core/notifications/notification_service.dart';
import 'package:agniraksha_mobile/core/alarm/alarm_service.dart';
import 'package:agniraksha_mobile/features/alerts/presentation/fire_alert_overlay.dart';
import 'package:agniraksha_mobile/features/realtime/providers/realtime_provider.dart';
import 'package:agniraksha_mobile/core/localization/lang_provider.dart';
import 'package:agniraksha_mobile/core/localization/app_translations.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationServiceProvider).initialize();
      // Pre-load subscriptions so WebSocket filtering works
      ref.read(subscriptionsProvider.notifier).loadAvailableRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isBasicUser = user?.role == 'user';
    final subState = ref.watch(subscriptionsProvider);
    final hasSubscriptions = subState.subscribedRoomIds.isNotEmpty;
    final lang = ref.watch(langProvider);

    // Listen to filtered real-time fire and gas alert stream
    // Triggers: 1) Loud siren + vibration  2) Full-screen overlay  3) Local notification (fallback)
    ref.listen<AsyncValue<Map<String, dynamic>>>(filteredRealtimeEventsProvider, (previous, next) {
      next.whenData((message) {
        if (message['type'] == 'FIRE_ALERT') {
          final alertData = message['data'] as Map<String, dynamic>?;
          if (alertData != null) {
            final roomName = alertData['room_name'] ?? 'Unknown Room';
            final riskLevel = alertData['risk_level'] ?? 'HIGH';
            final severity = alertData['severity'] as String? ?? 'high';
            final score = (alertData['fusion_score'] as num?)?.toDouble() ?? 0.0;
            final sensorSummary = alertData['sensor_summary'] ?? '';

            // 1) Start loud siren + continuous vibration
            ref.read(alarmServiceProvider).startAlarm(severity: severity);

            // 2) Show full-screen fire alert overlay (must interact to dismiss)
            if (mounted) {
              FireAlertOverlay.show(context, alertData);
            }

            // 3) Local notification as fallback (for when app is backgrounded)
            ref.read(notificationServiceProvider).showFireAlert(
              title: '🚨 FIRE ALERT: $roomName',
              body: 'Severity: ${riskLevel.toString().toUpperCase()} (${(score * 100).toStringAsFixed(0)}%)\n$sensorSummary',
            );
          }
        }
      });
    });

    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AgniRakhsa', style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            )),
            if (user != null)
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: AppColors.surface1,
        onRefresh: () => ref.read(dashboardProvider.notifier).manualRefresh(),
        child: dashboard.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brand),
          ),
          error: (e, _) => _ErrorView(
            message: e.toString(),
            onRetry: () => ref.read(dashboardProvider.notifier).manualRefresh(),
          ),
          data: (data) {
            // Empty state for basic users with no subscriptions
            if (isBasicUser && data.totalRooms == 0) {
              return _NoSubscriptionsView(
                onManage: () => context.push('/subscriptions'),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // ── Subscription banner for basic users ──
                if (isBasicUser && !hasSubscriptions) ...[
                  _SubscriptionBanner(
                    onTap: () => context.push('/subscriptions'),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── System Overview ──
                _SectionLabel(label: 'SYSTEM OVERVIEW'),
                const SizedBox(height: 12),
                _StatsGrid(data: data),

                const SizedBox(height: 28),

                // ── Room Status ──
                _SectionLabel(label: 'ROOM STATUS'),
                const SizedBox(height: 12),
                _RoomStatusBreakdown(counts: data.roomStatusCounts),

                const SizedBox(height: 28),

                // ── Recent Critical Events ──
                if (data.recentCriticalEvents.isNotEmpty) ...[
                  _SectionLabel(label: 'RECENT EVENTS'),
                  const SizedBox(height: 12),
                  ...data.recentCriticalEvents.map(
                    (e) => _EventTile(event: e),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Section Label ───────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Stats Grid ──────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final dynamic data;
  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatTile(
          value: '${data.totalRooms}',
          label: 'Rooms',
          color: AppColors.info,
          gradientColors: [
            AppColors.info.withValues(alpha: 0.15),
            AppColors.info.withValues(alpha: 0.02),
          ],
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(
          value: '${data.onlineDevices}/${data.totalDevices}',
          label: 'Devices Online',
          color: AppColors.safe,
          gradientColors: [
            AppColors.safe.withValues(alpha: 0.15),
            AppColors.safe.withValues(alpha: 0.02),
          ],
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(
          value: '${data.activeAlerts}',
          label: 'Active Alerts',
          color: data.activeAlerts > 0 ? AppColors.critical : AppColors.textMuted,
          gradientColors: [
            (data.activeAlerts > 0 ? AppColors.critical : AppColors.textMuted).withValues(alpha: 0.12),
            (data.activeAlerts > 0 ? AppColors.critical : AppColors.textMuted).withValues(alpha: 0.01),
          ],
        )),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final List<Color> gradientColors;
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.monoLarge.copyWith(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Room Status Breakdown ───────────────────────────────────
class _RoomStatusBreakdown extends StatelessWidget {
  final Map<String, int> counts;
  const _RoomStatusBreakdown({required this.counts});

  static const _statusMeta = {
    'safe':     (color: AppColors.safe,     icon: Icons.check_circle_outline_rounded),
    'low':      (color: AppColors.info,     icon: Icons.info_outline_rounded),
    'medium':   (color: AppColors.warning,  icon: Icons.warning_amber_rounded),
    'high':     (color: AppColors.critical, icon: Icons.error_outline_rounded),
    'critical': (color: AppColors.critical, icon: Icons.crisis_alert_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (sum, v) => sum + v);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: counts.entries.map((entry) {
          final meta = _statusMeta[entry.key];
          final color = meta?.color ?? AppColors.textMuted;
          final icon = meta?.icon ?? Icons.circle_outlined;
          final fraction = total > 0 ? entry.value / total : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.key.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Progress bar
                SizedBox(
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${entry.value}',
                    textAlign: TextAlign.right,
                    style: AppTypography.mono.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Event Tile ──────────────────────────────────────────────
class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final riskLevel = event['risk_level'] as String? ?? 'unknown';
    final score = (event['fusion_score'] as num?)?.toStringAsFixed(2) ?? '--';
    final isHigh = riskLevel == 'high' || riskLevel == 'critical';
    final color = isHigh ? AppColors.critical : AppColors.warning;
    final icon = isHigh ? Icons.crisis_alert_rounded : Icons.warning_amber_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'RISK: ${riskLevel.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SCORE $score',
                        style: AppTypography.monoSmall.copyWith(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (event['room_name'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event['room_name'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: color.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

// ── Subscription Banner ───────────────────────────────────
class _SubscriptionBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SubscriptionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.brand.withValues(alpha: 0.12),
              AppColors.info.withValues(alpha: 0.08),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: AppColors.brand, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Up Room Subscriptions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Choose which rooms you want to monitor',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── No Subscriptions Empty State ────────────────────────────
class _NoSubscriptionsView extends StatelessWidget {
  final VoidCallback onManage;
  const _NoSubscriptionsView({required this.onManage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 36,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Rooms Selected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select the rooms you want to monitor to see their status and receive alerts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onManage,
                icon: const Icon(Icons.checklist_rounded, size: 20),
                label: const Text('Choose Rooms'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View ──────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
