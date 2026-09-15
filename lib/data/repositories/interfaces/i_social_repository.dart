import '../../../core/result.dart';
import '../../models/comment_model.dart';
import '../../models/event_model.dart';
import '../../models/group_member_model.dart';
import '../../models/notification_model.dart';

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

  /// Adds a "Yorum" (comment) to a post. [authorName]/[authorPhoto] are
  /// denormalized onto the comment document — see [CommentModel]. Returns
  /// `true` on success; the real, live comment count is read back via
  /// [watchComments]/[PostModel.commentsCount], not this return value.
  Future<Result<bool>> addYorum(
    String postId,
    String yorum, {
    required String authorName,
    required String authorPhoto,
  });

  /// Real-time stream of a post's comments, oldest first — backs
  /// [FeedDetailScreen]'s comment list. A malformed document is skipped
  /// rather than breaking the whole stream, same convention as
  /// [IPostRepository.getSocialFeed].
  Stream<List<CommentModel>> watchComments(String postId);

  /// Follows a user. Returns true on success.
  Future<Result<bool>> followUser(String userId);

  /// Unfollows a user. Returns true on success.
  Future<Result<bool>> unfollowUser(String userId);

  /// Fetches upcoming Eskişehir events.
  Future<Result<List<EventModel>>> getEvents();

  /// Joins an event. Returns updated attendee count.
  Future<Result<int>> joinEvent(String eventId);

  /// Toggles bookmark on a post. Returns the new bookmarked state.
  Future<Result<bool>> toggleBookmark(String postId);

  /// Toggles "kaydet" (save) on an adoption/lost-pet listing. Same
  /// sub-collection shape as [toggleBookmark], just a separate collection
  /// (`savedListings` vs. `bookmarks`) since listings and posts are
  /// different models with no shared identity space. Returns the new
  /// saved state.
  Future<Result<bool>> toggleListingBookmark(String listingId);

  /// Returns the set of user IDs that the current user follows.
  /// Used to seed [SocialViewModel] on startup.
  Future<Result<Set<String>>> getFollowingIds();

  /// Returns the set of post IDs bookmarked by the current user.
  /// Used to seed [SocialViewModel] on startup.
  Future<Result<Set<String>>> getBookmarkedPostIds();

  /// Returns the set of listing IDs saved by the current user.
  /// Used to seed [SocialViewModel] on startup.
  Future<Result<Set<String>>> getBookmarkedListingIds();

  /// Real-time stream — emits true whenever the current user follows [targetUid].
  ///
  /// Watches the `users/{me}/following/{targetUid}` document existence so the
  /// button state stays accurate even when a follow/unfollow originates from
  /// another device or session.
  Stream<bool> isFollowingStream(String targetUid);

  /// Toggles the current user's membership in a Topluluk group. Same
  /// paired-subcollection + transaction shape as [followUser]/[unfollowUser]
  /// (`communityGroups/{groupId}/members/{uid}` +
  /// `users/{uid}/joinedGroups/{groupId}`, with `communityGroups/{groupId}
  /// .memberCount` kept in sync via `FieldValue.increment`), exposed as one
  /// toggle like [toggleBookmark] rather than two separate methods.
  ///
  /// [memberName]/[memberPhoto] are denormalized onto the new
  /// `members/{uid}` document on join (unused on leave) — see
  /// [GroupMemberModel]. Joining always sets [GroupMemberRole.member]; the
  /// owner role is only ever granted once, at group creation
  /// ([IFormRepository.createGroup]).
  ///
  /// Returns the new membership state.
  Future<Result<bool>> toggleGroupMembership(
    String groupId, {
    required String memberName,
    required String memberPhoto,
  });

  /// Returns the set of group IDs the current user has joined.
  /// Used to seed [SocialViewModel] on startup.
  Future<Result<Set<String>>> getJoinedGroupIds();

  /// Real-time stream of [groupId]'s member list, ordered owner-first then
  /// by [GroupMemberModel.joinedAt] — backs [GroupMembersScreen].
  Stream<List<GroupMemberModel>> watchGroupMembers(String groupId);

  /// Removes [targetUid] from [groupId]: deletes their `members/{uid}` doc,
  /// the `users/{targetUid}/joinedGroups/{groupId}` mirror, decrements
  /// `memberCount`, and writes a [NotificationType.groupKick] document to
  /// `users/{targetUid}/notifications/{id}` (naming [groupName] — the
  /// only real, cross-user notification this app writes; see
  /// [watchMyNotifications]) — all in one atomic batch. Enforcement of
  /// *who* may call this (the group's owner or a moderator, never a plain
  /// member on anyone but themselves) lives in Firestore security rules,
  /// not here.
  Future<Result<bool>> kickGroupMember(
    String groupId,
    String targetUid, {
    required String groupName,
  });

  /// Real-time stream of the current user's own `notifications`
  /// subcollection, newest first — today this only ever contains
  /// [NotificationType.groupKick] entries (see [kickGroupMember]); every
  /// other [NotificationModel] in the app is created locally by
  /// [NotificationViewModel] for the user's own actions, never through
  /// this stream. Emits an empty list when signed out.
  Stream<List<NotificationModel>> watchMyNotifications();

  /// Grants or revokes [GroupMemberRole.moderator] on [targetUid] within
  /// [groupId]. Owner-only (enforced by security rules) — a moderator
  /// cannot promote another member, and the owner's own role can never be
  /// changed this way.
  Future<Result<bool>> setGroupModerator(
    String groupId,
    String targetUid,
    bool isModerator,
  );
}
