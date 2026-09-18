import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/result.dart';
import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';
import '../interfaces/i_chat_repository.dart';

/// Firestore implementation of [IChatRepository].
///
/// Firestore paths:
///   `chats/{roomId}`                  — room metadata (participants, last message)
///   `chats/{roomId}/messages/{msgId}` — message thread
class FirestoreChatRepository implements IChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _kChats = 'chats';
  static const _kMessages = 'messages';

  CollectionReference<Map<String, dynamic>> get _chatsCol =>
      _firestore.collection(_kChats);

  // ── Real-time: inbox ─────────────────────────────────────────────────────

  /// [FIX SYNC-01 pattern] Same fix applied to `watchUserPosts` in
  /// FirestorePostRepository: `where(arrayContains) + orderBy` requires a
  /// composite index that may not exist in the console, which would make
  /// this stream fail silently (empty inbox, no new rooms appearing). Only
  /// the index-free `where` clause goes to Firestore; sorting by most recent
  /// activity happens client-side. A user's room count is small enough that
  /// this costs nothing in practice.
  @override
  Stream<List<ChatRoomModel>> watchUserChatRooms(String uid) {
    return _chatsCol
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final rooms = <ChatRoomModel>[];
      for (final doc in snapshot.docs) {
        try {
          rooms.add(ChatRoomModel.fromFirestore(doc.data(), id: doc.id));
        } catch (_) {
          // Skip a malformed room doc rather than breaking the whole stream.
        }
      }
      rooms.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      return rooms;
    });
  }

  // ── Real-time: messages ──────────────────────────────────────────────────

  @override
  Stream<List<MessageModel>> watchMessages(String roomId) {
    return _chatsCol
        .doc(roomId)
        .collection(_kMessages)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
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
    try {
      final roomId = ChatRoomModel.idFor(currentUserId, otherUserId);
      final docRef = _chatsCol.doc(roomId);
      final snap = await docRef.get();

      if (snap.exists && snap.data() != null) {
        // Existing room — its request state is never touched here.
        return Success(ChatRoomModel.fromFirestore(snap.data()!, id: roomId));
      }

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

      // merge:true — if two devices race to create the same deterministic
      // room simultaneously, the second write doesn't clobber the first.
      await docRef.set(room.toFirestore(), SetOptions(merge: true));
      return Success(room);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Sohbet başlatılamadı.', exception: e);
    }
  }

  // ── Send message ─────────────────────────────────────────────────────────

  @override
  Future<Result<void>> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) async {
    try {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return const Success(null);

      final roomRef = _chatsCol.doc(roomId);
      final messageRef = roomRef.collection(_kMessages).doc();
      final now = DateTime.now();

      final batch = _firestore.batch();
      batch.set(messageRef, {
        'senderId': senderId,
        'text': trimmed,
        'timestamp': Timestamp.fromDate(now),
      });
      batch.set(
        roomRef,
        {
          'lastMessage': trimmed,
          'lastUpdated': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );
      await batch.commit();

      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Mesaj gönderilemedi.', exception: e);
    }
  }

  // ── Message requests — accept / decline ──────────────────────────────────

  @override
  Future<Result<void>> acceptChatRequest(String roomId) async {
    try {
      await _chatsCol
          .doc(roomId)
          .set({'acceptedByRecipient': true}, SetOptions(merge: true));
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('İstek kabul edilemedi.', exception: e);
    }
  }

  @override
  Future<Result<void>> declineChatRequest(String roomId) async {
    try {
      await _chatsCol.doc(roomId).delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('İstek silinemedi.', exception: e);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok.';
      case 'unavailable':
        return 'Sunucu şu anda kullanılamıyor. Lütfen tekrar deneyin.';
      case 'deadline-exceeded':
        return 'İstek zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.';
      default:
        return e.message ?? 'Beklenmedik bir hata oluştu.';
    }
  }
}
