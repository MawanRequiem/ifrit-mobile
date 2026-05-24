import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';
import 'package:agniraksha_mobile/features/auth/presentation/login_screen.dart';
import 'package:agniraksha_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:agniraksha_mobile/features/rooms/presentation/rooms_list_screen.dart';
import 'package:agniraksha_mobile/features/rooms/presentation/room_detail_screen.dart';
import 'package:agniraksha_mobile/features/alerts/presentation/alerts_screen.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = auth.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // Still loading session — don't redirect yet
      if (auth.status == AuthStatus.unknown || auth.status == AuthStatus.loading) {
        return null;
      }

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/rooms',
            builder: (context, state) => const RoomsListScreen(),
          ),
          GoRoute(
            path: '/rooms/:roomId',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return RoomDetailScreen(roomId: roomId);
            },
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Bottom navigation shell wrapping all authenticated screens.
class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  static const _tabs = [
    (icon: Icons.dashboard_rounded, label: 'Monitor'),
    (icon: Icons.meeting_room_outlined, label: 'Rooms'),
    (icon: Icons.notification_important_outlined, label: 'Alerts'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/rooms')) return 1;
    if (location.startsWith('/alerts')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) {
            switch (i) {
              case 0:
                context.go('/dashboard');
                break;
              case 1:
                context.go('/rooms');
                break;
              case 2:
                context.go('/alerts');
                break;
            }
          },
          items: _tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
