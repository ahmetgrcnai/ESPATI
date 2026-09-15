import 'dart:io';

import '../../../core/result.dart';
import '../../models/listing_model.dart';
import '../../models/chat_group_model.dart';

/// Abstract interface for all data operations on the Form Hub screen.
///
/// Covers two domains: pet listings (İlanlar) and community groups (Gruplar).
/// Direct messages (Mesajlar) moved to [IChatRepository] — a real,
/// Firestore-backed 1-on-1 messaging system replaced the mock DM list this
/// interface used to serve (Sprint 8).
///
/// Listings are live (Phase 1 — see [FirestoreFormRepository]); Groups are
/// live too as of Step 70, reading the `communityGroups` collection.
abstract class IFormRepository {
  /// Streams all pet listings (both [ListingStatus.kayip] and
  /// [ListingStatus.sahiplendirme]) sorted by [ListingModel.createdAt] desc.
  ///
  /// Real-time — any user's new listing appears for everyone without a
  /// manual refresh, matching the Social/Chat/Pets pattern.
  Stream<List<ListingModel>> watchListings();

  /// Returns all community groups, pinned groups first.
  Future<Result<List<ChatGroupModel>>> getChatGroups();

  /// Creates a new, user-owned community group in `communityGroups` and,
  /// in the same write, joins the creator to it as [GroupMemberRole.owner]
  /// — [memberCount] starts at 1, not 0. [isPinned] is always false —
  /// pinning is a manual, admin-curated action, never set by user-facing
  /// group creation. [petCategory] is always [PetCategory.all] for these
  /// groups; [customCategory] carries whatever free-text category the
  /// creator typed themselves (see [ChatGroupModel.categoryLabel]).
  /// [creatorName]/[creatorPhoto] are denormalized onto the owner's
  /// `members/{uid}` document, same convention as every other
  /// author-snapshot field in this codebase. [coverImage], if given, is
  /// uploaded to Storage before the group document is written — the
  /// returned [ChatGroupModel.coverImageUrl] is the final download URL.
  /// [bannedWords] seeds [ChatGroupModel.bannedWords].
  Future<Result<ChatGroupModel>> createGroup({
    required String name,
    required String description,
    required PetCategory petCategory,
    String? customCategory,
    required String creatorName,
    required String creatorPhoto,
    File? coverImage,
    List<String> bannedWords,
  });

  /// Deletes [groupId] entirely: the group document itself and every
  /// `members/{uid}` sub-document (Firestore never cascade-deletes a
  /// subcollection on its own). Posts/listings that carried this
  /// [groupId] are left as-is — they simply point at a group that no
  /// longer exists, same as any other stale denormalized reference in
  /// this codebase; deleting user content isn't this action's job.
  /// Owner-only — enforced by Firestore security rules, not here.
  Future<Result<void>> deleteGroup(String groupId);

  /// Uploads [images] and persists a new listing derived from [listing].
  ///
  /// The caller does not need to set [ListingModel.id] or
  /// [ListingModel.imageUrls] — the repository assigns a document ID and
  /// fills in the uploaded download URLs. Returns the final, persisted
  /// [ListingModel] on success.
  Future<Result<ListingModel>> createListing(
    ListingModel listing,
    List<File> images,
  );

  /// Discovery/search over listings, filtered by any combination of
  /// [species], [district], [status], and free-text [keyword].
  ///
  /// All parameters are optional; a call with none set returns the same
  /// recency-ordered set as [watchListings] (as a one-time snapshot, not a
  /// stream). See the Phase 2 strategy note on
  /// `FirestoreFormRepository.searchListings` for why this filters
  /// client-side over a bounded read rather than issuing a Firestore
  /// compound query.
  Future<Result<List<ListingModel>>> searchListings({
    String? species,
    String? district,
    ListingStatus? status,
    String? keyword,
  });

  /// Deletes the listing with [listingId]. Powers "Benim İlanlarım" on the
  /// Profile tab — callers are expected to only expose this for listings the
  /// current user authored; enforcement itself lives in security rules.
  Future<Result<void>> deleteListing(String listingId);
}
