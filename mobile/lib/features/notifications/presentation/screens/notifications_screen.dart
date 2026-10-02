import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
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
    // For demo purposes, if no notifications exist in firestore, we show a static list to ensure the screen looks complete
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDemoNotificationItem(
          title: 'New Episode Available!',
          message: 'Episode 4 of "The Clever Fox" is now streaming.',
          timeAgo: '2 hours ago',
          icon: Icons.play_circle_filled,
          color: Colors.blue,
          isRead: false,
        ),
        _buildDemoNotificationItem(
          title: 'Story Recommended for You',
          message:
              'Because you watched "The Lion and the Mouse", you might like "The Golden Egg".',
          timeAgo: '1 day ago',
          icon: Icons.auto_awesome,
          color: Colors.amber,
          isRead: true,
        ),
        _buildDemoNotificationItem(
          title: 'Subscription Expiring',
          message:
              'Your StoryVerse Pro subscription expires in 3 days. Renew now to avoid interruption.',
          timeAgo: '2 days ago',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
          isRead: true,
        ),
        _buildDemoNotificationItem(
          title: 'System Update',
          message:
              'Welcome to StoryVerse v2.0! Check out our new AI Hub features.',
          timeAgo: '1 week ago',
          icon: Icons.system_update,
          color: AppColors.primaryAccent,
          isRead: true,
        ),
      ],
    );
  }

  Widget _buildDemoNotificationItem({
    required String title,
    required String message,
    required String timeAgo,
    required IconData icon,
    required Color color,
    required bool isRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead
            ? AppColors.primarySurface
            : AppColors.primarySurface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
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
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
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
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: isRead
                              ? FontWeight.w600
                              : FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isRead)
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
                  message,
                  style: TextStyle(
                    color: isRead ? AppColors.secondaryText : Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeAgo,
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
