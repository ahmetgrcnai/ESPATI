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
