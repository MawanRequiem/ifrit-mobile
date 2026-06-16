import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/features/alerts/providers/alerts_provider.dart';
import 'package:agniraksha_mobile/features/alerts/domain/alert_model.dart';
import 'package:agniraksha_mobile/features/alerts/presentation/alert_detail_sheet.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';
import 'package:agniraksha_mobile/core/theme/app_typography.dart';
import 'package:agniraksha_mobile/core/localization/lang_provider.dart';
import 'package:agniraksha_mobile/core/localization/app_translations.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  String _searchQuery = '';
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim().toLowerCase());
      ref.read(alertsProvider.notifier).setSearchQuery(value.trim().toLowerCase());
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    ref.read(alertsProvider.notifier).setSearchQuery(null);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsProvider);
    final lang = ref.watch(langProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.tr('alerts', lang))),
      body: Column(
        children: [
          // ── Filter Chips ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface1,
              border: Border(bottom: BorderSide(color: AppColors.of(context).border)),
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: AppTranslations.tr('filter_all', lang),
                  isActive: alertsState.severityFilter == null,
                  onTap: () => ref.read(alertsProvider.notifier).setSeverityFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppTranslations.tr('filter_warning', lang),
                  isActive: alertsState.severityFilter == 'warning',
                  color: AppColors.of(context).warning,
                  onTap: () => ref.read(alertsProvider.notifier).setSeverityFilter('warning'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppTranslations.tr('filter_critical', lang),
                  isActive: alertsState.severityFilter == 'critical',
                  color: AppColors.of(context).critical,
                  onTap: () => ref.read(alertsProvider.notifier).setSeverityFilter('critical'),
                ),
              ],
            ),
          ),

          // ── Search Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: AppColors.of(context).surface1,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                hintText: AppTranslations.tr('search_alerts', lang),
                filled: true,
                fillColor: AppColors.of(context).surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.brand.withValues(alpha: 0.4), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
            ),
          ),

          // ── Alert List ──
          Expanded(
            child: RefreshIndicator(
              color: AppColors.of(context).brand,
              backgroundColor: AppColors.of(context).surface1,
              onRefresh: () => ref.read(alertsProvider.notifier).fetchAlerts(),
              child: alertsState.isLoading && alertsState.items.isEmpty
                  ? Center(child: CircularProgressIndicator(color: AppColors.of(context).brand))
                  : alertsState.items.isEmpty
                      ? _buildEmptyState(context)
                      : _buildAlertList(alertsState, context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isBasicUser = user?.role == 'user';
    final lang = ref.watch(langProvider);

    if (isBasicUser) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                const Icon(Icons.notifications_off_outlined,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  AppTranslations.tr('no_alerts_sub', lang),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppTranslations.tr('subscribe_rooms', lang),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 48, color: AppColors.safe),
              const SizedBox(height: 16),
              Text(
                AppTranslations.tr('no_alerts', lang),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppTranslations.tr('all_nominal', lang),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertList(AlertsState alertsState, BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? alertsState.items
        : alertsState.items.where((a) {
            final message = a.message?.toLowerCase() ?? '';
            final alertType = a.alertType?.toLowerCase() ?? '';
            return message.contains(_searchQuery) || alertType.contains(_searchQuery);
          }).toList();

    final lang = ref.watch(langProvider);
    if (filtered.isEmpty && _searchQuery.isNotEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                const Icon(Icons.search_rounded, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  AppTranslations.tr('no_alerts_found', lang),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppTranslations.tr('try_different', lang),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _AlertTile(
          alert: filtered[index],
          lang: lang,
          onTap: () {
            AlertDetailSheet.show(
              context,
              alert: filtered[index],
            );
          },
          onAcknowledge: () {
            final alert = filtered[index];
            ref.read(alertsProvider.notifier).acknowledge(alert.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppTranslations.tr('btn_acknowledge', lang)),
                backgroundColor: AppColors.safe,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: AppTranslations.tr('btn_view_room', lang),
                  textColor: Colors.white,
                  onPressed: () {
                    AlertDetailSheet.show(
                      context,
                      alert: alert,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.of(context).brand;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : AppColors.of(context).surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.5) : AppColors.of(context).border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isActive ? activeColor : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;
  final VoidCallback onAcknowledge;
  final String lang;
  const _AlertTile({
    required this.alert,
    required this.onTap,
    required this.onAcknowledge,
    required this.lang,
  });

  Color _severityColor(BuildContext context) {
    final colors = AppColors.of(context);
    switch (alert.severity?.toLowerCase()) {
      case 'critical': return colors.critical;
      case 'high':     return colors.critical;
      case 'warning':  return colors.warning;
      case 'medium':   return colors.warning;
      case 'low':      return colors.info;
      default:         return colors.info;
    }
  }

  IconData get _severityIcon {
    switch (alert.severity?.toLowerCase()) {
      case 'critical': return Icons.crisis_alert_rounded;
      case 'high':     return Icons.error_outline_rounded;
      case 'warning':  return Icons.warning_amber_rounded;
      default:         return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = _formatTimestamp(alert.createdAt);
    final isCritical = alert.severity == 'critical' || alert.severity == 'high';
    final unacknowledged = !alert.isAcknowledged;
    final sevColor = _severityColor(context);

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.of(context).safe.withValues(alpha: 0.0),
              AppColors.of(context).safe.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: AppColors.of(context).safe, size: 20),
            const SizedBox(width: 6),
            Text(
              AppTranslations.tr('swipe_acknowledge', lang),
              style: TextStyle(
                color: AppColors.of(context).safe,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onAcknowledge();
        return true;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCritical && unacknowledged
                  ? sevColor.withValues(alpha: 0.05)
                  : AppColors.of(context).surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCritical && unacknowledged
                    ? sevColor.withValues(alpha: 0.2)
                    : AppColors.of(context).border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread dot
                if (unacknowledged) ...[
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4, right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sevColor,
                      boxShadow: [
                        BoxShadow(
                          color: sevColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],

                // Severity icon in rounded box with background
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_severityIcon, size: 18, color: sevColor),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: sevColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppTranslations.severity(alert.severity, lang),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: sevColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (unacknowledged) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: sevColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppTranslations.tr('badge_new', lang),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: sevColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            timestamp,
                            style: AppTypography.monoSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert.message ?? alert.alertType ?? 'Alert',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tap indicator
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return AppTranslations.tr('just_now', lang);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
