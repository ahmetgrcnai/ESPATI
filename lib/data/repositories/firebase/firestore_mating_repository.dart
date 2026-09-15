import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/result.dart';
import '../../models/mating_match_model.dart';
import '../../models/mating_swipe_model.dart';
import '../../models/pet_model.dart';
import '../interfaces/i_mating_repository.dart';

/// Firestore implementation of [IMatingRepository].
///
/// Firestore paths:
///   `users/{uid}/pets/{petId}`     — read via a `pets` **collection-group**
///                                    query (pets live per-owner, not in a
///                                    flat top-level collection — the
///                                    Çiftleşme deck needs to query across
///                                    every owner at once).
///   `matingSwipes/{fromPetId}_{toPetId}` — one directional swipe.
///   `matingMatches/{autoId}`             — a confirmed mutual match.
///
/// ⚠️ Two queries here need a manual composite index created in the
/// Firebase Console the first time they run (Firestore's error message
/// links directly to create it): [_matchesInvolvingPet] (`petIds`
/// array-contains + `matchedAt` range) and [watchMyMatches] (`ownerIds`
/// array-contains + `matchedAt` orderBy). The deck query itself
/// (`collectionGroup` + single equality filter) does not need one.
class FirestoreMatingRepository implements IMatingRepository {
  FirestoreMatingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _kSwipes = 'matingSwipes';
  static const _kMatches = 'matingMatches';

  // ── Discover deck ────────────────────────────────────────────────────────

  @override
  Future<Result<List<PetModel>>> getDiscoverDeck({
    required String excludeOwnerId,
    required String excludePetId,
    int limit = 20,
  }) async {
    try {
      // Already-swiped pets (liked or passed) never resurface — fetched
      // first so it can be filtered client-side below, same "bounded read
      // + client-side filter" pattern FirestoreFormRepository.searchListings
      // already uses for its own multi-condition filtering.
      final swipedSnap = await _firestore
          .collection(_kSwipes)
          .where('fromPetId', isEqualTo: excludePetId)
          .get();
      final alreadySwipedIds =
          swipedSnap.docs.map((d) => d.data()['toPetId'] as String).toSet();

      // Over-fetch — some candidates get filtered out client-side below —
      // then trim to the requested [limit].
      final candidatesSnap = await _firestore
          .collectionGroup('pets')
          .where('isAvailableForMating', isEqualTo: true)
          .limit(limit * 3)
          .get();

      final deck = <PetModel>[];
      for (final doc in candidatesSnap.docs) {
        if (deck.length >= limit) break;
        try {
          final pet = PetModel.fromFirestore(doc.data(), id: doc.id);
          if (pet.ownerId == excludeOwnerId) continue;
          if (alreadySwipedIds.contains(pet.id)) continue;
          if (!pet.isEligibleForMating) continue;
          deck.add(pet);
        } catch (_) {
          // Skip a malformed pet document rather than breaking the deck.
        }
      }
      return Success(deck);
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Eşleşme listesi yüklenemedi.', exception: e);
    }
  }

  // ── Swipe ────────────────────────────────────────────────────────────────

  @override
  Future<Result<MatingSwipeResult>> swipe({
    required PetModel fromPet,
    required String fromOwnerId,
    required PetModel toPet,
    required String toOwnerId,
    required bool liked,
  }) async {
    try {
      final mySwipe = MatingSwipeModel(
        fromPetId: fromPet.id,
        fromOwnerId: fromOwnerId,
        toPetId: toPet.id,
        toOwnerId: toOwnerId,
        liked: liked,
        timestamp: DateTime.now(),
      );
      await _firestore
          .collection(_kSwipes)
          .doc(MatingSwipeModel.docId(fromPet.id, toPet.id))
          .set(mySwipe.toFirestore());

      if (!liked) {
        return const Success(MatingSwipeResult(MatingSwipeOutcome.noMatch));
      }

      // Mutual? Check the other pet's swipe straight at its deterministic
      // doc id — a direct .get(), not a query.
      final reverseDoc = await _firestore
          .collection(_kSwipes)
          .doc(MatingSwipeModel.docId(toPet.id, fromPet.id))
          .get();
      final reverseLiked = reverseDoc.data()?['liked'] as bool? ?? false;
      if (!reverseLiked) {
        return const Success(MatingSwipeResult(MatingSwipeOutcome.noMatch));
      }

      // Mutual like confirmed — but Madde 4's frequency limit gates
      // whether a *match* actually gets created, on both sides.
      final myRecentMatches = await _matchesInvolvingPet(fromPet.id);
      final theirRecentMatches = await _matchesInvolvingPet(toPet.id);
      if (myRecentMatches >= IMatingRepository.kMaxMatchesPerYear ||
          theirRecentMatches >= IMatingRepository.kMaxMatchesPerYear) {
        return const Success(
            MatingSwipeResult(MatingSwipeOutcome.limitReached));
      }

      final matchRef = _firestore.collection(_kMatches).doc();
      final match = MatingMatchModel(
        id: matchRef.id,
        petAId: fromPet.id,
        petBId: toPet.id,
        ownerAId: fromOwnerId,
        ownerBId: toOwnerId,
        matchedAt: DateTime.now(),
      );
      await matchRef.set(match.toFirestore());

      return Success(MatingSwipeResult(MatingSwipeOutcome.matched, match: match));
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('İşlem başarısız.', exception: e);
    }
  }

  /// Counts [petId]'s matches in the last 365 days — see the class doc
  /// comment's index warning.
  Future<int> _matchesInvolvingPet(String petId) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 365));
    final snap = await _firestore
        .collection(_kMatches)
        .where('petIds', arrayContains: petId)
        .where('matchedAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .get();
    return snap.docs.length;
  }

  @override
  Future<Result<void>> attachChatRoom(String matchId, String chatRoomId) async {
    try {
      await _firestore
          .collection(_kMatches)
          .doc(matchId)
          .update({'chatRoomId': chatRoomId});
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Sohbet odası eşleşmeye kaydedilemedi.', exception: e);
    }
  }

  @override
  Stream<List<MatingMatchModel>> watchMyMatches(String ownerId) {
    return _firestore
        .collection(_kMatches)
        .where('ownerIds', arrayContains: ownerId)
        .orderBy('matchedAt', descending: true)
        .snapshots()
        .map((snap) {
      final matches = <MatingMatchModel>[];
      for (final doc in snap.docs) {
        try {
          matches.add(MatingMatchModel.fromFirestore(doc));
        } catch (_) {
          // Skip a malformed match rather than breaking the list.
        }
      }
      return matches;
    });
  }

  String _mapError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok.';
      case 'failed-precondition':
        return 'Bu sorgu için bir Firestore dizini (index) eksik.';
      default:
        return e.message ?? 'Beklenmedik bir hata oluştu.';
    }
  }
}
