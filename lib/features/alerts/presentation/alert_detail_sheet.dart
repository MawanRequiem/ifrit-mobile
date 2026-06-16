import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/features/alerts/domain/alert_model.dart';
import 'package:agniraksha_mobile/features/alerts/providers/alerts_provider.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';
import 'package:agniraksha_mobile/core/theme/app_typography.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:agniraksha_mobile/core/localization/lang_provider.dart';
import 'package:agniraksha_mobile/core/localization/app_translations.dart';

/// Bottom sheet showing full details of an alert with action buttons.
class AlertDetailSheet extends ConsumerStatefulWidget {
  final AlertModel alert;
  final String? roomName;

  const AlertDetailSheet({
    super.key,
    required this.alert,
    this.roomName,
  });

  /// Show the bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required AlertModel alert,
    String? roomName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AlertDetailSheet(alert: alert, roomName: roomName),
    );
  }

  @override
  ConsumerState<AlertDetailSheet> createState() => _AlertDetailSheetState();
}

class _AlertDetailSheetState extends ConsumerState<AlertDetailSheet> {
  bool _isAcknowledging = false;

  AlertModel get alert => widget.alert;

  Color get _severityColor {
    switch (alert.severity) {
      case 'critical':
        return AppColors.critical;
      case 'high':
        return AppColors.critical;
      case 'warning':
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  IconData get _severityIcon {
    switch (alert.severity) {
      case 'critical':
        return Icons.crisis_alert_rounded;
      case 'high':
        return Icons.error_outline_rounded;
      case 'warning':
      case 'medium':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Future<void> _handleAcknowledge() async {
    if (_isAcknowledging) return;
    setState(() => _isAcknowledging = true);

    try {
      await ref.read(alertsProvider.notifier).acknowledge(alert.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isAcknowledging = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to acknowledge alert'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  void _handleViewRoom() {
    Navigator.of(context).pop();
    if (alert.roomId != null) {
      context.push('/rooms/${alert.roomId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    final isCritical = alert.severity == 'critical' || alert.severity == 'high';

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: ListView(
            controller: scrollController,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _severityColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(_severityIcon, color: _severityColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _severityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppTranslations.severity(alert.severity, lang),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _severityColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          alert.roomName ?? alert.alertType ?? 'Alert',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (alert.isAcknowledged)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.safe.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.safe.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.safe),
                          const SizedBox(width: 4),
                          Text(
                            AppTranslations.tr('badge_safe', lang),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.safe,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Message ──
              if (alert.message != null && alert.message!.isNotEmpty)
                Builder(
                  builder: (context) {
                    String displayText = alert.message!;
                    
                    // Try parsing as JSON from the backend
                    try {
                      final parsed = jsonDecode(alert.message!);
                      final explanation = parsed['explanation_$lang'];
                      final messageStr = parsed[lang];
                      if (explanation != null && explanation.toString().isNotEmpty) {
                        displayText = explanation;
                      } else if (messageStr != null) {
                        displayText = messageStr;
                      }
                    } catch (_) {}

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isCritical
                            ? AppColors.critical.withValues(alpha: 0.05)
                            : AppColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCritical
                              ? AppColors.critical.withValues(alpha: 0.15)
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        displayText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    );
                  }
                ),

              const SizedBox(height: 16),

              // ── Detection Image ──
              if (alert.imageUrl != null && alert.imageUrl!.isNotEmpty) ...[
                Text(
                  AppTranslations.tr('image_capture', lang),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      alert.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.surface2,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                              color: AppColors.brand,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (ctx, err, st) => Container(
                        color: AppColors.surface2,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined,
                                  size: 32, color: AppColors.textMuted),
                              SizedBox(height: 8),
                              Text(
                                'Image unavailable',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Details grid ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      label: AppTranslations.tr('location', lang),
                      value: alert.roomName ?? alert.roomId ?? '—',
                      icon: Icons.location_on_outlined,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    _DetailRow(
                      label: AppTranslations.tr('alert_type', lang),
                      value: (alert.alertType ?? '—').toUpperCase(),
                      icon: Icons.local_fire_department_outlined,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    _DetailRow(
                      label: AppTranslations.tr('device_id', lang),
                      value: alert.deviceId != null && alert.deviceId!.length >= 8
                          ? alert.deviceId!.substring(0, 8)
                          : (alert.deviceId ?? '—'),
                      icon: Icons.developer_board_outlined,
                      isMono: true,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    _DetailRow(
                      label: AppTranslations.tr('timestamp', lang),
                      value: _formatTimestamp(alert.createdAt),
                      icon: Icons.access_time_rounded,
                      isMono: true,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    _DetailRow(
                      label: AppTranslations.tr('status', lang),
                      value: alert.isAcknowledged
                          ? AppTranslations.tr('status_acknowledged', lang)
                          : AppTranslations.tr('status_active', lang),
                      icon: alert.isAcknowledged
                          ? Icons.verified_rounded
                          : Icons.pending_outlined,
                      valueColor: alert.isAcknowledged ? AppColors.safe : AppColors.warning,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Action buttons ──
              if (!alert.isAcknowledged)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isAcknowledging ? null : _handleAcknowledge,
                    icon: _isAcknowledging
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: Text(
                      _isAcknowledging
                          ? AppTranslations.tr('btn_acknowledging', lang)
                          : AppTranslations.tr('btn_acknowledge', lang),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safe,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              if (alert.roomId != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _handleViewRoom,
                    icon: const Icon(Icons.meeting_room_outlined, size: 18),
                    label: Text(
                      AppTranslations.tr('btn_view_room', lang),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      final time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
      final date =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

      if (diff.inMinutes < 1) return 'Just now ($time)';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago ($time)';
      if (diff.inHours < 24) return '${diff.inHours}h ago ($time)';
      return '$date $time';
    } catch (_) {
      return iso;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isMono;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isMono = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: (isMono ? AppTypography.monoSmall : Theme.of(context).textTheme.labelMedium)
                ?.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
