import '../../../core/result.dart';
import '../../models/post_model.dart';
import '../../models/story_model.dart';
import '../../sample_data.dart';
import '../interfaces/i_post_repository.dart';

/// Mock implementation of [IPostRepository].
///
/// Returns data from [SampleData] wrapped in [Future.delayed]
/// to simulate real-world network latency (~800ms).
class MockPostRepository implements IPostRepository {
  /// Simulated network delay duration.
  static const _delay = Duration(milliseconds: 800);

  @override
  Future<Result<List<PostModel>>> getPosts() async {
    try {
      await Future.delayed(_delay);

      final posts = SampleData.posts.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        return PostModel(
          id: 'post_$i',
          userId: 'user_$i',
          userName: p['username'] as String,
          userProfileImage: p['avatar'] as String,
          content: p['caption'] as String,
          imageUrl: p['image'] as String,
          likesCount: p['likes'] as int,
          commentsCount: p['comments'] as int,
          locationTag: '',
          timestamp: DateTime.now().subtract(Duration(hours: (i + 1) * 2)),
        );
      }).toList();

      return Success(posts);
    } on Exception catch (e) {
      return Failure('Failed to load posts', exception: e);
    }
  }

  @override
  Future<Result<List<StoryModel>>> getStories() async {
    try {
      await Future.delayed(_delay);

      final stories = SampleData.stories.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return StoryModel(
          id: 'story_$i',
          userId: 'user_$i',
          imageUrl: s['avatar']!,
          isViewed: false,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );
      }).toList();

      return Success(stories);
    } on Exception catch (e) {
      return Failure('Failed to load stories', exception: e);
    }
  }
}
