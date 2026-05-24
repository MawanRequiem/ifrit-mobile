import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';
import 'package:agniraksha_mobile/core/theme/app_typography.dart';
import 'package:agniraksha_mobile/core/notifications/notification_service.dart';
import 'package:agniraksha_mobile/features/realtime/providers/realtime_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications system
    Future.microtask(() {
      ref.read(notificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time fire and gas alert stream to trigger local notifications
    ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeEventsProvider, (previous, next) {
      next.whenData((message) {
        if (message['type'] == 'FIRE_ALERT') {
          final alertData = message['data'] as Map<String, dynamic>?;
          if (alertData != null) {
            final roomName = alertData['room_name'] ?? 'Unknown Room';
            final riskLevel = alertData['risk_level'] ?? 'HIGH';
            final score = (alertData['fusion_score'] as num?)?.toDouble() ?? 0.0;
            final sensorSummary = alertData['sensor_summary'] ?? '';

            ref.read(notificationServiceProvider).showFireAlert(
              title: '🚨 FIRE ALERT: $roomName',
              body: 'Severity: ${riskLevel.toString().toUpperCase()} (${(score * 100).toStringAsFixed(0)}%)\n$sensorSummary',
            );
          }
        }
      });
    });

    final dashboard = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AgniRakhsa', style: Theme.of(context).textTheme.titleLarge),
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
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => _ErrorView(
            message: e.toString(),
            onRetry: () => ref.read(dashboardProvider.notifier).manualRefresh(),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
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
          ),
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
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(
          value: '${data.onlineDevices}/${data.totalDevices}',
          label: 'Devices Online',
          color: AppColors.safe,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(
          value: '${data.activeAlerts}',
          label: 'Active Alerts',
          color: data.activeAlerts > 0 ? AppColors.critical : AppColors.textMuted,
        )),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatTile({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.monoLarge.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: counts.entries.map((entry) {
          final meta = _statusMeta[entry.key];
          final color = meta?.color ?? AppColors.textMuted;
          final icon = meta?.icon ?? Icons.circle_outlined;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 10),
                Text(
                  entry.key.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${entry.value}',
                  style: AppTypography.mono.copyWith(color: color),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (isHigh ? AppColors.critical : AppColors.warning).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isHigh ? AppColors.critical : AppColors.warning).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHigh ? Icons.crisis_alert_rounded : Icons.warning_amber_rounded,
            size: 18,
            color: isHigh ? AppColors.critical : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk: ${riskLevel.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isHigh ? AppColors.critical : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fusion Score: $score',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
