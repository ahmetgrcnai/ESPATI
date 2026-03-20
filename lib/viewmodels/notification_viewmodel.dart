import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';

/// ViewModel for the notification system.
///
/// Manages list of notifications, unread count, and provides
/// methods to add/read/clear notifications.
class NotificationViewModel extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  /// Number of unread notifications.
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Whether there are any unread notifications.
  bool get hasUnread => unreadCount > 0;

  /// Adds a notification to the top of the list.
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// Marks a single notification as read.
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Marks all notifications as read.
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  /// Clears all notifications.
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Convenience: create a like notification.
  void addLikeNotification(String userName, String postId) {
    addNotification(NotificationModel(
      id: 'notif_like_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.like,
      title: 'New Like ❤️',
      message: '$userName liked your post',
      timestamp: DateTime.now(),
    ));
  }

  /// Convenience: create a comment notification.
  void addCommentNotification(String userName, String comment) {
    addNotification(NotificationModel(
      id: 'notif_comment_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.comment,
      title: 'New Comment 💬',
      message: '$userName commented: "$comment"',
      timestamp: DateTime.now(),
    ));
  }

  /// Convenience: create an event join notification.
  void addEventNotification(String eventTitle) {
    addNotification(NotificationModel(
      id: 'notif_event_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.event,
      title: 'Event Joined 🎉',
      message: 'You have joined "$eventTitle". See you there!',
      timestamp: DateTime.now(),
    ));
  }
}
