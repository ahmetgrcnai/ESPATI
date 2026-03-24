import '../../../core/result.dart';
import '../../models/event_model.dart';

/// Abstract interface for social interaction operations.
///
/// Method naming follows the ESPATI brand language:
///   • "Pati" (paw) — the like interaction (formerly "Yala")
///   • "Yorum"      — the comment interaction (formerly "Havla")
abstract class ISocialRepository {
  /// Registers a "Pati" (like) on a post. Returns the updated pati count.
  Future<Result<int>> patiVer(String postId);

  /// Removes a "Pati" (like) from a post. Returns the updated pati count.
  Future<Result<int>> patiGeri(String postId);

  /// Adds a "Yorum" (comment) to a post. Returns the updated yorum count.
  Future<Result<int>> addYorum(String postId, String yorum);

  /// Follows a user. Returns true on success.
  Future<Result<bool>> followUser(String userId);

  /// Unfollows a user. Returns true on success.
  Future<Result<bool>> unfollowUser(String userId);

  /// Fetches upcoming Eskişehir events.
  Future<Result<List<EventModel>>> getEvents();

  /// Joins an event. Returns updated attendee count.
  Future<Result<int>> joinEvent(String eventId);
}
