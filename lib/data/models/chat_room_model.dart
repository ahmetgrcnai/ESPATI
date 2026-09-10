import 'package:cloud_firestore/cloud_firestore.dart';

/// A 1-on-1 chat room between two ESPATI users.
///
/// Firestore path: `chats/{roomId}`. [roomId] is deterministic — the two
/// participant UIDs sorted and joined with `_` — so starting a chat between
/// the same two users always resolves to the same document instead of
/// creating duplicates.
///
/// [participantNames] / [participantPhotos] are denormalized (uid → value)
/// so the Inbox list can render without an extra per-room user lookup.
class ChatRoomModel {
  final String roomId;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final String lastMessage;
  final DateTime lastUpdated;

  /// Per-participant unread message count (uid → count) for this room.
  /// Step 67: the field/round-trip exists so [InboxChatTile]'s unread
  /// styling has real data to read, but nothing increments it yet — that
  /// needs the message-send write path (`sendMessage`,
  /// `firestore_chat_repository.dart`) to bump the *other* participant's
  /// entry, and `ChatThreadViewModel`/`ChatScreen` to reset the current
  /// user's entry back to 0 on opening a room. Until that lands, every
  /// room reads as 0/read. Defaults to an empty map for rooms written
  /// before this field existed.
  final Map<String, int> unreadCounts;

  const ChatRoomModel({
    required this.roomId,
    required this.participantIds,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastUpdated,
    this.unreadCounts = const {},
  });

  /// Unread count for [myUid] in this room — 0 for a uid with no entry.
  int unreadCountFor(String myUid) => unreadCounts[myUid] ?? 0;

  factory ChatRoomModel.empty() => ChatRoomModel(
        roomId: '',
        participantIds: const [],
        participantNames: const {},
        participantPhotos: const {},
        lastMessage: '',
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
        unreadCounts: const {},
      );

  factory ChatRoomModel.fromFirestore(Map<String, dynamic> data,
      {required String id}) {
    return ChatRoomModel(
      roomId: id,
      participantIds: List<String>.from(
        data['participantIds'] as List<dynamic>? ?? const [],
      ),
      participantNames: Map<String, String>.from(
        data['participantNames'] as Map<dynamic, dynamic>? ?? const {},
      ),
      participantPhotos: Map<String, String>.from(
        data['participantPhotos'] as Map<dynamic, dynamic>? ?? const {},
      ),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastUpdated: _parseTimestamp(data['lastUpdated']),
      unreadCounts: (data['unreadCounts'] as Map<dynamic, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key as String, (value as num).toInt())),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'participantIds': participantIds,
        'participantNames': participantNames,
        'participantPhotos': participantPhotos,
        'lastMessage': lastMessage,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
        'unreadCounts': unreadCounts,
      };

  /// Deterministic room id for a pair of UIDs — sorted so the order the
  /// caller supplies them in never matters.
  static String idFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// The UID of the other participant, relative to [myUid].
  String otherParticipantId(String myUid) =>
      participantIds.firstWhere((id) => id != myUid, orElse: () => '');

  String otherParticipantName(String myUid) =>
      participantNames[otherParticipantId(myUid)] ?? 'Pati Dostu';

  String otherParticipantPhoto(String myUid) =>
      participantPhotos[otherParticipantId(myUid)] ?? '';

  bool get isEmpty => roomId.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoomModel &&
          runtimeType == other.runtimeType &&
          roomId == other.roomId;

  @override
  int get hashCode => roomId.hashCode;

  @override
  String toString() =>
      'ChatRoomModel(roomId: $roomId, participants: $participantIds)';

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
