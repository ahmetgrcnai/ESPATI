import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../data/models/message_model.dart';
import '../data/repositories/interfaces/i_chat_repository.dart';

/// ViewModel for a single [ChatScreen] instance.
///
/// Screen-scoped — created fresh via `ChangeNotifierProvider` each time a
/// chat thread is opened and disposed when the route pops, the same pattern
/// [CreatePostViewModel] uses for its screen-scoped upload state. This keeps
/// the message subscription from leaking between different chat threads.
class ChatThreadViewModel extends ChangeNotifier {
  final IChatRepository _chatRepo;
  final String roomId;
  final String currentUserId;

  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  ChatThreadViewModel({
    required IChatRepository chatRepository,
    required this.roomId,
    required this.currentUserId,
  }) : _chatRepo = chatRepository {
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  // ── State ──────────────────────────────────────────────────────────────────

  List<MessageModel> _messages = [];
  List<MessageModel> get messages => List.unmodifiable(_messages);

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Message stream ────────────────────────────────────────────────────────

  void _subscribeToMessages() {
    _messagesSubscription = _chatRepo.watchMessages(roomId).listen(
      (messages) {
        _messages = messages;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        debugPrint('[ChatThreadViewModel] watchMessages error: $e');
        notifyListeners();
      },
    );
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _chatRepo.sendMessage(
      roomId: roomId,
      senderId: currentUserId,
      text: trimmed,
    );

    if (result case Failure(:final message)) {
      _errorMessage = message;
      debugPrint('[ChatThreadViewModel] sendMessage error: $message');
    }

    _isSending = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
