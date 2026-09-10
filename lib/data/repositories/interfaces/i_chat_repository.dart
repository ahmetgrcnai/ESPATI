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
  Future<Result<ChatRoomModel>> getOrCreateChatRoom({
    required String currentUserId,
    required String currentUserName,
    required String currentUserPhoto,
    required String otherUserId,
    required String otherUserName,
    required String otherUserPhoto,
  });

  /// Appends a message to [roomId] and updates the room's
  /// [ChatRoomModel.lastMessage] / [ChatRoomModel.lastUpdated] for the Inbox.
  Future<Result<void>> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  });
}
