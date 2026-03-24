import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/result.dart';
import '../data/models/listing_model.dart';
import '../data/models/chat_group_model.dart';
import '../data/models/direct_message_model.dart';
import '../data/repositories/interfaces/i_form_repository.dart';

/// Inbox sub-tab selection.
enum InboxView { groups, messages }

/// ViewModel for [FormHubScreen].
///
/// Manages state for three domains:
/// - İlanlar: pet listing filter + data
/// - Gruplar: community group list
/// - Mesajlar: direct message conversations
///
/// UI layer must use [Consumer<FormViewModel>] and never hold business logic.
class FormViewModel extends ChangeNotifier {
  final IFormRepository _repository;

  FormViewModel(this._repository) {
    loadAll();
  }

  // ── Loading & Error State ──────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Listings ──────────────────────────────────────────────────────────────

  List<ListingModel> _allListings = [];

  /// Active filter. One of: 'all' | 'kayip' | 'sahiplendirme'.
  String _listingFilter = 'all';
  String get listingFilter => _listingFilter;

  /// Listings filtered by the current [_listingFilter].
  List<ListingModel> get filteredListings {
    if (_listingFilter == 'all') return List.unmodifiable(_allListings);
    final target = _listingFilter == 'kayip'
        ? ListingStatus.kayip
        : ListingStatus.sahiplendirme;
    return _allListings.where((l) => l.status == target).toList();
  }

  int get lostCount =>
      _allListings.where((l) => l.status == ListingStatus.kayip).length;

  int get adoptionCount =>
      _allListings.where((l) => l.status == ListingStatus.sahiplendirme).length;

  // ── Community Groups ──────────────────────────────────────────────────────

  List<ChatGroupModel> _chatGroups = [];
  List<ChatGroupModel> get chatGroups => List.unmodifiable(_chatGroups);

  int get totalGroupUnread =>
      _chatGroups.fold(0, (sum, g) => sum + g.unreadCount);

  // ── Direct Messages ───────────────────────────────────────────────────────

  List<DirectMessageModel> _directMessages = [];
  List<DirectMessageModel> get directMessages =>
      List.unmodifiable(_directMessages);

  int get totalDmUnread =>
      _directMessages.fold(0, (sum, d) => sum + d.unreadCount);

  int get totalInboxUnread => totalGroupUnread + totalDmUnread;

  // ── Inbox sub-tab ─────────────────────────────────────────────────────────

  InboxView _inboxView = InboxView.groups;
  InboxView get inboxView => _inboxView;

  // ── Public Actions ────────────────────────────────────────────────────────

  /// Fetches all data concurrently. Safe to call multiple times.
  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final results = await Future.wait([
      _repository.getListings(),
      _repository.getChatGroups(),
      _repository.getDirectMessages(),
    ]);

    final listingsResult = results[0] as Result<List<ListingModel>>;
    final groupsResult = results[1] as Result<List<ChatGroupModel>>;
    final dmsResult = results[2] as Result<List<DirectMessageModel>>;

    switch (listingsResult) {
      case Success(:final data):
        _allListings = data;
      case Failure(:final message):
        _errorMessage = message;
    }

    switch (groupsResult) {
      case Success(:final data):
        _chatGroups = data;
      case Failure(:final message):
        _errorMessage ??= message;
    }

    switch (dmsResult) {
      case Success(:final data):
        _directMessages = data;
      case Failure(:final message):
        _errorMessage ??= message;
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

  /// Marks all messages in a group as read. Call when user opens a group.
  void markGroupRead(String groupId) {
    final idx = _chatGroups.indexWhere((g) => g.id == groupId);
    if (idx == -1 || _chatGroups[idx].unreadCount == 0) return;
    _chatGroups = List<ChatGroupModel>.from(_chatGroups)
      ..[idx] = _chatGroups[idx].copyWith(unreadCount: 0);
    notifyListeners();
  }

  /// Marks a DM conversation as read. Call when user opens a DM thread.
  void markDmRead(String dmId) {
    final idx = _directMessages.indexWhere((d) => d.id == dmId);
    if (idx == -1 || _directMessages[idx].unreadCount == 0) return;
    _directMessages = List<DirectMessageModel>.from(_directMessages)
      ..[idx] = _directMessages[idx].copyWith(unreadCount: 0);
    notifyListeners();
  }

  // ── Listing Creation ──────────────────────────────────────────────────────

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _submitError;
  String? get submitError => _submitError;

  /// Persists [listing] via the repository, prepends it locally on success.
  ///
  /// Returns `true` on success, `false` on failure.
  /// The UI should observe [isSubmitting] to show a loading indicator.
  Future<bool> createListing(ListingModel listing) async {
    if (_isSubmitting) {
      debugPrint('[FormViewModel] createListing blocked — already submitting.');
      return false;
    }

    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final result = await _repository.createListing(listing);

      switch (result) {
        case Success():
          // Prepend so the new listing appears at the top of the list.
          _allListings = [listing, ..._allListings];
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

  /// Clears any pending submission error.
  void clearSubmitError() {
    if (_submitError == null) return;
    _submitError = null;
    notifyListeners();
  }
}
