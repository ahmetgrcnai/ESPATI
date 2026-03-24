/// A direct message conversation entry shown in the DM inbox list.
///
/// Immutable value object. Supports JSON serialization for future
/// Firestore / REST API integration.
class DirectMessageModel {
  final String id;
  final String displayName;
  final String avatarUrl;
  final String lastMessage;
  final String timeLabel;   // e.g. "5 dk" | "2 sa" | "Dün"
  final bool isOnline;
  final int unreadCount;
  final bool isVerified;    // e.g. veterinarians, official accounts

  const DirectMessageModel({
    required this.id,
    required this.displayName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timeLabel,
    this.isOnline = false,
    this.unreadCount = 0,
    this.isVerified = false,
  });

  factory DirectMessageModel.fromJson(Map<String, dynamic> json) {
    return DirectMessageModel(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'lastMessage': lastMessage,
        'timeLabel': timeLabel,
        'isOnline': isOnline,
        'unreadCount': unreadCount,
        'isVerified': isVerified,
      };

  DirectMessageModel copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    String? lastMessage,
    String? timeLabel,
    bool? isOnline,
    int? unreadCount,
    bool? isVerified,
  }) {
    return DirectMessageModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      timeLabel: timeLabel ?? this.timeLabel,
      isOnline: isOnline ?? this.isOnline,
      unreadCount: unreadCount ?? this.unreadCount,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  bool get hasUnread => unreadCount > 0;
  bool get isRead => unreadCount == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectMessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DirectMessageModel(id: $id, displayName: $displayName, unread: $unreadCount)';
}
