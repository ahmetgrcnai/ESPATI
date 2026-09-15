import 'dart:async';

import '../../../core/result.dart';
import '../../models/comment_model.dart';
import '../../models/event_model.dart';
import '../../models/group_member_model.dart';
import '../../models/notification_model.dart';
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

  // In-memory group member lists keyed by groupId — [MockFormRepository]'s
  // own seed groups are a separate repository with no shared state (same
  // "mock repos aren't cross-consistent" looseness as everywhere else in
  // mock mode; kUseMock is false in production, see service_locator.dart),
  // so this only tracks joins/kicks made through *this* repository during
  // the session.
  final Map<String, List<GroupMemberModel>> _groupMembers = {};
  final Map<String, StreamController<List<GroupMemberModel>>>
      _groupMemberControllers = {};

  void _emitMembers(String groupId) {
    _groupMemberControllers[groupId]
        ?.add(List.unmodifiable(_groupMembers[groupId] ?? const []));
  }

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
  Future<Result<bool>> toggleGroupMembership(
    String groupId, {
    required String memberName,
    required String memberPhoto,
  }) async {
    try {
      await Future.delayed(_delay);
      final members = _groupMembers.putIfAbsent(groupId, () => []);
      if (_joinedGroups.contains(groupId)) {
        _joinedGroups.remove(groupId);
        members.removeWhere((m) => m.uid == 'current_user');
        _emitMembers(groupId);
        return const Success(false);
      } else {
        _joinedGroups.add(groupId);
        members.add(GroupMemberModel(
          uid: 'current_user',
          name: memberName,
          photoUrl: memberPhoto,
          role: GroupMemberRole.member,
          joinedAt: DateTime.now(),
        ));
        _emitMembers(groupId);
        return const Success(true);
      }
    } on Exception catch (e) {
      return Failure('İşlem başarısız.', exception: e);
    }
  }

  @override
  Stream<List<GroupMemberModel>> watchGroupMembers(String groupId) {
    final controller = _groupMemberControllers.putIfAbsent(
      groupId,
      () => StreamController<List<GroupMemberModel>>.broadcast(),
    );
    Stream<List<GroupMemberModel>> replay() async* {
      yield List.unmodifiable(_groupMembers[groupId] ?? const []);
      yield* controller.stream;
    }

    return replay();
  }

  final List<NotificationModel> _myNotifications = [];
  final _notificationsController =
      StreamController<List<NotificationModel>>.broadcast();
  int _notificationIdSeq = 0;

  @override
  Future<Result<bool>> kickGroupMember(
    String groupId,
    String targetUid, {
    required String groupName,
  }) async {
    try {
      await Future.delayed(_delay);
      _groupMembers[groupId]?.removeWhere((m) => m.uid == targetUid);
      _emitMembers(groupId);

      // Mock mode has a single simulated "current_user" identity — a kick
      // notification only makes sense to surface when that's who got
      // kicked (kicking anyone else has no session to notify).
      if (targetUid == 'current_user') {
        _myNotifications.insert(
          0,
          NotificationModel(
            id: 'notif_kick_${_notificationIdSeq++}',
            type: NotificationType.groupKick,
            title: 'Gruptan Çıkarıldın',
            message: '"$groupName" grubundan çıkarıldın.',
            timestamp: DateTime.now(),
          ),
        );
        _notificationsController.add(List.unmodifiable(_myNotifications));
      }
      return const Success(true);
    } on Exception catch (e) {
      return Failure('Üye çıkarılamadı.', exception: e);
    }
  }

  @override
  Stream<List<NotificationModel>> watchMyNotifications() async* {
    yield List.unmodifiable(_myNotifications);
    yield* _notificationsController.stream;
  }

  @override
  Future<Result<bool>> setGroupModerator(
    String groupId,
    String targetUid,
    bool isModerator,
  ) async {
    try {
      await Future.delayed(_delay);
      final members = _groupMembers[groupId];
      if (members == null) return const Success(true);
      final idx = members.indexWhere((m) => m.uid == targetUid);
      if (idx != -1) {
        members[idx] = members[idx].copyWith(
          role: isModerator ? GroupMemberRole.moderator : GroupMemberRole.member,
        );
        _emitMembers(groupId);
      }
      return const Success(true);
    } on Exception catch (e) {
      return Failure('Yetki güncellenemedi.', exception: e);
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
