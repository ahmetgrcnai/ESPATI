import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../../viewmodels/notification_viewmodel.dart';

/// Dedicated notification screen with full list and 'Mark all as read' button.
///
/// All state is managed by [NotificationViewModel].
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Consumer<NotificationViewModel>(
            builder: (context, vm, _) {
              if (vm.notifications.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => vm.markAllAsRead(),
                icon: Icon(Icons.done_all_rounded,
                    size: 18, color: AppColors.primary),
                label: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, vm, _) {
          // ── Empty State ──
          if (vm.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_rounded,
                    size: 64,
                    color: AppColors.textPrimary.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Interact with posts and events to see\nnotifications appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Notification List ──
          return Column(
            children: [
              // Unread summary bar
              if (vm.hasUnread)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${vm.unreadCount} unread notification${vm.unreadCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: vm.notifications.length,
                  itemBuilder: (context, index) {
                    final notif = vm.notifications[index];
                    return _NotificationCard(
                      notification: notif,
                      onTap: () => vm.markAsRead(notif.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A single notification card styled to match the app theme.
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.like:
        return Icons.favorite_rounded;
      case NotificationType.comment:
        return Icons.chat_bubble_rounded;
      case NotificationType.event:
        return Icons.event_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.like:
        return AppColors.error;
      case NotificationType.comment:
        return AppColors.primary;
      case NotificationType.event:
        return AppColors.success;
      case NotificationType.system:
        return AppColors.warning;
    }
  }

  String _formatTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : AppColors.primaryLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(notification.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
