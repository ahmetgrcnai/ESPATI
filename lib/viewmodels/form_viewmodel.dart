import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/result.dart';
import '../data/models/listing_model.dart';
import '../data/models/chat_group_model.dart';
import '../data/repositories/interfaces/i_form_repository.dart';

/// Inbox sub-tab selection.
enum InboxView { groups, messages }

/// Manages state for two domains:
/// - İlanlar: pet listing filter + real-time data ([IFormRepository.watchListings]).
///   Consumed by [ListingFormScreen], [FeedDetailScreen]'s mini-map data,
///   and the Topluluk tab's [GroupDetailScreen] mixed feed.
/// - Gruplar: community group list ([ChatGroupModel], one-time fetch from
///   the `communityGroups` Firestore collection as of Step 70) — the
///   backbone of [CommunityHubScreen]'s Topluluk group list (Phase 2 Step 4),
///   not a Forum sub-tab.
///
/// Mesajlar (1-on-1 chats) is owned by [ChatViewModel] instead — real,
/// Firestore-backed messaging (Sprint 8), surfaced via [InboxScreen].
///
/// UI layer must use [Consumer<FormViewModel>] and never hold business logic.
class FormViewModel extends ChangeNotifier {
  final IFormRepository _repository;

  StreamSubscription<List<ListingModel>>? _listingsSubscription;

  FormViewModel(this._repository) {
    _subscribeToListings();
    loadAll();
  }

  @override
  void dispose() {
    _listingsSubscription?.cancel();
    super.dispose();
  }

  // ── Loading & Error State (Groups) ──────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Listings ──────────────────────────────────────────────────────────────

  /// True until the first [IFormRepository.watchListings] emission arrives.
  bool _isListingsLoading = true;
  bool get isListingsLoading => _isListingsLoading;

  String? _listingsError;
  String? get listingsError => _listingsError;

  List<ListingModel> _allListings = [];

  /// Unfiltered live listings — for consumers (e.g. the unified Discovery
  /// map) that need their own independent filter without mutating
  /// [_listingFilter], which is shared UI state read by the Forum tab.
  List<ListingModel> get allListings => List.unmodifiable(_allListings);

  /// Active filter. One of: 'all' | 'kayip' | 'sahiplendirme' | 'acil'.
  String _listingFilter = 'all';
  String get listingFilter => _listingFilter;

  /// Listings filtered by the current [_listingFilter].
  List<ListingModel> get filteredListings {
    switch (_listingFilter) {
      case 'kayip':
        return _allListings.where((l) => l.status == ListingStatus.kayip).toList();
      case 'sahiplendirme':
        return _allListings
            .where((l) => l.status == ListingStatus.sahiplendirme)
            .toList();
      case 'acil':
        return _allListings.where((l) => l.isUrgent).toList();
      case 'all':
      default:
        return List.unmodifiable(_allListings);
    }
  }

  int get lostCount =>
      _allListings.where((l) => l.status == ListingStatus.kayip).length;

  int get adoptionCount =>
      _allListings.where((l) => l.status == ListingStatus.sahiplendirme).length;

  int get urgentCount => _allListings.where((l) => l.isUrgent).length;

  /// Listings authored by [authorId] — powers "Benim İlanlarım" on the
  /// Profile tab. Reuses the already-live [_allListings] stream rather than
  /// issuing a separate Firestore query.
  List<ListingModel> listingsByAuthor(String authorId) => _allListings
      .where((l) => l.authorId == authorId)
      .toList();

  // ── Community Groups ──────────────────────────────────────────────────────

  List<ChatGroupModel> _chatGroups = [];
  List<ChatGroupModel> get chatGroups => List.unmodifiable(_chatGroups);

  /// Locally nudges a group's displayed member count by [delta] (+1/-1)
  /// right when the user joins/leaves it. [loadAll] fetches groups with a
  /// one-time `.get()`, not a live listener (see its own doc comment), so
  /// without this the count shown would stay stale until the next full
  /// reload even though [SocialViewModel.toggleGroupMembership] already
  /// confirmed the real change in Firestore.
  void adjustGroupMemberCount(String groupId, int delta) {
    final idx = _chatGroups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final current = _chatGroups[idx];
    _chatGroups = List<ChatGroupModel>.from(_chatGroups)
      ..[idx] = current.copyWith(
          memberCount: (current.memberCount + delta).clamp(0, 1 << 31));
    notifyListeners();
  }

  // ── Inbox sub-tab ─────────────────────────────────────────────────────────

  InboxView _inboxView = InboxView.groups;
  InboxView get inboxView => _inboxView;

  // ── Listings stream ────────────────────────────────────────────────────────

  void _subscribeToListings() {
    _listingsSubscription = _repository.watchListings().listen(
      (listings) {
        _allListings = listings;
        _isListingsLoading = false;
        _listingsError = null;
        notifyListeners();
      },
      onError: (e) {
        _isListingsLoading = false;
        _listingsError = 'İlanlar yüklenemedi.';
        debugPrint('[FormViewModel] watchListings error: $e');
        notifyListeners();
      },
    );
  }

  // ── Public Actions ────────────────────────────────────────────────────────

  /// Fetches Groups (one-time — real `communityGroups` Firestore read as of
  /// Step 70). Listings update live via the [_subscribeToListings] stream
  /// and don't need a manual reload.
  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getChatGroups();

