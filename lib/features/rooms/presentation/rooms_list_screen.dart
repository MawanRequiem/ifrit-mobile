import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:agniraksha_mobile/features/rooms/providers/rooms_provider.dart';
import 'package:agniraksha_mobile/features/rooms/domain/room_model.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';

class RoomsListScreen extends ConsumerWidget {
  const RoomsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: AppColors.surface1,
        onRefresh: () => ref.refresh(roomsListProvider.future),
        child: roomsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Unable to load rooms',
            subtitle: e.toString(),
          ),
          data: (rooms) {
            if (rooms.isEmpty) {
              return const _EmptyState(
                icon: Icons.meeting_room_outlined,
                title: 'No rooms configured',
                subtitle: 'Add rooms from the web dashboard to see them here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: rooms.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _RoomCard(room: rooms[index]),
            );
          },
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  const _RoomCard({required this.room});

  Color get _statusColor {
    switch (room.status) {
      case 'safe':     return AppColors.safe;
      case 'low':      return AppColors.info;
      case 'medium':   return AppColors.warning;
      case 'high':     return AppColors.critical;
      case 'critical': return AppColors.critical;
      default:         return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface1,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/rooms/${room.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Status LED
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Room info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _MetaChip(
                          icon: Icons.developer_board_rounded,
                          label: '${room.deviceCount} nodes',
                        ),
                        const SizedBox(width: 12),
                        _MetaChip(
                          icon: Icons.sensors_rounded,
                          label: '${room.sensorCount} sensors',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  room.status.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
        )),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            )),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
