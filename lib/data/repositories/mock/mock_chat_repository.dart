import 'dart:async';

import '../../../core/result.dart';
import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';
import '../interfaces/i_chat_repository.dart';

/// Mock implementation of [IChatRepository].
///
/// In-memory only — mutations update local lists and push to broadcast
/// streams, simulating Firestore's `snapshots()` behavior without any
/// network dependency.
class MockChatRepository implements IChatRepository {
  static const _delay = Duration(milliseconds: 500);

  final Map<String, ChatRoomModel> _rooms = {
    for (final r in _seedRooms) r.roomId: r,
  };
  final Map<String, List<MessageModel>> _messages = {
    for (final entry in _seedMessages.entries) entry.key: [...entry.value],
  };

  final Map<String, StreamController<List<ChatRoomModel>>> _roomsControllers =
      {};
  final Map<String, StreamController<List<MessageModel>>>
      _messagesControllers = {};

  int _messageIdCounter = 1000;

  // ── Real-time: inbox ─────────────────────────────────────────────────────

  @override
  Stream<List<ChatRoomModel>> watchUserChatRooms(String uid) {
    final controller = _roomsControllers.putIfAbsent(
      uid,
      () => StreamController<List<ChatRoomModel>>.broadcast(),
    );
    Future.microtask(() => _emitRooms(uid));
    return controller.stream;
  }

  void _emitRooms(String uid) {
    final controller = _roomsControllers[uid];
    if (controller == null || controller.isClosed) return;
    final rooms = _rooms.values
        .where((r) => r.participantIds.contains(uid))
        .toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    controller.add(rooms);
  }

  void _emitAllRoomSubscribers() {
    for (final uid in _roomsControllers.keys) {
      _emitRooms(uid);
    }
  }

  // ── Real-time: messages ──────────────────────────────────────────────────

  @override
  Stream<List<MessageModel>> watchMessages(String roomId) {
    final controller = _messagesControllers.putIfAbsent(
      roomId,
      () => StreamController<List<MessageModel>>.broadcast(),
    );
    Future.microtask(() => _emitMessages(roomId));
    return controller.stream;
  }

  void _emitMessages(String roomId) {
    final controller = _messagesControllers[roomId];
    if (controller == null || controller.isClosed) return;
    controller.add(List.unmodifiable(_messages[roomId] ?? const []));
  }

  // ── Get-or-create room ───────────────────────────────────────────────────

  @override
  Future<Result<ChatRoomModel>> getOrCreateChatRoom({
    required String currentUserId,
    required String currentUserName,
    required String currentUserPhoto,
    required String otherUserId,
    required String otherUserName,
    required String otherUserPhoto,
    required bool autoAccept,
  }) async {
    await Future.delayed(_delay);

    final roomId = ChatRoomModel.idFor(currentUserId, otherUserId);
    final existing = _rooms[roomId];
    if (existing != null) return Success(existing);

    final room = ChatRoomModel(
      roomId: roomId,
      participantIds: [currentUserId, otherUserId],
      participantNames: {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      participantPhotos: {
        currentUserId: currentUserPhoto,
        otherUserId: otherUserPhoto,
      },
      lastMessage: '',
      lastUpdated: DateTime.now(),
      initiatorId: currentUserId,
      acceptedByRecipient: autoAccept,
    );
    _rooms[roomId] = room;
    _messages.putIfAbsent(roomId, () => []);
    _emitAllRoomSubscribers();

    return Success(room);
  }

  // ── Send message ─────────────────────────────────────────────────────────

  @override
  Future<Result<void>> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) async {
    await Future.delayed(_delay);

    final trimmed = text.trim();
    if (trimmed.isEmpty) return const Success(null);

    final message = MessageModel(
      messageId: 'msg_${_messageIdCounter++}',
      senderId: senderId,
      text: trimmed,
      timestamp: DateTime.now(),
    );
    _messages.putIfAbsent(roomId, () => []).add(message);
    _emitMessages(roomId);

    final room = _rooms[roomId];
    if (room != null) {
      _rooms[roomId] = ChatRoomModel(
        roomId: room.roomId,
        participantIds: room.participantIds,
        participantNames: room.participantNames,
        participantPhotos: room.participantPhotos,
        lastMessage: trimmed,
        lastUpdated: message.timestamp,
        unreadCounts: room.unreadCounts,
        initiatorId: room.initiatorId,
        acceptedByRecipient: room.acceptedByRecipient,
      );
      _emitAllRoomSubscribers();
    }

    return const Success(null);
  }

  // ── Message requests — accept / decline ──────────────────────────────────

  @override
  Future<Result<void>> acceptChatRequest(String roomId) async {
    await Future.delayed(_delay);
    final room = _rooms[roomId];
    if (room == null) return const Failure('İstek bulunamadı.');
    _rooms[roomId] = ChatRoomModel(
      roomId: room.roomId,
      participantIds: room.participantIds,
      participantNames: room.participantNames,
      participantPhotos: room.participantPhotos,
      lastMessage: room.lastMessage,
      lastUpdated: room.lastUpdated,
      unreadCounts: room.unreadCounts,
      initiatorId: room.initiatorId,
      acceptedByRecipient: true,
    );
    _emitAllRoomSubscribers();
    return const Success(null);
  }

  @override
  Future<Result<void>> declineChatRequest(String roomId) async {
    await Future.delayed(_delay);
    _rooms.remove(roomId);
    _messages.remove(roomId);
    _emitAllRoomSubscribers();
    return const Success(null);
  }
}

// ── Seed data ─────────────────────────────────────────────────────────────────
//
// 'current_user' matches the uid MockAuthRepository/MockUserRepository seed
// as the signed-in mock account, so the Mesajlar tab isn't empty in mock mode.

final List<ChatRoomModel> _seedRooms = [
  ChatRoomModel(
    roomId: ChatRoomModel.idFor('current_user', 'mock_user_2'),
    participantIds: const ['current_user', 'mock_user_2'],
    participantNames: const {
      'current_user': 'Sen',
      'mock_user_2': 'Zeynep H.',
    },
    participantPhotos: const {
      'mock_user_2': 'https://placekitten.com/72/72',
    },
    lastMessage: 'Rocky\'yi bugün Sazova Parkı girişinde gördüm!',
    lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
  ),
];

final Map<String, List<MessageModel>> _seedMessages = {
  ChatRoomModel.idFor('current_user', 'mock_user_2'): [
    MessageModel(
      messageId: 'msg_seed_1',
      senderId: 'mock_user_2',
      text: 'Merhaba, kayıp ilanınızı gördüm.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MessageModel(
      messageId: 'msg_seed_2',
      senderId: 'mock_user_2',
      text: 'Rocky\'yi bugün Sazova Parkı girişinde gördüm!',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ],
};
