import 'dart:async';

import 'package:flutter/foundation.dart';

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
}
