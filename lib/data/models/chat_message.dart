/// A single chat message used in the AI/Vet chat screen.
///
/// Supports JSON serialization for future API/Firebase integration,
/// immutable updates via [copyWith], and a safe [empty] factory.
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  /// Creates an empty placeholder [ChatMessage].
  factory ChatMessage.empty() {
    return ChatMessage(
      id: '',
      text: '',
      isUser: false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Creates a [ChatMessage] from a JSON map.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp: _parseDateTime(json['timestamp']),
    );
  }

  /// Converts this [ChatMessage] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Returns a copy with the given fields replaced.
  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  String toString() =>
      'ChatMessage(id: $id, isUser: $isUser, text: ${text.length > 30 ? '${text.substring(0, 30)}...' : text})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

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
