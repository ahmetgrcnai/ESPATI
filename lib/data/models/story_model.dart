/// Story model representing a temporary story post on the ESPATI platform.
///
/// Supports JSON serialization for Firebase/REST API integration,
/// immutable state updates via [copyWith], and safe empty state via [StoryModel.empty].
class StoryModel {
  final String id;
  final String userId;
  final String imageUrl;
  final bool isViewed;
  final DateTime expiresAt;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.isViewed,
    required this.expiresAt,
  });

  /// Creates an empty [StoryModel] to avoid null-pointer errors in the UI.
  factory StoryModel.empty() {
    return StoryModel(
      id: '',
      userId: '',
      imageUrl: '',
      isViewed: false,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Creates a [StoryModel] from a JSON map (e.g. Firestore document or REST response).
  ///
  /// The [expiresAt] field accepts either:
  /// - An ISO-8601 string (REST APIs)
  /// - A millisecondsSinceEpoch integer (Firestore Timestamps converted to millis)
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      isViewed: json['isViewed'] as bool? ?? false,
      expiresAt: _parseDateTime(json['expiresAt']),
    );
  }

  /// Converts this [StoryModel] to a JSON map for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'isViewed': isViewed,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  /// Returns a copy of this [StoryModel] with the given fields replaced.
  StoryModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    bool? isViewed,
    DateTime? expiresAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      isViewed: isViewed ?? this.isViewed,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Whether this instance represents an empty / placeholder story.
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Whether this story has expired (past its [expiresAt] time).
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether this story is still active (not expired).
  bool get isActive => !isExpired && isNotEmpty;

  @override
  String toString() =>
      'StoryModel(id: $id, userId: $userId, isViewed: $isViewed, isExpired: $isExpired)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryModel && runtimeType == other.runtimeType && id == other.id;

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
