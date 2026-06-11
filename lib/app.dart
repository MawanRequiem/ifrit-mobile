import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/notifications/fcm_service.dart';
import 'features/auth/providers/auth_provider.dart';

class AgniRakhsaApp extends ConsumerStatefulWidget {
  const AgniRakhsaApp({super.key});

  @override
  ConsumerState<AgniRakhsaApp> createState() => _AgniRakhsaAppState();
}

class _AgniRakhsaAppState extends ConsumerState<AgniRakhsaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'AgniRakhsa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
