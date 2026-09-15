import 'dart:async';

import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/interfaces/i_social_repository.dart';

/// ViewModel for the notification system.
///
/// Manages list of notifications, unread count, and provides
/// methods to add/read/clear notifications.
///
/// Almost every [NotificationModel] here is created locally by
/// [addLikeNotification]/[addCommentNotification]/[addEventNotification] —
/// convenience wrappers around the user's own actions, never delivered by a
/// backend. [ISocialRepository.watchMyNotifications], subscribed to when a
/// repository is passed to the constructor, is the one exception: a real,
/// cross-user notification stream (today, only [NotificationType.groupKick]
/// — see [ISocialRepository.kickGroupMember]), merged into the same list so
/// [NotificationScreen] doesn't need to know the difference.
class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel({ISocialRepository? socialRepository}) {
    final repo = socialRepository;
    if (repo != null) {
      _remoteSub = repo.watchMyNotifications().listen((remote) {
        // Replace the remote slice, keep every local-only notification —
        // matched by id so a live update doesn't duplicate entries.
        final remoteIds = remote.map((n) => n.id).toSet();
        _notifications.removeWhere((n) => remoteIds.contains(n.id));
        _notifications.addAll(remote);
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      });
    }
  }

  StreamSubscription<List<NotificationModel>>? _remoteSub;

  final List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  @override
  void dispose() {
    _remoteSub?.cancel();
    super.dispose();
  }

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
      title: 'Yeni Beğeni ❤️',
      message: '$userName gönderini beğendi',
      timestamp: DateTime.now(),
    ));
  }

  /// Convenience: create a comment notification.
  void addCommentNotification(String userName, String comment) {
    addNotification(NotificationModel(
      id: 'notif_comment_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.comment,
      title: 'Yeni Yorum 💬',
      message: '$userName yorum yaptı: "$comment"',
      timestamp: DateTime.now(),
    ));
  }

  /// Convenience: create an event join notification.
  void addEventNotification(String eventTitle) {
    addNotification(NotificationModel(
      id: 'notif_event_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.event,
      title: 'Etkinliğe Katıldın 🎉',
      message: '"$eventTitle" etkinliğine katıldın. Orada görüşürüz!',
      timestamp: DateTime.now(),
    ));
  }
}
