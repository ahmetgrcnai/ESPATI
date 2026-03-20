import '../../../core/result.dart';
import '../../models/event_model.dart';

/// Abstract interface for social interaction operations.
abstract class ISocialRepository {
  /// Likes a post. Returns updated like count.
  Future<Result<int>> likePost(String postId);

  /// Unlikes a post. Returns updated like count.
  Future<Result<int>> unlikePost(String postId);

  /// Adds a comment to a post. Returns updated comment count.
  Future<Result<int>> addComment(String postId, String comment);

  /// Follows a user. Returns true on success.
  Future<Result<bool>> followUser(String userId);

  /// Unfollows a user. Returns true on success.
  Future<Result<bool>> unfollowUser(String userId);

  /// Fetches upcoming Eskişehir events.
  Future<Result<List<EventModel>>> getEvents();

  /// Joins an event. Returns updated attendee count.
  Future<Result<int>> joinEvent(String eventId);
}
