import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';
import 'package:agniraksha_mobile/features/subscriptions/data/subscriptions_repository.dart';
import 'package:agniraksha_mobile/features/subscriptions/providers/subscriptions_provider.dart';

class ManageSubscriptionsScreen extends ConsumerStatefulWidget {
  const ManageSubscriptionsScreen({super.key});

  @override
  ConsumerState<ManageSubscriptionsScreen> createState() =>
      _ManageSubscriptionsScreenState();
}

class _ManageSubscriptionsScreenState
    extends ConsumerState<ManageSubscriptionsScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load rooms when the screen opens
    Future.microtask(() {
      ref.read(subscriptionsProvider.notifier).loadAvailableRooms();
    });
  }

  Future<void> _saveSubscriptions() async {
    setState(() => _isSaving = true);

    final success =
        await ref.read(subscriptionsProvider.notifier).saveSubscriptions();

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscriptions saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final error = ref.read(subscriptionsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to save subscriptions'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.role.toLowerCase() == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subscriptions'),
      ),
      body: isAdmin ? _buildAdminMessage() : _buildSubscriptionList(),
      floatingActionButton: isAdmin
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveSubscriptions,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
            ),
    );
  }

  Widget _buildAdminMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              size: 64,
              color: AppColors.brand.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Admin Access',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'As an admin, you are subscribed to all rooms.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionList() {
    final state = ref.watch(subscriptionsProvider);

    if (state.isLoading && state.availableRooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.availableRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.critical.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(subscriptionsProvider.notifier).loadAvailableRooms();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.availableRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No rooms available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
      itemCount: state.availableRooms.length,
      itemBuilder: (context, index) {
        final room = state.availableRooms[index];
        final isSubscribed = state.subscribedRoomIds.contains(room.roomId);

        return _RoomTile(
          room: room,
          isSubscribed: isSubscribed,
          onToggle: () {
            ref.read(subscriptionsProvider.notifier).toggleRoom(room.roomId);
          },
        );
      },
    );
  }
}

class _RoomTile extends StatelessWidget {
  final AvailableRoom room;
  final bool isSubscribed;
  final VoidCallback onToggle;

  const _RoomTile({
    required this.room,
    required this.isSubscribed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isSubscribed,
      onChanged: (_) => onToggle(),
      title: Text(
        room.roomName,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
      ),
      subtitle: isSubscribed
          ? Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Subscribed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            )
          : null,
      secondary: isSubscribed
          ? Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade600,
            )
          : Icon(
              Icons.meeting_room_outlined,
              color: AppColors.textMuted,
            ),
      activeColor: AppColors.brand,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}