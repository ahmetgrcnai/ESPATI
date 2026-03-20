import '../../../core/result.dart';
import '../../models/event_model.dart';
import '../interfaces/i_social_repository.dart';

/// Mock implementation of [ISocialRepository].
///
/// Simulates backend operations with ~1 second delay.
class MockSocialRepository implements ISocialRepository {
  static const _delay = Duration(seconds: 1);

  // Track like counts per post
  final Map<String, int> _likeCounts = {};

  // Track comment counts per post
  final Map<String, int> _commentCounts = {};

  // Track attendee counts per event
  final Map<String, int> _attendeeCounts = {
    'event_1': 24,
    'event_2': 18,
    'event_3': 31,
  };

  @override
  Future<Result<int>> likePost(String postId) async {
    try {
      await Future.delayed(_delay);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
      return Success(_likeCounts[postId]!);
    } on Exception catch (e) {
      return Failure('Failed to like post', exception: e);
    }
  }

  @override
  Future<Result<int>> unlikePost(String postId) async {
    try {
      await Future.delayed(_delay);
      _likeCounts[postId] = ((_likeCounts[postId] ?? 1) - 1).clamp(0, 999999);
      return Success(_likeCounts[postId]!);
    } on Exception catch (e) {
      return Failure('Failed to unlike post', exception: e);
    }
  }

  @override
  Future<Result<int>> addComment(String postId, String comment) async {
    try {
      await Future.delayed(_delay);
      _commentCounts[postId] = (_commentCounts[postId] ?? 0) + 1;
      return Success(_commentCounts[postId]!);
    } on Exception catch (e) {
      return Failure('Failed to add comment', exception: e);
    }
  }

  @override
  Future<Result<bool>> followUser(String userId) async {
    try {
      await Future.delayed(_delay);
      return const Success(true);
    } on Exception catch (e) {
      return Failure('Failed to follow user', exception: e);
    }
  }

  @override
  Future<Result<bool>> unfollowUser(String userId) async {
    try {
      await Future.delayed(_delay);
      return const Success(true);
    } on Exception catch (e) {
      return Failure('Failed to unfollow user', exception: e);
    }
  }

  @override
  Future<Result<List<EventModel>>> getEvents() async {
    try {
      await Future.delayed(_delay);
      return Success(_eskisehirEvents);
    } on Exception catch (e) {
      return Failure('Failed to load events', exception: e);
    }
  }

  @override
  Future<Result<int>> joinEvent(String eventId) async {
    try {
      await Future.delayed(_delay);
      _attendeeCounts[eventId] = (_attendeeCounts[eventId] ?? 0) + 1;
      return Success(_attendeeCounts[eventId]!);
    } on Exception catch (e) {
      return Failure('Failed to join event', exception: e);
    }
  }

  /// Eskişehir seed events.
  static final List<EventModel> _eskisehirEvents = [
    EventModel(
      id: 'event_1',
      title: 'Porsuk Kenarı Pati Yürüyüşü',
      locationName: 'Adalar, Porsuk Çayı',
      dateTime: DateTime.now().add(const Duration(days: 3, hours: 10)),
      attendeeCount: 24,
      description:
          'Eskişehir\'in güzel Porsuk Çayı kenarında evcil hayvanlarımızla yürüyüş! '
          'Tüm patili dostlar davetli 🐾',
    ),
    EventModel(
      id: 'event_2',
      title: 'Sazova Köpek Oyun Günü',
      locationName: 'Sazova Parkı',
      dateTime: DateTime.now().add(const Duration(days: 7, hours: 14)),
      attendeeCount: 18,
      description:
          'Sazova Parkı\'nda köpekler için özel oyun alanı ve sosyalleşme etkinliği. '
          'Agility parkurları ve ödüller var!',
    ),
    EventModel(
      id: 'event_3',
      title: 'Kanlıkavak Kedi Buluşması',
      locationName: 'Kanlıkavak Parkı',
      dateTime: DateTime.now().add(const Duration(days: 5, hours: 16)),
      attendeeCount: 31,
      description:
          'Kedi severler bir araya geliyor! Kanlıkavak Parkı\'nda kedi bakım ipuçları, '
          'mama paylaşımı ve kedilerimizi tanıştırma etkinliği.',
    ),
  ];
}
