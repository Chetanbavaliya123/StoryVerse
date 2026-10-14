import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/empty_state.dart';
import 'package:storyverse/core/models/notification_model.dart';
import 'package:storyverse/features/notifications/data/notification_repository.dart';

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationRepositoryProvider).streamNotifications();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.primaryAccent),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref.read(notificationRepositoryProvider).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'All notifications marked as read',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: AppColors.primarySurface,
                ),
              );
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          // Generate some fake demo notifications if empty for final project showcase
          // (Since we don't have a backend pushing them yet, this makes the demo look complete)

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationItem(context, ref, notif);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'No Notifications Yet',
        message: 'When new episodes, series releases, or recommendations are available, you will see them here.',
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
  ) {
    IconData getIcon() {
      switch (notif.type) {
        case 'new_episode':
          return Icons.play_circle_filled;
        case 'recommendation':
          return Icons.auto_awesome;
        case 'system':
          return Icons.system_update;
        default:
          return Icons.notifications;
      }
    }

    Color getColor() {
      switch (notif.type) {
        case 'new_episode':
          return Colors.blue;
        case 'recommendation':
          return Colors.amber;
        case 'system':
          return AppColors.primaryAccent;
        default:
          return Colors.white;
      }
    }

    return InkWell(
      onTap: () {
        if (!notif.isRead) {
          ref.read(notificationRepositoryProvider).markAsRead(notif.id);
        }
        if (notif.targetRoute != null) {
          context.push(notif.targetRoute!);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppColors.primarySurface
              : AppColors.primarySurface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? AppColors.border
                : AppColors.primaryAccent.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: getColor().withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(getIcon(), color: getColor(), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: TextStyle(
                      color: notif.isRead
                          ? AppColors.secondaryText
                          : Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _timeAgo(notif.createdAt ?? DateTime.now()),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
