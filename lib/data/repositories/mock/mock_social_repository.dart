import '../../../core/result.dart';
import '../../models/event_model.dart';
import '../interfaces/i_social_repository.dart';

/// Mock implementation of [ISocialRepository].
///
/// Simulates backend operations with ~1 second delay.
class MockSocialRepository implements ISocialRepository {
  static const _delay = Duration(seconds: 1);

  // In-memory pati (like) counts keyed by postId
  final Map<String, int> _patiSayilari = {};

  // In-memory yorum (comment) counts keyed by postId
  final Map<String, int> _yorumSayilari = {};

  // In-memory attendee counts keyed by eventId
  final Map<String, int> _attendeeCounts = {
    'event_1': 24,
    'event_2': 18,
    'event_3': 31,
  };

  @override
  Future<Result<int>> patiVer(String postId) async {
    try {
      await Future.delayed(_delay);
      _patiSayilari[postId] = (_patiSayilari[postId] ?? 0) + 1;
      return Success(_patiSayilari[postId]!);
    } on Exception catch (e) {
      return Failure('Pati gönderilemedi. Lütfen tekrar deneyin.', exception: e);
    }
  }

  @override
  Future<Result<int>> patiGeri(String postId) async {
    try {
      await Future.delayed(_delay);
      _patiSayilari[postId] =
          ((_patiSayilari[postId] ?? 1) - 1).clamp(0, 999999);
      return Success(_patiSayilari[postId]!);
    } on Exception catch (e) {
      return Failure('Pati geri alınamadı. Lütfen tekrar deneyin.', exception: e);
    }
  }

  @override
  Future<Result<int>> addYorum(String postId, String yorum) async {
    try {
      await Future.delayed(_delay);
      _yorumSayilari[postId] = (_yorumSayilari[postId] ?? 0) + 1;
      return Success(_yorumSayilari[postId]!);
    } on Exception catch (e) {
      return Failure('Yorum eklenemedi. Lütfen tekrar deneyin.', exception: e);
    }
  }

  @override
  Future<Result<bool>> followUser(String userId) async {
    try {
      await Future.delayed(_delay);
      return const Success(true);
    } on Exception catch (e) {
      return Failure('Takip edilemedi.', exception: e);
    }
  }

  @override
  Future<Result<bool>> unfollowUser(String userId) async {
    try {
      await Future.delayed(_delay);
      return const Success(true);
    } on Exception catch (e) {
      return Failure('Takip bırakılamadı.', exception: e);
    }
  }

  @override
  Future<Result<List<EventModel>>> getEvents() async {
    try {
      await Future.delayed(_delay);
      return Success(_eskisehirEvents);
    } on Exception catch (e) {
      return Failure('Etkinlikler yüklenemedi.', exception: e);
    }
  }

  @override
  Future<Result<int>> joinEvent(String eventId) async {
    try {
      await Future.delayed(_delay);
      _attendeeCounts[eventId] = (_attendeeCounts[eventId] ?? 0) + 1;
      return Success(_attendeeCounts[eventId]!);
    } on Exception catch (e) {
      return Failure('Etkinliğe katılınamadı.', exception: e);
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
