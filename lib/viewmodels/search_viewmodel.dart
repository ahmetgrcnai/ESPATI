import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../data/models/user_model.dart';
import '../data/repositories/interfaces/i_user_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATE ENUM
// ─────────────────────────────────────────────────────────────────────────────

/// Finite states for the search screen — exhaustively handled in the UI via
/// a switch expression on [SearchViewModel.state].
enum SearchState {
  /// Nothing typed yet — show the idle splash illustration.
  initial,

  /// Debounce timer running or Firestore call in-flight — show shimmer.
  loading,

  /// Firestore returned ≥ 1 matching users — show the results list.
  success,

  /// Firestore returned 0 results for a non-blank query — show empty state.
  empty,

  /// Repository returned a [Failure] — surface error message.
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW MODEL
// ─────────────────────────────────────────────────────────────────────────────

/// ViewModel for the User Search screen.
///
/// Lifecycle:
///   • Created per-route (factory pattern) via a scoped [ChangeNotifierProvider]
///     in the navigation call — not in the global service locator — so it is
///     disposed automatically when the screen pops.
///
/// Debounce:
///   [onQueryChanged] cancels and restarts a 500 ms [Timer] on every keystroke.
///   Only the final keystroke within a 500 ms window triggers a Firestore read,
///   keeping read costs proportional to deliberate input, not typing speed.
class SearchViewModel extends ChangeNotifier {
  final IUserRepository _userRepo;

  SearchViewModel({required IUserRepository userRepository})
      : _userRepo = userRepository;

  // ── State ──────────────────────────────────────────────────────────────────

  SearchState _state = SearchState.initial;
  SearchState get state => _state;

  List<UserModel> _results = [];
  List<UserModel> get searchResults => List.unmodifiable(_results);

  /// The query string that produced the current [searchResults].
  /// Displayed in the empty/error states so the user knows what was searched.
  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Debounce ───────────────────────────────────────────────────────────────

  Timer? _debounce;
  static const _kDebounce = Duration(milliseconds: 500);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called on every keystroke from the search [TextField].
  ///
  /// • Blank / whitespace → reset to [SearchState.initial] immediately,
  ///   zero network calls.
  /// • Non-blank → transition to [SearchState.loading] instantly (shows shimmer
  ///   after the first character so the UI feels reactive), then fire the
  ///   Firestore query after the debounce window closes.
  void onQueryChanged(String query) {
    _debounce?.cancel();
    _errorMessage = null;

    if (query.trim().isEmpty) {
      _state = SearchState.initial;
      _results = [];
      _lastQuery = '';
      notifyListeners();
      return;
    }

    // Transition to loading immediately — shimmer appears before the 500 ms
    // window closes so the user always gets visual feedback on first keystroke.
    _state = SearchState.loading;
    notifyListeners();

    _debounce = Timer(_kDebounce, () => _executeSearch(query.trim()));
  }

  /// Clears the search and resets to [SearchState.initial].
  /// Called by the × clear button.
  void clearSearch() {
    _debounce?.cancel();
    _state = SearchState.initial;
    _results = [];
    _lastQuery = '';
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _executeSearch(String query) async {
    _lastQuery = query;
    // Remain in loading state during the Firestore round-trip.

    final result = await _userRepo.searchUsers(query);

    switch (result) {
      case Success(:final data):
        _results = data;
        _state = data.isEmpty ? SearchState.empty : SearchState.success;
        _errorMessage = null;
      case Failure(:final message):
        _results = [];
        _state = SearchState.error;
        _errorMessage = message;
        debugPrint('[SearchViewModel] searchUsers error: $message');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
