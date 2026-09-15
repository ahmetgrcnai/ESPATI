import 'dart:async';

import 'package:flutter/material.dart';
import '../core/result.dart';
import '../data/models/comment_model.dart';
import '../data/models/event_model.dart';
import '../data/models/post_model.dart';
import '../data/models/story_model.dart';
import '../data/repositories/interfaces/i_post_repository.dart';
import '../data/repositories/interfaces/i_social_repository.dart';
import 'notification_viewmodel.dart';

/// ViewModel for social interactions (pati, yorum, follow) and events.
///
/// Uses **Optimistic UI** — state is updated immediately and rolled back
/// if the backend call fails.
///
/// Feed mutations flow:
///   • togglePati  → [IPostRepository.togglePati] (Firebase transaction)
///   • addYorum    → [ISocialRepository.addYorum]  (mock until implemented)
///   • follow/unfollow, bookmark, events → [ISocialRepository] (mock until implemented)
///
/// Brand language:
///   • "Pati"  — the like/reaction interaction (paw stamp)
///   • "Yorum" — the comment interaction
class SocialViewModel extends ChangeNotifier {
  final ISocialRepository _socialRepository;
  final IPostRepository _postRepository;
  final NotificationViewModel _notificationViewModel;

  StreamSubscription<List<PostModel>>? _feedSubscription;

  SocialViewModel(
    this._socialRepository,
    this._postRepository,
    this._notificationViewModel,
  ) {
    _subscribeFeed();
    loadStories();
    loadEvents();
    _loadUserSocialState();
  }

  // ── Feed Posts ─────────────────────────────────────────────────────────────

  List<PostModel> _feedPosts = [];
  List<PostModel> get feedPosts => List.unmodifiable(_feedPosts);

  bool _feedLoading = true;
  bool get feedLoading => _feedLoading;

  // Tracks postIds for which a pati toggle is currently in-flight.
  // While a postId is in this set, the Firestore stream will NOT overwrite
  // the optimistic count — preventing flicker between tap and stream confirm.
  final Set<String> _inFlightPati = {};

