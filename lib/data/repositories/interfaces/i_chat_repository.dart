import '../../../core/result.dart';
import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';

/// Abstract interface for 1-on-1 messaging (Mesajlar inbox + chat threads).
///
/// Swap [MockChatRepository] with [FirestoreChatRepository] via the
/// [kUseMock] flag in `service_locator.dart` — no ViewModel/UI change needed.
abstract class IChatRepository {
  /// Emits [uid]'s active chat rooms in real time, newest activity first.
  Stream<List<ChatRoomModel>> watchUserChatRooms(String uid);

  /// Emits a chat room's messages in real time, oldest first.
  Stream<List<MessageModel>> watchMessages(String roomId);

  /// Returns the existing 1-on-1 room between the two users, creating one
  /// (with no messages yet) if it doesn't already exist. Safe to call
  /// repeatedly — resolves to the same deterministic room either way.
  ///
  /// [autoAccept] only matters when a *new* room is created (an existing
  /// room's request state is never touched): `true` marks it immediately
  /// accepted (e.g. messaging from a listing inquiry — the sender is
  /// contextually known), `false` leaves it pending until the recipient
  /// calls [acceptChatRequest] (e.g. a cold DM from search to a stranger).
  /// Required — no silent default — so every call site makes this choice
  /// deliberately.
  Future<Result<ChatRoomModel>> getOrCreateChatRoom({
    required String currentUserId,
    required String currentUserName,
    required String currentUserPhoto,
    required String otherUserId,
    required String otherUserName,
    required String otherUserPhoto,
    required bool autoAccept,
  });

  /// Appends a message to [roomId] and updates the room's
  /// [ChatRoomModel.lastMessage] / [ChatRoomModel.lastUpdated] for the Inbox.
  Future<Result<void>> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  });

  /// Marks [roomId] accepted — moves it out of "Gelen İstekler" into the
  /// recipient's main inbox.
  Future<Result<void>> acceptChatRequest(String roomId);

  /// Declines [roomId] — deletes the room document. No conversation has
  /// meaningfully started yet at request stage, so this matches
  /// [RequestChatTile]'s "Sil" wording; any orphaned `messages` subcollection
  /// docs (there shouldn't be any before acceptance) are an accepted,
  /// harmless trade-off, same as other documented orphaned-data cases in
  /// this codebase.
  Future<Result<void>> declineChatRequest(String roomId);
}
