import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message inside a [ChatRoomModel] thread.
///
/// Firestore path: `chats/{roomId}/messages/{messageId}`.
class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final DateTime timestamp;

  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromFirestore(Map<String, dynamic> data,
      {required String id}) {
    return MessageModel(
      messageId: id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  bool isMine(String uid) => senderId == uid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId;

  @override
  int get hashCode => messageId.hashCode;

  @override
  String toString() =>
      'MessageModel(messageId: $messageId, senderId: $senderId)';

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
