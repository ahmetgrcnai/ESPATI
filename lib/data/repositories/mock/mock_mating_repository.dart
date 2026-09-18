import 'dart:async';

import '../../../core/result.dart';
import '../../models/mating_match_model.dart';
import '../../models/pet_model.dart';
import '../interfaces/i_mating_repository.dart';

/// Mock implementation of [IMatingRepository].
///
/// Seeds a small fixed deck of eligible mock pets (distinct from
/// [MockPetRepository]'s own seed data — mock repos aren't cross-consistent
/// in this codebase, same looseness already accepted for groups/social;
/// `kUseMock` is false in production, see service_locator.dart) so the
/// swipe screen has something real to render offline.
class MockMatingRepository implements IMatingRepository {
  static const _delay = Duration(milliseconds: 500);

  final Map<String, bool> _swipes = {}; // '${from}_${to}' -> liked
  final List<MatingMatchModel> _matches = [];
  final _matchesController =
      StreamController<List<MatingMatchModel>>.broadcast();
  int _matchIdSeq = 0;

  static final List<PetModel> _seedDeck = [
    PetModel(
      id: 'mate_pet_1',
      ownerId: 'user_1',
      name: 'Zeytin',
      breed: 'Golden Retriever',
      age: 3,
      gender: PetGender.female,
      medicalHistorySummary: '',
      petType: PetType.dog,
      photoUrl: '',
      bio: 'Enerjik ve sosyal bir Golden.',
      weight: 24,
      isAvailableForMating: true,
      isVaccinated: true,
      vaccinationCardUrl: 'mock://vaccination_card',
      characterTags: const [PetCharacterTag.enerjik, PetCharacterTag.oyuncu],
      matingPurpose: PetMatingPurpose.puppyExcitement,
    ),
    PetModel(
      id: 'mate_pet_2',
      ownerId: 'user_2',
      name: 'Duman',
      breed: 'British Shorthair',
      age: 2,
      gender: PetGender.male,
      medicalHistorySummary: '',
      petType: PetType.cat,
      photoUrl: '',
      bio: 'Sakin, uysal, kucak kedisi.',
      weight: 5,
      isAvailableForMating: true,
      isVaccinated: true,
      vaccinationCardUrl: 'mock://vaccination_card',
      characterTags: const [PetCharacterTag.uysal, PetCharacterTag.sakin],
      matingPurpose: PetMatingPurpose.familyBuilding,
    ),
    PetModel(
      id: 'mate_pet_3',
      ownerId: 'user_3',
      name: 'Barış',
      breed: 'Kangal',
      age: 4,
      gender: PetGender.male,
      medicalHistorySummary: '',
      petType: PetType.dog,
      photoUrl: '',
      bio: 'Bağımsız karakterli, sakin bir Kangal.',
      weight: 45,
      isAvailableForMating: true,
      isVaccinated: true,
      vaccinationCardUrl: 'mock://vaccination_card',
      characterTags: const [PetCharacterTag.bagimsiz, PetCharacterTag.sakin],
      matingPurpose: PetMatingPurpose.lookingForFriend,
    ),
  ];

  @override
  Future<Result<List<PetModel>>> getDiscoverDeck({
    required String excludeOwnerId,
    required String excludePetId,
    int limit = 20,
  }) async {
    await Future.delayed(_delay);
    final deck = _seedDeck
        .where((p) => p.ownerId != excludeOwnerId)
        .where((p) => !_swipes.containsKey('${excludePetId}_${p.id}'))
        .take(limit)
        .toList();
    return Success(deck);
  }

  @override
  Future<Result<MatingSwipeResult>> swipe({
    required PetModel fromPet,
    required String fromOwnerId,
    required PetModel toPet,
    required String toOwnerId,
    required bool liked,
  }) async {
    await Future.delayed(_delay);
    _swipes['${fromPet.id}_${toPet.id}'] = liked;

    if (!liked) {
      return const Success(MatingSwipeResult(MatingSwipeOutcome.noMatch));
    }

    final reverseLiked = _swipes['${toPet.id}_${fromPet.id}'] ?? false;
    if (!reverseLiked) {
      return const Success(MatingSwipeResult(MatingSwipeOutcome.noMatch));
    }

    final cutoff = DateTime.now().subtract(const Duration(days: 365));
    final myRecent = _matches
        .where((m) => m.involvesPet(fromPet.id) && m.matchedAt.isAfter(cutoff))
        .length;
    final theirRecent = _matches
        .where((m) => m.involvesPet(toPet.id) && m.matchedAt.isAfter(cutoff))
        .length;
    if (myRecent >= IMatingRepository.kMaxMatchesPerYear ||
        theirRecent >= IMatingRepository.kMaxMatchesPerYear) {
      return const Success(MatingSwipeResult(MatingSwipeOutcome.limitReached));
    }

    final match = MatingMatchModel(
      id: 'match_${_matchIdSeq++}',
      petAId: fromPet.id,
      petBId: toPet.id,
      ownerAId: fromOwnerId,
      ownerBId: toOwnerId,
      matchedAt: DateTime.now(),
    );
    _matches.insert(0, match);
    _matchesController.add(List.unmodifiable(_matches));

    return Success(MatingSwipeResult(MatingSwipeOutcome.matched, match: match));
  }

  @override
  Future<Result<void>> attachChatRoom(String matchId, String chatRoomId) async {
    await Future.delayed(_delay);
    final idx = _matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      _matches[idx] = _matches[idx].copyWith(chatRoomId: chatRoomId);
      _matchesController.add(List.unmodifiable(_matches));
    }
    return const Success(null);
  }

  @override
  Stream<List<MatingMatchModel>> watchMyMatches(String ownerId) async* {
    yield List.unmodifiable(
        _matches.where((m) => m.ownerAId == ownerId || m.ownerBId == ownerId));
    yield* _matchesController.stream.map(
        (all) => all.where((m) => m.ownerAId == ownerId || m.ownerBId == ownerId).toList());
  }
}
