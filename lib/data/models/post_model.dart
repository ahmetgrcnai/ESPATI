/// Post model representing a user's feed post on the ESPATI platform.
///
/// Supports JSON serialization for Firebase/REST API integration,
/// immutable state updates via [copyWith], and safe empty state via [PostModel.empty].
class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userProfileImage;
  final String content;
  final String imageUrl;
  final int likesCount;
  final int commentsCount;
  final String locationTag;
  final DateTime timestamp;

  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.content,
    required this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.locationTag,
    required this.timestamp,
  });

  /// Creates an empty [PostModel] to avoid null-pointer errors in the UI.
  factory PostModel.empty() {
    return PostModel(
      id: '',
      userId: '',
      userName: '',
      userProfileImage: '',
      content: '',
      imageUrl: '',
      likesCount: 0,
      commentsCount: 0,
      locationTag: '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Creates a [PostModel] from a JSON map (e.g. Firestore document or REST response).
  ///
  /// The [timestamp] field accepts either:
  /// - An ISO-8601 string (REST APIs)
  /// - A millisecondsSinceEpoch integer (Firestore Timestamps converted to millis)
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userProfileImage: json['userProfileImage'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      locationTag: json['locationTag'] as String? ?? '',
      timestamp: _parseDateTime(json['timestamp']),
    );
  }

  /// Converts this [PostModel] to a JSON map for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'content': content,
      'imageUrl': imageUrl,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'locationTag': locationTag,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Returns a copy of this [PostModel] with the given fields replaced.
  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImage,
    String? content,
    String? imageUrl,
    int? likesCount,
    int? commentsCount,
    String? locationTag,
    DateTime? timestamp,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      locationTag: locationTag ?? this.locationTag,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Whether this instance represents an empty / placeholder post.
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  String toString() =>
      'PostModel(id: $id, userName: $userName, locationTag: $locationTag)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Safely parses a [DateTime] from a JSON value.
///
/// Supports ISO-8601 strings, millisecondsSinceEpoch integers, and null.
DateTime _parseDateTime(dynamic value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
