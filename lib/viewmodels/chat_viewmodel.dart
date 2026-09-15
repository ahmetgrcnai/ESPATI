import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../data/models/chat_room_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/interfaces/i_chat_repository.dart';
import '../data/repositories/interfaces/i_user_repository.dart';

/// ViewModel for the "Mesajlar" inbox — the real-time list of the current
/// user's 1-on-1 chat rooms, shown in [FormHubScreen]'s Mesajlar sub-tab.
///
/// Long-lived (registered once in `service_locator.dart`), mirroring
/// [ProfileViewModel]'s pattern: subscribes to [IUserRepository.watchCurrentUser]
/// so it re-subscribes to the right rooms on login/logout/account switch,
/// and clears state immediately on sign-out.
class ChatViewModel extends ChangeNotifier {
  final IUserRepository _userRepo;
  final IChatRepository _chatRepo;

  StreamSubscription<UserModel?>? _userSubscription;
  StreamSubscription<List<ChatRoomModel>>? _roomsSubscription;

  String _currentUserId = '';
  String get currentUserId => _currentUserId;

  ChatViewModel({
    required IUserRepository userRepository,
    required IChatRepository chatRepository,
  })  : _userRepo = userRepository,
        _chatRepo = chatRepository {
    _subscribeToUser();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _roomsSubscription?.cancel();
    super.dispose();
  }

  // ── State ──────────────────────────────────────────────────────────────────

  List<ChatRoomModel> _chatRooms = [];
  List<ChatRoomModel> get chatRooms => List.unmodifiable(_chatRooms);

  /// Rooms that belong in the main Inbox list — everything except a
  /// still-pending request addressed to the current user.
  List<ChatRoomModel> get acceptedChatRooms => List.unmodifiable(
      _chatRooms.where((r) => !r.isPendingFor(_currentUserId)));

  /// Rooms someone else started that the current user hasn't accepted yet —
  /// "Gelen İstekler".
  List<ChatRoomModel> get pendingRequests => List.unmodifiable(
      _chatRooms.where((r) => r.isPendingFor(_currentUserId)));

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── User stream ────────────────────────────────────────────────────────────

  void _subscribeToUser() {
    _userSubscription = _userRepo.watchCurrentUser().listen(
      (user) {
        final uid = user?.id ?? '';
        if (uid == _currentUserId) return;
        _currentUserId = uid;

        if (uid.isEmpty) {
          _chatRooms = [];
          _roomsSubscription?.cancel();
          _roomsSubscription = null;
          _isLoading = false;
          notifyListeners();
          return;
        }

        _subscribeToRooms(uid);
      },
      onError: (e) {
        debugPrint('[ChatViewModel] watchCurrentUser error: $e');
      },
    );
  }

  void _subscribeToRooms(String uid) {
    _roomsSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _roomsSubscription = _chatRepo.watchUserChatRooms(uid).listen(
      (rooms) {
        _chatRooms = rooms;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        debugPrint('[ChatViewModel] watchUserChatRooms error: $e');
        notifyListeners();
      },
    );
  }

  // ── Message requests — accept / decline ──────────────────────────────────

  /// Accepts a pending request — the live [watchUserChatRooms] stream
  /// reflects the room moving into [acceptedChatRooms] on its own once the
  /// write lands, same as every other Firestore-backed mutation in this
  /// ViewModel.
  ///
  /// Returns `true` on success, `false` on failure — callers must check this
  /// before treating the request as accepted (e.g. before navigating into
  /// the chat thread), since [ChatRoomModel.acceptedByRecipient] stays
  /// `false` server-side on failure and the room remains pending.
  Future<bool> acceptRequest(String roomId) async {
    final result = await _chatRepo.acceptChatRequest(roomId);
    if (result is Failure) {
      debugPrint('[ChatViewModel] acceptRequest failure: ${result.message}');
      return false;
    }
    return true;
  }

  /// Declines (deletes) a pending request.
  Future<void> declineRequest(String roomId) async {
    final result = await _chatRepo.declineChatRequest(roomId);
    if (result is Failure) {
      debugPrint('[ChatViewModel] declineRequest failure: ${result.message}');
    }
  }
}
