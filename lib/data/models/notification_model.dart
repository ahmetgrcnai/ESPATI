import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of notification in the ESPATI app.
enum NotificationType {
  like,
  comment,
  event,
  system,

  /// A real, cross-user Firestore-backed notification — unlike every other
  /// value here, which [NotificationViewModel] only ever creates locally
  /// for the current user's own actions. Written by
  /// [ISocialRepository.kickGroupMember] into the *kicked* user's own
  /// `users/{uid}/notifications` subcollection, and streamed back in via
  /// [ISocialRepository.watchMyNotifications].
  groupKick;

  String get label {
    switch (this) {
      case NotificationType.like:
        return 'Like';
      case NotificationType.comment:
        return 'Comment';
      case NotificationType.event:
        return 'Event';
      case NotificationType.system:
        return 'System';
      case NotificationType.groupKick:
        return 'Gruptan Çıkarıldın';
    }
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.system,
    );
  }
}

/// A notification entry in the ESPATI app.
class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.empty() {
    return NotificationModel(
      id: '',
      type: NotificationType.system,
      title: '',
      message: '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] is String
          ? DateTime.tryParse(json['timestamp'] as String) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  /// Builds from a `users/{uid}/notifications/{id}` document — see
  /// [ISocialRepository.watchMyNotifications]. The only real Firestore
  /// source this model has; everything else in the app is constructed
  /// locally by [NotificationViewModel].
  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final timestamp = data['timestamp'];
    return NotificationModel(
      id: doc.id,
      type: NotificationType.fromString(data['type'] as String? ?? ''),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      timestamp: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  bool get isEmpty => id.isEmpty;

  @override
  String toString() =>
      'NotificationModel(id: $id, type: ${type.label}, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
