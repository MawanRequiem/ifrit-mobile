import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';
import 'package:agniraksha_mobile/features/auth/presentation/login_screen.dart';
import 'package:agniraksha_mobile/features/auth/presentation/register_screen.dart';
import 'package:agniraksha_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:agniraksha_mobile/features/rooms/presentation/rooms_list_screen.dart';
import 'package:agniraksha_mobile/features/rooms/presentation/room_detail_screen.dart';
import 'package:agniraksha_mobile/features/alerts/presentation/alerts_screen.dart';
import 'package:agniraksha_mobile/features/profile/presentation/profile_screen.dart';
import 'package:agniraksha_mobile/features/subscriptions/presentation/manage_subscriptions_screen.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';
import 'package:agniraksha_mobile/core/theme/theme_provider.dart';
import 'package:agniraksha_mobile/core/localization/lang_provider.dart';
import 'package:agniraksha_mobile/core/localization/app_translations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = auth.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      // Still loading session — don't redirect yet
      if (auth.status == AuthStatus.unknown || auth.status == AuthStatus.loading) {
        return null;
      }

      if (!isLoggedIn && !isLoggingIn && !isRegistering) return '/login';
      if (isLoggedIn && (isLoggingIn || isRegistering)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/subscriptions',
        builder: (context, state) => const ManageSubscriptionsScreen(),
      ),
    ],
  );
});

class _PlaceholderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _PlaceholderAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Bottom navigation shell wrapping all authenticated screens.
class _AppShell extends ConsumerWidget {
  final Widget child;
  const _AppShell({required this.child});

  static const _tabs = [
    (icon: Icons.dashboard_rounded, label: 'Monitor'),
    (icon: Icons.meeting_room_outlined, label: 'Rooms'),
    (icon: Icons.notification_important_outlined, label: 'Alerts'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/rooms')) return 1;
    if (location.startsWith('/alerts')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _currentIndex(context);
    final lang = ref.watch(langProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
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
              case 3:
                context.go('/profile');
                break;
            }
          },
          items: _tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    label: AppTranslations.tr(t.label.toLowerCase(), lang),
                  ))
              .toList(),
        ),
      ),
    );
  }
}