    switch (result) {
      case Success(:final data):
        _chatGroups = data;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Updates the listings filter. No-op if the filter hasn't changed.
  void setListingFilter(String filter) {
    if (_listingFilter == filter) return;
    _listingFilter = filter;
    notifyListeners();
  }

  /// Switches the inbox between groups and direct messages views.
  void setInboxView(InboxView view) {
    if (_inboxView == view) return;
    _inboxView = view;
    notifyListeners();
  }

  // ── Listing Creation ──────────────────────────────────────────────────────

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _submitError;
  String? get submitError => _submitError;

  /// Uploads [images] and persists [listing] via the repository.
  ///
  /// Does not update [filteredListings] locally — the live
  /// [_subscribeToListings] stream picks up the new document on its own,
  /// same as [ProfileViewModel.addPet] relies on its pets stream.
  ///
  /// Returns `true` on success, `false` on failure.
  /// The UI should observe [isSubmitting] to show a loading indicator.
  Future<bool> createListing(ListingModel listing, List<File> images) async {
    if (_isSubmitting) {
      debugPrint('[FormViewModel] createListing blocked — already submitting.');
      return false;
    }

    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final result = await _repository.createListing(listing, images);

      switch (result) {
        case Success():
          _isSubmitting = false;
          notifyListeners();
          return true;

        case Failure(:final message):
          _submitError = message;
          debugPrint('[FormViewModel] createListing failure: $message');
          _isSubmitting = false;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _submitError = 'İlan oluşturulamadı. Lütfen tekrar deneyin.';
      debugPrint('[FormViewModel] createListing exception: $e');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Listing Deletion ("Benim İlanlarım" management) ────────────────────────

  bool _isDeletingListing = false;
  bool get isDeletingListing => _isDeletingListing;

  String? _deleteListingError;
  String? get deleteListingError => _deleteListingError;

  /// Deletes [listingId] via the repository.
  ///
  /// Does not remove it from [filteredListings] locally — the live
  /// [_subscribeToListings] stream reflects the deletion on its own.
  /// Returns `true` on success, `false` on failure.
  Future<bool> deleteListing(String listingId) async {
    if (_isDeletingListing) return false;

    _isDeletingListing = true;
    _deleteListingError = null;
    notifyListeners();

    try {
      final result = await _repository.deleteListing(listingId);

      switch (result) {
        case Success():
          _isDeletingListing = false;
          notifyListeners();
          return true;
        case Failure(:final message):
          _deleteListingError = message;
          debugPrint('[FormViewModel] deleteListing failure: $message');
          _isDeletingListing = false;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _deleteListingError = 'İlan silinemedi. Lütfen tekrar deneyin.';
      debugPrint('[FormViewModel] deleteListing exception: $e');
      _isDeletingListing = false;
      notifyListeners();
      return false;
    }
  }

  void clearDeleteListingError() {
    if (_deleteListingError == null) return;
    _deleteListingError = null;
    notifyListeners();
  }

  /// Clears any pending submission error.
  void clearSubmitError() {
    if (_submitError == null) return;
    _submitError = null;
    notifyListeners();
  }

  // ── Group Creation ────────────────────────────────────────────────────────

  bool _isCreatingGroup = false;
  bool get isCreatingGroup => _isCreatingGroup;

  String? _createGroupError;
  String? get createGroupError => _createGroupError;

  /// Creates a new community group — the creator is auto-joined as owner
  /// in the same repository call (see [IFormRepository.createGroup]), so
  /// there's no separate membership step here. On success, prepends the
  /// group to [_chatGroups] immediately — same "don't wait for a full
  /// reload" pattern as [adjustGroupMemberCount], since [loadAll] is a
  /// one-time fetch, not a live listener. Returns the new group on success
  /// so the caller (the Grup Oluştur screen) can navigate straight into
  /// [GroupDetailScreen].
  Future<ChatGroupModel?> createGroup({
    required String name,
    required String description,
    required PetCategory petCategory,
    String? customCategory,
    required String creatorName,
    required String creatorPhoto,
    File? coverImage,
    List<String> bannedWords = const [],
  }) async {
    if (_isCreatingGroup) return null;

    _isCreatingGroup = true;
    _createGroupError = null;
    notifyListeners();

    final result = await _repository.createGroup(
      name: name,
      description: description,
      petCategory: petCategory,
      customCategory: customCategory,
      creatorName: creatorName,
      creatorPhoto: creatorPhoto,
      coverImage: coverImage,
      bannedWords: bannedWords,
    );

    switch (result) {
      case Success(:final data):
        _chatGroups = [data, ..._chatGroups];
        _isCreatingGroup = false;
        notifyListeners();
        return data;
      case Failure(:final message):
        _createGroupError = message;
        _isCreatingGroup = false;
        notifyListeners();
        return null;
    }
  }

  void clearCreateGroupError() {
    if (_createGroupError == null) return;
    _createGroupError = null;
    notifyListeners();
  }

  /// Deletes [groupId] (owner-only — enforced by Firestore rules, not
  /// here) and drops it from [_chatGroups] immediately on success, same
  /// "don't wait for a reload" reasoning as [createGroup]. Returns `true`
  /// on success.
  Future<bool> deleteGroup(String groupId) async {
    final result = await _repository.deleteGroup(groupId);
    switch (result) {
      case Success():
        _chatGroups = _chatGroups.where((g) => g.id != groupId).toList();
        notifyListeners();
        return true;
      case Failure(:final message):
        _createGroupError = message;
        notifyListeners();
        return false;
    }
  }
}
