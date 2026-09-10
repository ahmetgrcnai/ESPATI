import 'dart:async';

import '../../../core/result.dart';
import '../../models/comment_model.dart';
import '../../models/event_model.dart';
import '../interfaces/i_social_repository.dart';

/// Mock implementation of [ISocialRepository].
///
/// Simulates backend operations with ~1 second delay.
class MockSocialRepository implements ISocialRepository {
  static const _delay = Duration(seconds: 1);

  // In-memory pati (like) counts keyed by postId
  final Map<String, int> _patiSayilari = {};

  // In-memory bookmarked post IDs
  final Set<String> _bookmarkedPosts = {};
  final Set<String> _bookmarkedListings = {};
  final Set<String> _joinedGroups = {};

  // In-memory comments keyed by postId, replayed to new subscribers just
  // like [MockFormRepository.watchListings] does for listings.
  final Map<String, List<CommentModel>> _comments = {};
  final Map<String, StreamController<List<CommentModel>>> _commentControllers =
      {};
  int _commentIdSeq = 0;

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
  Future<Result<bool>> addYorum(
    String postId,
    String yorum, {
    required String authorName,
    required String authorPhoto,
  }) async {
    try {
      await Future.delayed(_delay);
      final trimmed = yorum.trim();
      if (trimmed.isEmpty) return const Failure('Yorum boş olamaz.');

      final comment = CommentModel(
        id: 'comment_${_commentIdSeq++}',
        authorId: 'mock_user',
        authorName: authorName,
        authorPhoto: authorPhoto,
        text: trimmed,
        timestamp: DateTime.now(),
      );
      final list = _comments.putIfAbsent(postId, () => []);
      list.add(comment);
      _commentControllers[postId]?.add(List.unmodifiable(list));
      return const Success(true);
    } on Exception catch (e) {
      return Failure('Yorum eklenemedi. Lütfen tekrar deneyin.', exception: e);
    }
  }

  @override
  Stream<List<CommentModel>> watchComments(String postId) {
    final controller = _commentControllers.putIfAbsent(
      postId,
      () => StreamController<List<CommentModel>>.broadcast(),
    );
    // Replay current state to a new subscriber, then forward future updates
    // — mirrors MockFormRepository.watchListings' "immediate current value,
    // then live updates" behaviour.
    Stream<List<CommentModel>> replay() async* {
      yield List.unmodifiable(_comments[postId] ?? const []);
      yield* controller.stream;
    }

    return replay();
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

  @override
  Future<Result<bool>> toggleBookmark(String postId) async {
    try {
      await Future.delayed(_delay);
      if (_bookmarkedPosts.contains(postId)) {
        _bookmarkedPosts.remove(postId);
        return const Success(false);
      } else {
        _bookmarkedPosts.add(postId);
        return const Success(true);
      }
    } on Exception catch (e) {
      return Failure('Kaydet işlemi başarısız.', exception: e);
    }
  }

  @override
  Future<Result<bool>> toggleListingBookmark(String listingId) async {
    try {
      await Future.delayed(_delay);
      if (_bookmarkedListings.contains(listingId)) {
        _bookmarkedListings.remove(listingId);
        return const Success(false);
      } else {
        _bookmarkedListings.add(listingId);
        return const Success(true);
      }
    } on Exception catch (e) {
      return Failure('Kaydet işlemi başarısız.', exception: e);
    }
  }

  @override
  Future<Result<bool>> toggleGroupMembership(String groupId) async {
    try {
      await Future.delayed(_delay);
      if (_joinedGroups.contains(groupId)) {
        _joinedGroups.remove(groupId);
        return const Success(false);
      } else {
        _joinedGroups.add(groupId);
        return const Success(true);
      }
    } on Exception catch (e) {
      return Failure('İşlem başarısız.', exception: e);
    }
  }

  @override
  Future<Result<Set<String>>> getFollowingIds() async {
    await Future.delayed(_delay);
    return const Success({});
  }

  @override
  Future<Result<Set<String>>> getBookmarkedPostIds() async {
    await Future.delayed(_delay);
    return Success(Set<String>.from(_bookmarkedPosts));
  }

  @override
  Future<Result<Set<String>>> getBookmarkedListingIds() async {
    await Future.delayed(_delay);
    return Success(Set<String>.from(_bookmarkedListings));
  }

  @override
  Future<Result<Set<String>>> getJoinedGroupIds() async {
    await Future.delayed(_delay);
    return Success(Set<String>.from(_joinedGroups));
  }

  @override
  Stream<bool> isFollowingStream(String targetUid) => Stream.value(false);

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
