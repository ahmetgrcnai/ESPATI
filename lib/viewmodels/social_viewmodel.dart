import 'package:flutter/material.dart';
import '../core/result.dart';
import '../data/models/event_model.dart';
import '../data/repositories/interfaces/i_social_repository.dart';
import 'notification_viewmodel.dart';

/// ViewModel for social interactions (pati, yorum, follow) and events.
///
/// Uses **Optimistic UI** — state is updated immediately and rolled back
/// if the backend call fails.
///
/// Brand language:
///   • "Pati"  — the like/reaction interaction (paw stamp)
///   • "Yorum" — the comment interaction
class SocialViewModel extends ChangeNotifier {
  final ISocialRepository _socialRepository;
  final NotificationViewModel _notificationViewModel;

  SocialViewModel(this._socialRepository, this._notificationViewModel) {
    loadEvents();
  }

  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Posts that the current user has "pati'd" (liked), tracked optimistically.
  final Set<String> _patiPosts = {};

  /// Returns true if the current user has given a Pati to [postId].
  bool isPostPati(String postId) => _patiPosts.contains(postId);

  // Track followed users (optimistic)
  final Set<String> _followedUsers = {};
  bool isUserFollowed(String userId) => _followedUsers.contains(userId);

  // Events
  List<EventModel> _events = [];
  List<EventModel> get events => List.unmodifiable(_events);

  // ── Pati / Like (Optimistic UI) ────────────────────────────────────────────

  /// Toggles the "Pati" (like) on a post.
  ///
  /// Updates the UI instantly via optimistic state, then confirms with the
  /// backend. On failure, rolls back the local state and surfaces an error.
  Future<void> togglePati(String postId) async {
    final wasPati = _patiPosts.contains(postId);

    // Optimistic update — UI responds immediately
    if (wasPati) {
      _patiPosts.remove(postId);
    } else {
      _patiPosts.add(postId);
    }
    notifyListeners();

    // Backend call
    final result = wasPati
        ? await _socialRepository.patiGeri(postId)
        : await _socialRepository.patiVer(postId);

    switch (result) {
      case Success():
        break; // Optimistic state is already correct
      case Failure(:final message):
        // Rollback on failure
        if (wasPati) {
          _patiPosts.add(postId);
        } else {
          _patiPosts.remove(postId);
        }
        _errorMessage = message;
        notifyListeners();
    }
  }

  // ── Yorum / Comment ────────────────────────────────────────────────────────

  /// Adds a "Yorum" (comment) to a post.
  Future<bool> addYorum(String postId, String yorum) async {
    final result = await _socialRepository.addYorum(postId, yorum);
    switch (result) {
      case Success():
        return true;
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  // ── Follow (Optimistic UI) ─────────────────────────────────────────────────

  /// Toggles follow on a user.
  Future<void> toggleFollow(String userId) async {
    final wasFollowed = _followedUsers.contains(userId);

    // Optimistic update
    if (wasFollowed) {
      _followedUsers.remove(userId);
    } else {
      _followedUsers.add(userId);
    }
    notifyListeners();

    // Backend call
    final result = wasFollowed
        ? await _socialRepository.unfollowUser(userId)
        : await _socialRepository.followUser(userId);

    switch (result) {
      case Success():
        break;
      case Failure(:final message):
        // Rollback
        if (wasFollowed) {
          _followedUsers.add(userId);
        } else {
          _followedUsers.remove(userId);
        }
        _errorMessage = message;
        notifyListeners();
    }
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  /// Loads upcoming events from the repository.
  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _socialRepository.getEvents();
    switch (result) {
      case Success(:final data):
        _events = data;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Joins an event — updates state optimistically and creates a notification.
  Future<void> joinEvent(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final event = _events[index];
    if (event.isJoined) return;

    // Optimistic update
    _events[index] = event.copyWith(
      isJoined: true,
      attendeeCount: event.attendeeCount + 1,
    );
    notifyListeners();

    _notificationViewModel.addEventNotification(event.title);

    // Backend call
    final result = await _socialRepository.joinEvent(eventId);
    switch (result) {
      case Success():
        break;
      case Failure(:final message):
        // Rollback
        _events[index] = event;
        _errorMessage = message;
        notifyListeners();
    }
  }

  /// Clears the error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
