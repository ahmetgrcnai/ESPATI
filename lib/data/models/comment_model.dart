import 'package:cloud_firestore/cloud_firestore.dart';

/// A single comment on a [PostModel] — `posts/{postId}/comments/{commentId}`.
///
/// [authorName]/[authorPhoto] are denormalized onto the document at write
/// time, same convention as [PostModel]/[PatiVideoModel], so rendering a
/// comment list never needs a per-comment `users/{uid}` read.
class CommentModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String text;
  final DateTime timestamp;

  const CommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.text,
    required this.timestamp,
  });

  factory CommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CommentModel(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorPhoto: data['authorPhoto'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }
}