  void _subscribeFeed() {
    _feedSubscription = _postRepository.getSocialFeed().listen(
      (posts) {
        _feedPosts = posts;
        _feedLoading = false;
        // Sync server counts — skip posts with an in-flight optimistic update
        // to avoid overwriting the count the user is currently seeing.
        for (final post in posts) {
          if (!_inFlightPati.contains(post.id)) {
            _patiCounts[post.id] = post.patiCount;
          }
        }
        notifyListeners();
      },
      onError: (_) {
        _feedLoading = false;
        _errorMessage = 'Gönderi akışı kesildi.';
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    super.dispose();
  }

  // ── Stories ────────────────────────────────────────────────────────────────

  List<StoryModel> _stories = [];
  List<StoryModel> get stories => List.unmodifiable(_stories);

  bool _storiesLoading = false;
  bool get storiesLoading => _storiesLoading;

  Future<void> loadStories() async {
    _storiesLoading = true;
    notifyListeners();

    final result = await _postRepository.getStories();
    switch (result) {
      case Success(:final data):
        _stories = data;
      case Failure():
        _stories = [];
    }

    _storiesLoading = false;
    notifyListeners();
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

  // Single source of truth for pati counts — keyed by postId.
  // Updated from the Firestore stream; protected by [_inFlightPati] during
  // optimistic toggles so the user never sees count flicker.
  final Map<String, int> _patiCounts = {};

  /// Returns the current pati count for [postId].
  int getPatiCount(String postId) => _patiCounts[postId] ?? 0;

  /// Seeds the initial pati count when a post card first mounts, before the
  /// stream has had a chance to populate [_patiCounts] for this post.
  /// No-op if the stream has already set the value.
  void seedPatiCount(String postId, int count) {
    _patiCounts.putIfAbsent(postId, () => count);
  }

  // Bookmarked post IDs — single source of truth.
  final Set<String> _bookmarkedPosts = {};

  /// Returns true if [postId] is bookmarked by the current user.
  bool isPostBookmarked(String postId) => _bookmarkedPosts.contains(postId);

  // Saved listing IDs — single source of truth, parallel to [_bookmarkedPosts]
  // (see [toggleListingBookmark]).
  final Set<String> _bookmarkedListings = {};

  /// Returns true if [listingId] is saved by the current user.
  bool isListingBookmarked(String listingId) =>
      _bookmarkedListings.contains(listingId);

  // Track followed users (optimistic)
  final Set<String> _followedUsers = {};
  bool isUserFollowed(String userId) => _followedUsers.contains(userId);

  // Mirrors [_inFlightPati] — see [toggleFollow]/[toggleBookmark]/
  // [toggleListingBookmark]/[toggleGroupMembership].
  final Set<String> _inFlightFollow = {};
  final Set<String> _inFlightBookmark = {};
  final Set<String> _inFlightListingBookmark = {};
  final Set<String> _inFlightGroupMembership = {};

  // Joined Topluluk group IDs — single source of truth, parallel to
  // [_bookmarkedPosts]/[_bookmarkedListings].
  final Set<String> _joinedGroupIds = {};

  /// Returns true if the current user has joined [groupId].
  bool isGroupMember(String groupId) => _joinedGroupIds.contains(groupId);

  /// Real-time stream of whether the current user follows [userId].
  ///
  /// Backed by `users/{me}/following/{userId}` document existence in Firestore.
  /// Use this on dedicated user-profile views where a single accurate stream
  /// is preferred over the optimistic Set (e.g. [UserCard], profile page).
  Stream<bool> watchIsFollowing(String userId) =>
      _socialRepository.isFollowingStream(userId);

  // Events
  List<EventModel> _events = [];
  List<EventModel> get events => List.unmodifiable(_events);

  // ── Startup state ─────────────────────────────────────────────────────────

  /// Kullanıcının önceki oturumlardan kalan takip ve kayıt durumunu
  /// Firestore'dan yükler. Uygulama açıldığında UI'ın doğru durumu
  /// göstermesi için kritiktir.
  Future<void> _loadUserSocialState() async {
    final followingResult = await _socialRepository.getFollowingIds();
    if (followingResult case Success(:final data)) {
      _followedUsers.addAll(data);
    }

    final bookmarksResult = await _socialRepository.getBookmarkedPostIds();
    if (bookmarksResult case Success(:final data)) {
      _bookmarkedPosts.addAll(data);
    }

    final savedListingsResult =
        await _socialRepository.getBookmarkedListingIds();
    if (savedListingsResult case Success(:final data)) {
      _bookmarkedListings.addAll(data);
    }

    final joinedGroupsResult = await _socialRepository.getJoinedGroupIds();
    if (joinedGroupsResult case Success(:final data)) {
      _joinedGroupIds.addAll(data);
    }

    notifyListeners();
  }

  // ── Pati / Like (Optimistic UI) ────────────────────────────────────────────

  /// Toggles the "Pati" (like) on a post.
  ///
  /// Updates the UI instantly via optimistic state, then confirms with the
  /// Firebase backend via [IPostRepository.togglePati] (atomic Firestore
  /// transaction). On failure, rolls back local state and surfaces an error.
  ///
  /// [_inFlightPati] serves double duty:
  ///   1. Early-return lock — rapid taps while a transaction is in-flight for
  ///      this post are silently dropped, preventing conflicting concurrent
  ///      Firestore transactions and the resulting count desync.
  ///   2. Stream-update shield — the live feed stream will not overwrite the
  ///      optimistic count until the transaction resolves, eliminating flicker.
  Future<void> togglePati(String postId) async {
    // Drop taps that arrive while this post's transaction is already in-flight.
    if (_inFlightPati.contains(postId)) return;

    final wasPati = _patiPosts.contains(postId);
    final previousCount = _patiCounts[postId] ?? 0;

    // Guard: block stream count updates for this post while in-flight.
    _inFlightPati.add(postId);

    // Optimistic update — count and toggle state move together immediately.
    if (wasPati) {
      _patiPosts.remove(postId);
      _patiCounts[postId] = (previousCount - 1).clamp(0, 999999);
    } else {
      _patiPosts.add(postId);
      _patiCounts[postId] = previousCount + 1;
    }
    notifyListeners();

    // Backend call — atomic Firestore transaction via IPostRepository.
    // Returns Result<void>; the confirmed count arrives via the live stream.
    final result = await _postRepository.togglePati(postId);

    // Release guard — stream may now sync the server-confirmed count.
    _inFlightPati.remove(postId);

    switch (result) {
      case Success():
        // The Firestore stream will emit the confirmed count on its next tick.
        // No manual notifyListeners() needed here — stream handler calls it.
        break;
      case Failure(:final message):
        // Rollback both toggle state and count on backend failure.
        if (wasPati) {
          _patiPosts.add(postId);
        } else {
          _patiPosts.remove(postId);
        }
        _patiCounts[postId] = previousCount;
        _errorMessage = message;
        notifyListeners();
    }
  }

  // ── Yorum / Comment ────────────────────────────────────────────────────────

  /// Adds a "Yorum" (comment) to a post. [authorName]/[authorPhoto] are
  /// denormalized onto the comment — see [CommentModel]. No local list state
  /// to update here: [FeedDetailScreen] owns its own [watchComments]
  /// subscription directly, so the write just needs to succeed for that
  /// live stream to pick it up.
  Future<bool> addYorum(
    String postId,
    String yorum, {
    required String authorName,
    required String authorPhoto,
  }) async {
    final result = await _socialRepository.addYorum(
      postId,
      yorum,
      authorName: authorName,
      authorPhoto: authorPhoto,
    );
    switch (result) {
      case Success():
        return true;
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  /// Real-time stream of a post's comments — see
  /// [ISocialRepository.watchComments]. A thin passthrough (not cached here)
  /// since only [FeedDetailScreen] ever needs one post's comments at a time.
  Stream<List<CommentModel>> watchComments(String postId) =>
      _socialRepository.watchComments(postId);

  // ── Follow (Optimistic UI) ─────────────────────────────────────────────────

  /// Toggles follow on a user.
  ///
  /// Guarded by [_inFlightFollow] against rapid double-taps — without it, a
  /// second tap landing before the first `followUser`/`unfollowUser` call
  /// resolves reads the *optimistic* (not yet backend-confirmed) state,
  /// fires the opposite backend call, and the two requests can resolve out
  /// of order — leaving Firestore's actual follow state inverted relative
  /// to whatever the UI settled on. Same fix as [togglePati]'s
  /// [_inFlightPati] lock.
  Future<void> toggleFollow(String userId) async {
    if (_inFlightFollow.contains(userId)) return;

    final wasFollowed = _followedUsers.contains(userId);
    _inFlightFollow.add(userId);

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

    _inFlightFollow.remove(userId);

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

    // Backend call
    final result = await _socialRepository.joinEvent(eventId);
    switch (result) {
      case Success():
        _notificationViewModel.addEventNotification(event.title);
      case Failure(:final message):
        // Rollback
        _events[index] = event;
        _errorMessage = message;
        notifyListeners();
    }
  }

  // ── Bookmark ───────────────────────────────────────────────────────────────

  /// Toggles bookmark on [postId] optimistically, confirmed by the repository.
  ///
  /// Guarded by [_inFlightBookmark] — see [toggleFollow]'s doc comment for
  /// why a rapid double-tap needs this lock.
  Future<void> toggleBookmark(String postId) async {
    if (_inFlightBookmark.contains(postId)) return;

    final wasBookmarked = _bookmarkedPosts.contains(postId);
    _inFlightBookmark.add(postId);

    // Optimistic update
    if (wasBookmarked) {
      _bookmarkedPosts.remove(postId);
    } else {
      _bookmarkedPosts.add(postId);
    }
    notifyListeners();

    final result = await _socialRepository.toggleBookmark(postId);
    _inFlightBookmark.remove(postId);

    switch (result) {
      case Success():
        break;
      case Failure(:final message):
        // Rollback
        if (wasBookmarked) {
          _bookmarkedPosts.add(postId);
        } else {
          _bookmarkedPosts.remove(postId);
        }
        _errorMessage = message;
        notifyListeners();
    }
  }

  // ── Listing save ("Kaydet") ────────────────────────────────────────────────

  /// Toggles "kaydet" (save) on [listingId] optimistically, confirmed by the
  /// repository — same shape as [toggleBookmark], separate storage since
  /// listings and posts don't share an ID space. Guarded by
  /// [_inFlightListingBookmark] against rapid double-taps.
  Future<void> toggleListingBookmark(String listingId) async {
    if (_inFlightListingBookmark.contains(listingId)) return;

    final wasSaved = _bookmarkedListings.contains(listingId);
    _inFlightListingBookmark.add(listingId);

    // Optimistic update
    if (wasSaved) {
      _bookmarkedListings.remove(listingId);
    } else {
      _bookmarkedListings.add(listingId);
    }
    notifyListeners();

    final result = await _socialRepository.toggleListingBookmark(listingId);
    _inFlightListingBookmark.remove(listingId);

    switch (result) {
      case Success():
        break;
      case Failure(:final message):
        // Rollback
        if (wasSaved) {
          _bookmarkedListings.add(listingId);
        } else {
          _bookmarkedListings.remove(listingId);
        }
        _errorMessage = message;
        notifyListeners();
    }
  }

  // ── Topluluk üyeliği ("Katıl") ──────────────────────────────────────────────

  /// Toggles membership on [groupId] optimistically, confirmed by the
  /// repository — same shape as [toggleBookmark]. Guarded by
  /// [_inFlightGroupMembership] against rapid double-taps.
  ///
  /// [memberName]/[memberPhoto] are only used on join (denormalized onto
  /// the new `members/{uid}` doc) — see [ISocialRepository.toggleGroupMembership].
  Future<void> toggleGroupMembership(
    String groupId, {
    required String memberName,
    required String memberPhoto,
  }) async {
    if (_inFlightGroupMembership.contains(groupId)) return;

    final wasMember = _joinedGroupIds.contains(groupId);
    _inFlightGroupMembership.add(groupId);

    // Optimistic update
    if (wasMember) {
      _joinedGroupIds.remove(groupId);
    } else {
      _joinedGroupIds.add(groupId);
    }
    notifyListeners();

    final result = await _socialRepository.toggleGroupMembership(
      groupId,
      memberName: memberName,
      memberPhoto: memberPhoto,
    );
    _inFlightGroupMembership.remove(groupId);

    switch (result) {
      case Success():
        break;
      case Failure(:final message):
        // Rollback
        if (wasMember) {
          _joinedGroupIds.add(groupId);
        } else {
          _joinedGroupIds.remove(groupId);
        }
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
