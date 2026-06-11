import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:agniraksha_mobile/core/theme/app_colors.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';
import 'package:agniraksha_mobile/features/profile/providers/profile_provider.dart';
import 'package:agniraksha_mobile/core/theme/theme_provider.dart';
import 'package:agniraksha_mobile/core/localization/lang_provider.dart';
import 'package:agniraksha_mobile/core/localization/app_translations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(profileProvider);
    final user = authState.user;

    final lang = ref.watch(langProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tr('profile', lang)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User Info Card ──────────────────────────────
          _Card(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.brand.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.email ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _RoleBadge(role: user?.role ?? 'user'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Settings Card ────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Settings'),
                const SizedBox(height: 12),
                _ThemeToggleTile(),
                const SizedBox(height: 8),
                _LanguageToggleTile(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Actions Card ─────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Account'),
                const SizedBox(height: 8),
                _ListTile(
                  icon: Icons.subscriptions_outlined,
                  title: 'Manage Subscriptions',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/subscriptions'),
                ),
                const Divider(),
                _ListTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  trailing: Text(
                    'v1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Logout Button ────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.critical,
                side: const BorderSide(color: AppColors.critical),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── App Branding ─────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  'AgniRakhsa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Industrial Fire & Gas Monitoring',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.brand;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ListTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Row(
      children: [
        Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Dark Mode',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Switch(
          value: isDark,
          onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
          activeColor: AppColors.brand,
        ),
      ],
    );
  }
}

class _LanguageToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);

    return Row(
      children: [
        Icon(
          Icons.language_rounded,
          size: 20,
          color: AppColors.of(context).textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppTranslations.tr('language', lang),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
        ),
        DropdownButton<String>(
          value: lang,
          underline: const SizedBox(),
          dropdownColor: AppColors.of(context).surface2,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.of(context).brand,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'id', child: Text('Bahasa')),
          ],
          onChanged: (String? newLang) {
            if (newLang != null) {
              ref.read(langProvider.notifier).setLang(newLang);
            }
          },
        ),
      ],
    );
  }
}