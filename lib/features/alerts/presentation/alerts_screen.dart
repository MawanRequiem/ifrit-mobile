import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/features/alerts/providers/alerts_provider.dart';
import 'package:agniraksha_mobile/features/alerts/domain/alert_model.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';
import 'package:agniraksha_mobile/core/theme/app_typography.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: Column(
        children: [
          // ── Filter Chips ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.surface1,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isActive: alertsState.severityFilter == null,
                  onTap: () => ref.read(alertsProvider.notifier).setSeverityFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Warning',
                  isActive: alertsState.severityFilter == 'warning',
                  color: AppColors.warning,
                  onTap: () => ref.read(alertsProvider.notifier).setSeverityFilter('warning'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Critical',
                  isActive: alertsState.severityFilter == 'critical',
                  color: AppColors.critical,
                  onTap: () => ref.read(alertsProvider.notifier).setSeverityFilter('critical'),
                ),
              ],
            ),
          ),

          // ── Alert List ──
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brand,
              backgroundColor: AppColors.surface1,
              onRefresh: () => ref.read(alertsProvider.notifier).fetchAlerts(),
              child: alertsState.items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 48, color: AppColors.safe),
                              const SizedBox(height: 16),
                              Text(
                                'No active alerts',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'All systems nominal',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: alertsState.items.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _AlertTile(
                          alert: alertsState.items[index],
                          onAcknowledge: () {
                            ref.read(alertsProvider.notifier)
                                .acknowledge(alertsState.items[index].id);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
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
    final activeColor = color ?? AppColors.brand;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.4) : AppColors.border,
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
  final VoidCallback onAcknowledge;
  const _AlertTile({required this.alert, required this.onAcknowledge});

  Color get _severityColor {
    switch (alert.severity) {
      case 'critical': return AppColors.critical;
      case 'high':     return AppColors.critical;
      case 'warning':  return AppColors.warning;
      case 'medium':   return AppColors.warning;
      default:         return AppColors.info;
    }
  }

  IconData get _severityIcon {
    switch (alert.severity) {
      case 'critical': return Icons.crisis_alert_rounded;
      case 'high':     return Icons.error_outline_rounded;
      case 'warning':  return Icons.warning_amber_rounded;
      default:         return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = _formatTimestamp(alert.createdAt);

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.safe.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.check_rounded, color: AppColors.safe),
      ),
      onDismissed: (_) => onAcknowledge(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_severityIcon, size: 20, color: _severityColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _severityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (alert.severity ?? 'info').toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _severityColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
