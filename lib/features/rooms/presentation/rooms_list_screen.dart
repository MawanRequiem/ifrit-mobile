import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:agniraksha_mobile/features/rooms/providers/rooms_provider.dart';
import 'package:agniraksha_mobile/features/rooms/domain/room_model.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';
import 'package:agniraksha_mobile/features/subscriptions/providers/subscriptions_provider.dart';
import 'package:agniraksha_mobile/features/rooms/presentation/room_detail_screen.dart';
import 'package:agniraksha_mobile/core/localization/lang_provider.dart';
import 'package:agniraksha_mobile/core/localization/app_translations.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';

class RoomsListScreen extends ConsumerStatefulWidget {
  const RoomsListScreen({super.key});

  @override
  ConsumerState<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends ConsumerState<RoomsListScreen> {
  String _searchQuery = '';
  Timer? _debounce;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsListProvider);
    final lang = ref.watch(langProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.tr('rooms', lang))),
      body: Column(
        children: [
          // ── Search Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: AppColors.of(context).surface1,
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                hintText: 'Search rooms...',
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
              ),
            ),
          ),

          // ── Room List ──
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brand,
              backgroundColor: AppColors.of(context).surface1,
              onRefresh: () => ref.refresh(roomsListProvider.future),
              child: roomsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Unable to load rooms',
                  subtitle: e.toString(),
                ),
                data: (rooms) {
                  final filtered = _searchQuery.isEmpty
                      ? rooms
                      : rooms.where((r) => r.name.toLowerCase().contains(_searchQuery)).toList();

                  if (rooms.isEmpty) {
                    final user = ref.watch(authProvider).user;
                    final isBasicUser = user?.role == 'user';
                    if (isBasicUser) {
                      return _EmptyState(
                        icon: Icons.meeting_room_outlined,
                        title: 'No rooms selected',
                        subtitle: 'Subscribe to rooms to monitor them here.',
                        actionLabel: 'Manage Subscriptions',
                        onAction: () => context.push('/subscriptions'),
                      );
                    }
                    return const _EmptyState(
                      icon: Icons.meeting_room_outlined,
                      title: 'No rooms configured',
                      subtitle: 'Add rooms from the web dashboard to see them here.',
                    );
                  }
                  if (filtered.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.search_rounded,
                      title: 'No rooms found',
                      subtitle: 'Try a different search term.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header with count
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                        child: Row(
                          children: [
                            Text(
                              'ALL ROOMS',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textMuted,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.brand.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${filtered.length}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.brand,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _RoomCard(room: filtered[index]),
                      ),
                    ],
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
      color: AppColors.of(context).surface1,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/rooms/${room.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Status LED with gradient glow
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
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
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MetaChip(
                          icon: Icons.developer_board_rounded,
                          label: '${room.deviceCount} nodes',
                        ),
                        const SizedBox(width: 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  room.status.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: AppColors.textMuted.withValues(alpha: 0.5)),
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
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
