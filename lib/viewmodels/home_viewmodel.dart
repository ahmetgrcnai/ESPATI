import 'package:flutter/foundation.dart';
import '../core/result.dart';
import '../data/models/post_model.dart';
import '../data/repositories/interfaces/i_post_repository.dart';
import '../data/sample_data.dart';

/// ViewModel for the Home screen.
///
/// Fetches posts and stories via [IPostRepository] and exposes
/// reactive state (loading, error, data) to the UI via [ChangeNotifier].
class HomeViewModel extends ChangeNotifier {
  final IPostRepository _postRepository;

  HomeViewModel(this._postRepository) {
    loadData();
  }

  // ── State Fields ──

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<PostModel> _posts = [];
  List<PostModel> get posts => List.unmodifiable(_posts);

  /// Raw story maps from SampleData — kept for backward-compatible UI rendering.
  List<Map<String, String>> _stories = [];
  List<Map<String, String>> get stories => List.unmodifiable(_stories);

  // ── Public Methods ──

  /// Loads both posts and stories concurrently.
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Fetch posts from repository
    final postsResult = await _postRepository.getPosts();

    switch (postsResult) {
      case Success(:final data):
        _posts = data;
      case Failure(:final message):
        _errorMessage = message;
    }

    // Stories are still loaded from SampleData (thin mapping for now)
    _stories = List<Map<String, String>>.from(
      SampleData.stories.map((s) => Map<String, String>.from(s)),
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Called when the user triggers pull-to-refresh.
  Future<void> refresh() => loadData();
}
