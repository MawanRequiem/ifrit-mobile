import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/core/alarm/alarm_service.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';
import 'package:agniraksha_mobile/core/theme/app_typography.dart';
import 'package:agniraksha_mobile/features/alerts/providers/alerts_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Full-screen fire alert overlay that demands user interaction.
/// Cannot be dismissed with back button — must tap Acknowledge or View Room.
class FireAlertOverlay extends ConsumerStatefulWidget {
  final Map<String, dynamic> alertData;

  const FireAlertOverlay({super.key, required this.alertData});

  /// Show the overlay as a modal dialog.
  static Future<void> show(BuildContext context, Map<String, dynamic> alertData) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => FireAlertOverlay(alertData: alertData),
    );
  }

  @override
  ConsumerState<FireAlertOverlay> createState() => _FireAlertOverlayState();
}

class _FireAlertOverlayState extends ConsumerState<FireAlertOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAcknowledging = false;

  String get _roomName => widget.alertData['room_name'] as String? ?? 'Unknown Room';
  String get _severity => widget.alertData['severity'] as String? ?? 'high';
  String get _riskLevel => widget.alertData['risk_level'] as String? ?? 'HIGH';
  double get _fusionScore => (widget.alertData['fusion_score'] as num?)?.toDouble() ?? 0.0;
  String? get _imageUrl => widget.alertData['image_url'] as String?;
  String? get _sensorSummary => widget.alertData['sensor_summary'] as String?;
  String? get _alertId => widget.alertData['alert_id'] as String?;
  String? get _roomId => widget.alertData['room_id'] as String?;
  String get _timestamp => widget.alertData['timestamp'] as String? ?? '';

  bool get _isCritical => _severity == 'critical';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAcknowledge() async {
    if (_isAcknowledging) return;
    setState(() => _isAcknowledging = true);

    // Acknowledge via API if we have an alert ID
    if (_alertId != null) {
      try {
        await ref.read(alertsRepositoryProvider).acknowledgeAlert(_alertId!);
      } catch (_) {
        // Continue even if API call fails — stopping the alarm is priority
      }
    }

    // Stop the alarm
    ref.read(alarmServiceProvider).stopAlarm();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleViewRoom() {
    // Stop the alarm
    ref.read(alarmServiceProvider).stopAlarm();

    Navigator.of(context).pop();

    if (_roomId != null) {
      context.push('/rooms/$_roomId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Cannot dismiss with back button
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final pulseValue = _pulseAnimation.value;

          return Dialog.fullscreen(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isCritical
                      ? [
                          Color.lerp(
                            const Color(0xFF3D0A0A),
                            const Color(0xFF5C1010),
                            pulseValue,
                          )!,
                          const Color(0xFF0D0F14),
                        ]
                      : [
                          Color.lerp(
                            const Color(0xFF3D2A0A),
                            const Color(0xFF5C3E10),
                            pulseValue,
                          )!,
                          const Color(0xFF0D0F14),
                        ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // ── Pulsing alert icon ──
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, _) {
                          return Transform.scale(
                            scale: 0.9 + pulseValue * 0.15,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (_isCritical ? AppColors.critical : AppColors.warning)
                                    .withValues(alpha: 0.15 + pulseValue * 0.1),
                                border: Border.all(
                                  color: (_isCritical ? AppColors.critical : AppColors.warning)
                                      .withValues(alpha: 0.4 + pulseValue * 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isCritical ? AppColors.critical : AppColors.warning)
                                        .withValues(alpha: pulseValue * 0.3),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isCritical
                                    ? Icons.local_fire_department_rounded
                                    : Icons.warning_amber_rounded,
                                size: 48,
                                color: _isCritical ? AppColors.critical : AppColors.warning,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // ── Title ──
                      Text(
                        _isCritical ? '🔴 KEBAKARAN KRITIS' : '🟠 PERINGATAN API',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _isCritical ? AppColors.critical : AppColors.warning,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // ── Room name ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _roomName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Stats row ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatChip(
                            label: 'SEVERITY',
                            value: _riskLevel.toUpperCase(),
                            color: _isCritical ? AppColors.critical : AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            label: 'SCORE',
                            value: '${(_fusionScore * 100).toStringAsFixed(0)}%',
                            color: AppColors.brand,
                          ),
                        ],
                      ),

                      if (_sensorSummary != null && _sensorSummary!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface1,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _sensorSummary!,
                            style: AppTypography.monoSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],

                      // ── Detection image ──
                      if (_imageUrl != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 160),
                            child: _imageUrl!.toLowerCase().endsWith('.svg')
                                ? SvgPicture.network(
                                    _imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholderBuilder: (ctx) => const Center(child: CircularProgressIndicator()),
                                  )
                                : Image.network(
                                    _imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
                                  ),
                          ),
                        ),
                      ],

                      // ── Timestamp ──
                      if (_timestamp.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _formatTimestamp(_timestamp),
                          style: AppTypography.monoSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],

                      const Spacer(flex: 2),

                      // ── Action buttons ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isAcknowledging ? null : _handleAcknowledge,
                          icon: _isAcknowledging
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline_rounded, size: 22),
                          label: Text(
                            _isAcknowledging ? 'ACKNOWLEDGING...' : 'ACKNOWLEDGE & SILENCE',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              fontSize: 14,
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

                      const SizedBox(height: 12),

                      if (_roomId != null)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _handleViewRoom,
                            icon: const Icon(Icons.meeting_room_outlined, size: 20),
                            label: const Text(
                              'VIEW ROOM DETAIL',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: TextButton(
                          onPressed: () {
                            ref.read(alarmServiceProvider).stopAlarm();
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'SILENCE ALARM ONLY',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return 'Detected at $h:$m:$s';
    } catch (_) {
      return '';
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.0,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.monoLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
