import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../data/models/mating_match_model.dart';
import '../data/models/pet_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/interfaces/i_chat_repository.dart';
import '../data/repositories/interfaces/i_mating_repository.dart';
import '../data/repositories/interfaces/i_pet_repository.dart';
import '../data/repositories/interfaces/i_user_repository.dart';

/// ViewModel powering [MatingSwipeScreen] — the Ruh Eşi (mating) module's
/// Tinder/Bumble-style discover deck.
///
/// Picks the current user's first [PetModel.isEligibleForMating] pet as
/// "the pet doing the swiping" ([mySwipingPet]) by default; when the user
/// has more than one eligible pet, [MatingSwipeScreen] shows a picker and
/// calls [selectSwipingPet] to switch, which reloads the deck for that pet.
///
/// A completed mutual match doesn't just record data — it creates the real
/// chat room via [IChatRepository] (same one every other 1-on-1
/// conversation in the app uses, `autoAccept: true` since both sides
/// already opted in by matching) and resolves the other owner's profile
/// via [IUserRepository.getUserById] so the celebration screen can show a
/// name, not just a uid.
class MatingViewModel extends ChangeNotifier {
  MatingViewModel({
    required IMatingRepository matingRepository,
    required IChatRepository chatRepository,
    required IUserRepository userRepository,
    required IPetRepository petRepository,
    required UserModel currentUser,
  })  : _matingRepository = matingRepository,
        _chatRepository = chatRepository,
        _userRepository = userRepository,
        _petRepository = petRepository,
        _currentUser = currentUser {
    _init();
  }

  final IMatingRepository _matingRepository;
  final IChatRepository _chatRepository;
  final IUserRepository _userRepository;
  final IPetRepository _petRepository;
  final UserModel _currentUser;

  bool _loading = true;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PetModel? _mySwipingPet;
  PetModel? get mySwipingPet => _mySwipingPet;

  List<PetModel> _eligiblePets = [];

  /// Every pet of the current user's that [PetModel.isEligibleForMating] —
  /// powers [MatingSwipeScreen]'s "which pet?" picker. Empty until [_init]
  /// resolves; a single-entry list means the picker has nothing to offer,
  /// which the screen treats the same as "no picker at all".
  List<PetModel> get eligiblePets => _eligiblePets;

  List<PetModel> _deck = [];

  /// The card on top of the deck — `null` once it's exhausted.
  PetModel? get currentCard => _deck.isNotEmpty ? _deck.first : null;

  bool _swiping = false;

  /// Set right after a swipe completes a match — [MatingSwipeScreen] shows
  /// the "Eşleştiniz!" overlay while this is non-null, then calls
  /// [clearCelebration].
  MatingMatchModel? _celebrationMatch;
  MatingMatchModel? get celebrationMatch => _celebrationMatch;
  UserModel? _matchedOwner;
  UserModel? get matchedOwner => _matchedOwner;
  PetModel? _matchedPet;
  PetModel? get matchedPet => _matchedPet;

  Future<void> _init() async {
    final petsResult = await _petRepository.getAllPets();
    if (petsResult case Success(:final data)) {
      _eligiblePets = data.where((p) => p.isEligibleForMating).toList();
      _mySwipingPet = _eligiblePets.firstOrNull;
    }

    if (_mySwipingPet == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    await _loadDeck();
  }

  /// Switches which of the current user's eligible pets is doing the
  /// swiping — called from [MatingSwipeScreen]'s pet picker. No-op if
  /// [pet] is already active; otherwise clears the current deck and
  /// reloads it for [pet].
  Future<void> selectSwipingPet(PetModel pet) async {
    if (pet.id == _mySwipingPet?.id) return;
    _mySwipingPet = pet;
    _deck = [];
    _loading = true;
    notifyListeners();
    await _loadDeck();
  }

  Future<void> _loadDeck() async {
    final pet = _mySwipingPet;
    if (pet == null) return;

    final result = await _matingRepository.getDiscoverDeck(
      excludeOwnerId: _currentUser.id,
      excludePetId: pet.id,
    );
    switch (result) {
      case Success(:final data):
        _deck = data;
      case Failure(:final message):
        _errorMessage = message;
    }
    _loading = false;
    notifyListeners();
  }

  /// Swipes [currentCard] — `liked: true` is a "right swipe" (interested),
  /// `false` a "left swipe" (pas geç). Removes the card immediately
  /// (optimistic — there's nothing meaningful to roll back to on failure,
  /// unlike a toggle) and, if this swipe completes a mutual match, kicks
  /// off [_celebrateMatch].
  Future<void> swipeCurrent({required bool liked}) async {
    final myPet = _mySwipingPet;
    final target = currentCard;
    if (myPet == null || target == null || _swiping) return;

    _swiping = true;
    _deck = _deck.sublist(1);
    notifyListeners();

    final result = await _matingRepository.swipe(
      fromPet: myPet,
      fromOwnerId: _currentUser.id,
      toPet: target,
      toOwnerId: target.ownerId,
      liked: liked,
    );

    switch (result) {
      case Success(:final data):
        switch (data.outcome) {
          case MatingSwipeOutcome.matched:
            final match = data.match;
            if (match != null) await _celebrateMatch(match, target);
          case MatingSwipeOutcome.limitReached:
            _errorMessage =
                '${myPet.name} ya da ${target.name} bu yıl için eşleşme limitine ulaştı.';
          case MatingSwipeOutcome.noMatch:
            break;
        }
      case Failure(:final message):
        _errorMessage = message;
    }

    _swiping = false;
    notifyListeners();
  }

  Future<void> _celebrateMatch(MatingMatchModel match, PetModel otherPet) async {
    UserModel? otherOwner;
    final ownerResult = await _userRepository.getUserById(otherPet.ownerId);
    if (ownerResult case Success(:final data)) otherOwner = data;

    final myName = _currentUser.name.isEmpty ? _currentUser.email : _currentUser.name;
    final otherName = (otherOwner == null || otherOwner.name.isEmpty)
        ? (otherOwner?.email ?? otherPet.name)
        : otherOwner.name;

    String chatRoomId = '';
    final roomResult = await _chatRepository.getOrCreateChatRoom(
      currentUserId: _currentUser.id,
      currentUserName: myName,
      currentUserPhoto: _currentUser.profilePicture,
      otherUserId: otherPet.ownerId,
      otherUserName: otherName,
      otherUserPhoto: otherOwner?.profilePicture ?? '',
      // Both sides already opted in by matching — nothing pending to accept.
      autoAccept: true,
    );
    if (roomResult case Success(:final data)) {
      chatRoomId = data.roomId;
      await _matingRepository.attachChatRoom(match.id, chatRoomId);
    }

    _celebrationMatch = match.copyWith(chatRoomId: chatRoomId);
    _matchedOwner = otherOwner;
    _matchedPet = otherPet;
    notifyListeners();
  }

  void clearCelebration() {
    _celebrationMatch = null;
    _matchedOwner = null;
    _matchedPet = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
