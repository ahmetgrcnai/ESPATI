import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/result.dart';
import '../../models/chat_group_model.dart';
import '../../models/listing_model.dart';
import '../interfaces/i_form_repository.dart';

/// Firestore + Firebase Storage implementation of [IFormRepository].
///
/// Firestore path : `listings/{listingId}`, `communityGroups/{groupId}`
/// Storage path   : `listings/{authorId}/{listingId}/{index}.jpg`
class FirestoreFormRepository implements IFormRepository {
  FirestoreFormRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  static const _kListings = 'listings';
  static const _kCommunityGroups = 'communityGroups';

  // ── Listings — real-time stream ──────────────────────────────────────────

  /// Streams the most recent listings, newest first.
  ///
  /// `.limit(100)` guards against an unbounded listener re-reading the whole
  /// collection on every write as it grows — same cost-control reasoning as
  /// [FirestorePostRepository.getSocialFeed]. A corrupt document is skipped
  /// rather than breaking the whole stream.
  @override
  Stream<List<ListingModel>> watchListings() {
    return _firestore
        .collection(_kListings)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final listings = <ListingModel>[];
      for (final doc in snapshot.docs) {
        try {
          listings.add(ListingModel.fromJson({'id': doc.id, ...doc.data()}));
        } catch (_) {
          // Skip malformed document — don't take down the whole stream.
        }
      }
      return listings;
    });
  }

  // ── Groups ────────────────────────────────────────────────────────────────

  /// Reads every document in `communityGroups`, pinned groups first.
  ///
  /// A one-time `.get()`, not `.snapshots()` — matches [getChatGroups]'s own
  /// "one-time fetch" contract in [IFormRepository]; the group directory
  /// changes rarely enough that [CommunityHubScreen]'s pull-to-retry (via
  /// [FormViewModel.loadAll]) is enough, unlike listings which need a live
  /// stream. An empty collection returns an empty list — no error, no
  /// synthetic fallback data — [CommunityHubScreen] already renders that as
  /// its normal "Henüz topluluk grubu yok" empty state.
  @override
  Future<Result<List<ChatGroupModel>>> getChatGroups() async {
    try {
      final snapshot = await _firestore.collection(_kCommunityGroups).get();
      final groups = <ChatGroupModel>[];
      for (final doc in snapshot.docs) {
        try {
          groups.add(ChatGroupModel.fromJson({'id': doc.id, ...doc.data()}));
        } catch (_) {
          // Skip malformed document — don't take down the whole list.
        }
      }
      groups.sort((a, b) => (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0));
      return Success(groups);
    } on FirebaseException catch (e) {
      return Failure('Gruplar yüklenemedi.', exception: e);
    } on Exception catch (e) {
      return Failure('Gruplar yüklenemedi.', exception: e);
    }
  }

  // ── Create listing ────────────────────────────────────────────────────────

  /// Creates a listing:
  ///
  /// 1. Requires a signed-in user — the listing's `authorId` must match the
  ///    Storage/Firestore security rules' `request.auth.uid` check.
  /// 2. Reserves a document ID up front ([CollectionReference.doc]) so photo
  ///    paths can be scoped under it before the Firestore write happens.
  /// 3. Uploads every picked image in parallel to
  ///    `listings/{authorId}/{listingId}/{index}.jpg`.
  /// 4. Writes the final document with the resulting download URLs.
  ///
  /// If a photo upload fails partway through, no Firestore document is
  /// written — an orphaned Storage file may remain, mirroring the same
  /// documented trade-off as [FirestorePostRepository.createPost].
  @override
  Future<Result<ListingModel>> createListing(
    ListingModel listing,
    List<File> images,
  ) async {
    const tag = '[FirestoreFormRepository.createListing]';
    try {
      debugPrint('$tag Step 1: checking auth + reserving document ID...');
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('$tag ABORT: no signed-in user.');
        return const Failure('İlan oluşturmak için giriş yapmanız gerekiyor.');
      }

      final docRef = _firestore.collection(_kListings).doc();
      final listingId = docRef.id;
      debugPrint('$tag Step 2: uploading ${images.length} image(s) for '
          'listing $listingId...');

      final imageUrls = await Future.wait(
        images.asMap().entries.map((entry) async {
          debugPrint('$tag   uploading image ${entry.key}...');
          final url =
              await _uploadPhoto(user.uid, listingId, entry.key, entry.value);
          debugPrint('$tag   image ${entry.key} uploaded -> $url');
          return url;
        }),
      ).timeout(const Duration(seconds: 60));
      debugPrint('$tag Step 3: all images uploaded, writing Firestore document...');

      final finalListing = listing.copyWith(
        id: listingId,
        authorId: user.uid,
        imageUrls: imageUrls,
      );

      await docRef.set(finalListing.toJson()).timeout(const Duration(seconds: 15));
      debugPrint('$tag Step 4: success — listing $listingId written.');

      return Success(finalListing);
    } on FirebaseException catch (e) {
      debugPrint('$tag FAILED: FirebaseException code=${e.code} message=${e.message}');
      return Failure(_mapFirebaseError(e), exception: e);
    } on TimeoutException {
      debugPrint('$tag FAILED: timed out.');
      return const Failure(
        'İlan zaman aşımına uğradı. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on Exception catch (e) {
      debugPrint('$tag FAILED: Exception: $e');
      return Failure('İlan kaydedilemedi. Lütfen tekrar deneyin.', exception: e);
    } catch (e, stack) {
      debugPrint('$tag FAILED: non-Exception throwable: $e\n$stack');
      return Failure(
        'İlan kaydedilemedi. Lütfen tekrar deneyin.',
        exception: e is Exception ? e : null,
      );
    }
  }

  // ── Discovery / search ───────────────────────────────────────────────────

  /// Phase 2 strategy: client-side faceted filtering over a bounded,
  /// recency-ordered read — deliberately **not** a Firestore compound query.
  ///
  /// Combining species + district + status + keyword server-side would need
  /// a composite index per active-facet combination (roughly a dozen, once
  /// you include the with/without-keyword variants) for a collection that,
  /// at current city-scale volume, already fits in a single bounded read —
  /// the same `.limit(100)` window [watchListings] already uses. So this
  /// issues exactly one simple query (`orderBy(createdAt).limit(100)`, no
  /// `.where()` at all — zero new indexes required) and applies every facet
  /// in Dart.
  ///
  /// [keyword] does a case-insensitive **substring** match across name,
  /// species, type, description, and location — strictly better UX than a
  /// tokenized `array-contains-any` (matches partial words), and free to do
  /// once the documents are already client-side.
  ///
  /// Migration trigger: once active listings routinely exceed 100 and this
  /// window starts truncating real results, replace the body of this method
  /// with `.where()`/`array-contains-any` queries against the `species`,
  /// `location`, `status`, and `searchKeywords` fields already being written
  /// by [ListingModel.toJson] — the model and [IFormRepository] contract
  /// don't need to change, only this method's internals.
  @override
  Future<Result<List<ListingModel>>> searchListings({
    String? species,
    String? district,
    ListingStatus? status,
    String? keyword,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_kListings)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 15));

      final normalizedKeyword = keyword?.trim().toLowerCase();

      final results = <ListingModel>[];
      for (final doc in snapshot.docs) {
        ListingModel listing;
        try {
          listing = ListingModel.fromJson({'id': doc.id, ...doc.data()});
        } catch (_) {
          continue; // Skip malformed document.
        }

        if (species != null && species.isNotEmpty && listing.species != species) {
          continue;
        }
        if (district != null && district.isNotEmpty && listing.location != district) {
          continue;
        }
        if (status != null && listing.status != status) {
          continue;
        }
        if (normalizedKeyword != null && normalizedKeyword.isNotEmpty) {
          final haystack = '${listing.name} ${listing.species} ${listing.type} '
                  '${listing.description} ${listing.location}'
              .toLowerCase();
          if (!haystack.contains(normalizedKeyword)) continue;
        }

        results.add(listing);
      }

      return Success(results);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on TimeoutException {
      return const Failure(
        'Arama zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.',
      );
    } on Exception catch (e) {
      return Failure('Arama başarısız oldu.', exception: e);
    } catch (e) {
      return Failure('Arama başarısız oldu.', exception: e is Exception ? e : null);
    }
  }

  // ── Delete listing ───────────────────────────────────────────────────────

  /// Deletes `listings/{listingId}`. Does not clean up the associated
  /// Storage photos — same documented orphaned-file trade-off as
  /// [createListing]; a Cloud Function sweep is the eventual fix.
  @override
  Future<Result<void>> deleteListing(String listingId) async {
    try {
      await _firestore
          .collection(_kListings)
          .doc(listingId)
          .delete()
          .timeout(const Duration(seconds: 15));
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on TimeoutException {
      return const Failure(
        'Silme işlemi zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.',
      );
    } on Exception catch (e) {
      return Failure('İlan silinemedi. Lütfen tekrar deneyin.', exception: e);
    } catch (e) {
      return Failure('İlan silinemedi. Lütfen tekrar deneyin.',
          exception: e is Exception ? e : null);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<String> _uploadPhoto(
    String authorId,
    String listingId,
    int index,
    File image,
  ) async {
    final ref =
        _storage.ref().child('listings/$authorId/$listingId/$index.jpg');
    await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
      case 'unauthorized':
        return 'Bu işlem için yetkiniz yok.';
      case 'unavailable':
        return 'Sunucu şu anda kullanılamıyor. Lütfen tekrar deneyin.';
      case 'deadline-exceeded':
        return 'İstek zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.';
      case 'resource-exhausted':
        return 'Servis kotası doldu. Lütfen daha sonra tekrar deneyin.';
      case 'object-not-found':
        return 'Dosya bulunamadı.';
      case 'canceled':
        return 'İşlem iptal edildi.';
      default:
        return e.message ?? 'Beklenmedik bir hata oluştu.';
    }
  }
}
