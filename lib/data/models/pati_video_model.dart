import 'package:cloud_firestore/cloud_firestore.dart';

/// A single short video ("Pati") in the Paties (Reels/Shorts) vertical feed.
///
/// Immutable value object. Mirrors [PostModel]'s author-denormalization
/// pattern ([authorName]/[authorPhoto] copied onto the document at write
/// time) so [PatiesViewerScreen] can render the creator badge without an
/// extra `users/{uid}` read per card.
class PatiVideoModel {
  final String id;
  final String videoUrl;
  final String description;
  final DateTime timestamp;
  final String authorId;
  final String authorName;
  final String authorPhoto;

  const PatiVideoModel({
    required this.id,
    required this.videoUrl,
    required this.description,
    required this.timestamp,
    required this.authorId,
    this.authorName = '',
    this.authorPhoto = '',
  });

  /// Builds a [PatiVideoModel] from a Firestore document snapshot.
  factory PatiVideoModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return PatiVideoModel(
      id: doc.id,
      videoUrl: data['videoUrl'] as String? ?? '',
      description: data['description'] as String? ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorPhoto: data['authorPhoto'] as String? ?? '',
    );
  }

  /// Firestore write payload. Document ID lives in the collection, not the
  /// body, so [id] is intentionally excluded — same convention as
  /// [PostModel.toFirestore].
  Map<String, dynamic> toFirestore() => {
        'videoUrl': videoUrl,
        'description': description,
        'timestamp': Timestamp.fromDate(timestamp),
        'authorId': authorId,
        'authorName': authorName,
        'authorPhoto': authorPhoto,
      };

  PatiVideoModel copyWith({
    String? id,
    String? videoUrl,
    String? description,
    DateTime? timestamp,
    String? authorId,
    String? authorName,
    String? authorPhoto,
  }) {
    return PatiVideoModel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhoto: authorPhoto ?? this.authorPhoto,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatiVideoModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PatiVideoModel(id: $id, authorName: $authorName, description: $description)';
}
