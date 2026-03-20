import 'package:flutter/material.dart';
import '../core/result.dart';
import '../data/models/event_model.dart';
import '../data/repositories/interfaces/i_social_repository.dart';
import 'notification_viewmodel.dart';

/// ViewModel for social interactions (like, comment, follow) and events.
///
/// Uses **Optimistic UI** — state is updated immediately and rolled back
/// if the backend call fails.
class SocialViewModel extends ChangeNotifier {
  final ISocialRepository _socialRepository;
  final NotificationViewModel _notificationViewModel;

  SocialViewModel(this._socialRepository, this._notificationViewModel) {
    loadEvents();
  }

  // ── State ──

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Track liked posts (optimistic)
  final Set<String> _likedPosts = {};
  bool isPostLiked(String postId) => _likedPosts.contains(postId);

  // Track followed users (optimistic)
  final Set<String> _followedUsers = {};
  bool isUserFollowed(String userId) => _followedUsers.contains(userId);

  // Events
  List<EventModel> _events = [];
  List<EventModel> get events => List.unmodifiable(_events);

  // ── Like (Optimistic UI) ──

  /// Toggles like on a post. Updates UI instantly, then confirms with backend.
  Future<void> toggleLike(String postId) async {
    final wasLiked = _likedPosts.contains(postId);

    // Optimistic update
    if (wasLiked) {
      _likedPosts.remove(postId);
    } else {
      _likedPosts.add(postId);
    }
    notifyListeners();

    // Backend call
    final result = wasLiked
        ? await _socialRepository.unlikePost(postId)
        : await _socialRepository.likePost(postId);

    switch (result) {
      case Success():
        break; // Already updated optimistically
      case Failure(:final message):
        // Rollback on failure
        if (wasLiked) {
          _likedPosts.add(postId);
        } else {
          _likedPosts.remove(postId);
        }
        _errorMessage = message;
        notifyListeners();
    }
  }

  // ── Comment ──

  /// Adds a comment to a post.
  Future<bool> addComment(String postId, String comment) async {
    final result = await _socialRepository.addComment(postId, comment);
    switch (result) {
      case Success():
        return true;
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  // ── Follow (Optimistic UI) ──

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

  // ── Events ──

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
    // Find and optimistically update the event
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final event = _events[index];
    if (event.isJoined) return; // Already joined

    // Optimistic update
    _events[index] = event.copyWith(
      isJoined: true,
      attendeeCount: event.attendeeCount + 1,
    );
    notifyListeners();

    // Sync notification — event joined
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
