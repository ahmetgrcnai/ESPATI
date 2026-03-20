import '../../../core/result.dart';
import '../../models/post_model.dart';
import '../../models/story_model.dart';

/// Abstract interface for post-related data operations.
///
/// Implementations can fetch from local mock data, REST API, or Firebase.
abstract class IPostRepository {
  /// Fetches the list of feed posts.
  Future<Result<List<PostModel>>> getPosts();

  /// Fetches the list of stories for the home feed.
  Future<Result<List<StoryModel>>> getStories();
}
