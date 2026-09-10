import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../core/post_event_bus.dart';
import '../core/result.dart';
import '../data/models/post_model.dart';
import '../data/repositories/interfaces/i_post_repository.dart';

/// ViewModel for the Global (Explore) Feed.
///
/// Owns a [PagingController] from the `infinite_scroll_pagination` package and
/// delegates the actual data fetch to [IPostRepository.getGlobalFeed], which
/// performs cursor-based pagination over Firestore (`DocumentSnapshot` cursor)
/// or offset-based pagination in the mock implementation.
///
/// The int [pageKey] in [PagingController] is a monotonic page number used only
/// to let the controller differentiate pages. The real cursor — a Firestore
/// [DocumentSnapshot] when live, or an int offset in mock — is stored in
/// [_nextPageToken] and passed to the repository on each fetch. This keeps the
/// controller contract simple (non-null page key) while preserving the
/// repository's cursor semantics.
class FeedViewModel extends ChangeNotifier {
  final IPostRepository _postRepository;

  /// Page size tuned for mobile — small enough for fast first paint, large
  /// enough to cover a single scroll-screen on most devices.
  static const int _pageSize = 10;

  /// The cursor for the next page. Firestore: [DocumentSnapshot]. Mock: [int].
  /// `null` means "start from the beginning" or "no more pages".
  Object? _nextPageToken;

  final PagingController<int, PostModel> pagingController =
      PagingController(firstPageKey: 0);

  StreamSubscription<PostModel>? _newPostSub;

  FeedViewModel(this._postRepository) {
    pagingController.addPageRequestListener(_fetchPage);
    _newPostSub = PostEventBus.instance.onPostCreated.listen(_onNewPost);
  }

  /// Prepends a freshly created post to the top of the visible list so the
  /// author sees their own post instantly without a pull-to-refresh round-trip.
  ///
  /// Duplicate guard: the Firestore real-time stream on SocialScreen and the
  /// EventBus can both deliver the same post in quick succession. Checking the
  /// id prevents a duplicate-key crash in the PagedListView.
  void _onNewPost(PostModel post) {
    final current = pagingController.itemList;
    if (current != null && !current.any((p) => p.id == post.id)) {
      pagingController.itemList = [post, ...current];
    }
  }

  /// Fetches [pageKey] from the repository and appends it to the controller.
  ///
  /// The first fetch (pageKey == 0) sends a null token so the repository
  /// returns the very first page. Subsequent fetches send the stored cursor.
  Future<void> _fetchPage(int pageKey) async {
    try {
      final tokenForRequest = pageKey == 0 ? null : _nextPageToken;

      final result = await _postRepository.getGlobalFeed(
        pageSize: _pageSize,
        pageToken: tokenForRequest,
      );

      switch (result) {
        case Success(:final data):
          _nextPageToken = data.nextPageToken;

          // End-of-feed signal from the repository: null cursor ⇒ last page.
          if (data.nextPageToken == null) {
            pagingController.appendLastPage(data.posts);
          } else {
            pagingController.appendPage(data.posts, pageKey + 1);
          }

        case Failure(:final message):
          pagingController.error = message;
      }
    } catch (e) {
      pagingController.error = e;
    }
  }

  /// Pull-to-refresh hook. Resets cursor and asks the controller to restart.
  /// `refresh()` clears the item list and re-invokes the page request listener
  /// with `firstPageKey` (0), so our _fetchPage will request a fresh first page.
  Future<void> refresh() async {
    _nextPageToken = null;
    pagingController.refresh();
  }

  @override
  void dispose() {
    _newPostSub?.cancel();
    pagingController.dispose();
    super.dispose();
  }
}
