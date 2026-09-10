import 'dart:async';

import '../data/models/post_model.dart';

/// Process-wide event bus for newly created posts.
///
/// Purpose: the Global Feed uses cursor-based pagination via
/// [FeedViewModel.pagingController] — it does NOT maintain a Firestore
/// snapshot subscription. When a user successfully publishes a post we need
/// the feed to reflect it *immediately* without a full refresh round-trip.
///
/// This bus is the lightweight bridge:
///   • [CreatePostViewModel.submit] → [emitPostCreated] on success.
///   • [FeedViewModel] listens to [onPostCreated] and prepends the post into
///     its PagingController's item list.
///
/// The bus is intentionally a singleton with an app-lifetime broadcast stream.
/// It is never closed — its lifetime matches the process, so there is no
/// dispose hazard for late subscribers.
class PostEventBus {
  PostEventBus._();

  /// Singleton entry point.
  static final PostEventBus instance = PostEventBus._();

  final StreamController<PostModel> _createdCtrl =
      StreamController<PostModel>.broadcast();

  /// Emits every time a post has been successfully persisted to the backend.
  /// The payload is the fully-hydrated [PostModel] including the Storage
  /// download URL, so subscribers can render it without any extra fetches.
  Stream<PostModel> get onPostCreated => _createdCtrl.stream;

  /// Notifies all subscribers that [post] was just created.
  /// Safe to call from any isolate scope that has a reference to the
  /// singleton; the underlying stream is broadcast.
  void emitPostCreated(PostModel post) {
    if (_createdCtrl.isClosed) return;
    _createdCtrl.add(post);
  }
}
