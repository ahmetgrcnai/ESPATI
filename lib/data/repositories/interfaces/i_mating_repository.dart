import '../../../core/result.dart';
import '../../models/mating_match_model.dart';
import '../../models/pet_model.dart';

/// What happened when a swipe was recorded — see [IMatingRepository.swipe].
enum MatingSwipeOutcome {
  /// Recorded; no match (either a pass, or a like the other pet hasn't
  /// reciprocated yet).
  noMatch,

  /// Both pets have now liked each other — a [MatingMatchModel] was
  /// created (see [MatingSwipeResult.match]).
  matched,

  /// Would have completed a mutual match, but one side (or both) has
  /// already hit [IMatingRepository.kMaxMatchesPerYear] for the rolling
  /// year — Madde 4's frequency-limit safeguard against a profile being
  /// used to farm breeding partners. The swipe itself is still recorded
  /// (so this decision is remembered), just no match is created.
  limitReached,
}

class MatingSwipeResult {
  final MatingSwipeOutcome outcome;
  final MatingMatchModel? match;

  const MatingSwipeResult(this.outcome, {this.match});
}

/// Abstract interface for the Çiftleşme (mating) module's discovery +
/// swipe + match data layer.
///
/// Deliberately has no dependency on [IChatRepository] — creating the
/// actual chat room for a fresh match is [MatingViewModel]'s job (it
/// already depends on both repositories), keeping every repository in
/// this codebase single-purpose.
abstract class IMatingRepository {
  /// Max new matches a single pet may form in a rolling 365-day window —
  /// Madde 4's ethics/anti-abuse pass, not a UI preference. See
  /// [MatingSwipeOutcome.limitReached].
  static const int kMaxMatchesPerYear = 2;

  /// Fetches up to [limit] mating-eligible pets ([PetModel.isEligibleForMating])
  /// for the swipe deck, excluding [excludeOwnerId]'s own pets and every
  /// pet [excludePetId] has already swiped on (liked or passed). Not a
  /// live stream — the deck is meant to be paged through, not silently
  /// reshuffled mid-swipe by someone else's edit.
  Future<Result<List<PetModel>>> getDiscoverDeck({
    required String excludeOwnerId,
    required String excludePetId,
    int limit = 20,
  });

  /// Records a swipe from [fromPet] onto [toPet]. See [MatingSwipeOutcome]
  /// for what the three possible results mean.
  Future<Result<MatingSwipeResult>> swipe({
    required PetModel fromPet,
    required String fromOwnerId,
    required PetModel toPet,
    required String toOwnerId,
    required bool liked,
  });

  /// Fills in the chat room id on an already-created match, right after
  /// [MatingViewModel] creates it via [IChatRepository.getOrCreateChatRoom].
  Future<Result<void>> attachChatRoom(String matchId, String chatRoomId);

  /// Real-time stream of every match [ownerId] is party to (through either
  /// of their pets), newest first.
  Stream<List<MatingMatchModel>> watchMyMatches(String ownerId);
}
