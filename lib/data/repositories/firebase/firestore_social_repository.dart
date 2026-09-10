import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/result.dart';
import '../../models/comment_model.dart';
import '../../models/event_model.dart';
import '../interfaces/i_social_repository.dart';

/// [ISocialRepository]'nin Firestore implementasyonu.
///
/// Veri modeli:
///   users/{uid}
///     ├─ following/{targetUid}   — alt-koleksiyon; takip edilen her kullanıcı
///     │                            için bir doküman (RISK-FB-02 düzeltmesi)
///     ├─ followers/{sourceUid}   — alt-koleksiyon; takipçiler
///     ├─ bookmarks/{postId}      — alt-koleksiyon; kaydedilen her gönderi için
///     │                            bir doküman (RISK-FB-02 düzeltmesi)
///     ├─ savedListings/{listingId} — alt-koleksiyon; kaydedilen her ilan için
///     │                            bir doküman (bookmarks ile aynı desen,
///     │                            ayrı koleksiyon — postId/listingId aynı
///     │                            ID uzayını paylaşmıyor)
///     ├─ joinedGroups/{groupId}  — alt-koleksiyon; üye olunan her Topluluk
///     │                            grubu için bir doküman (communityGroups/
///     │                            {groupId}/members/{uid}'in aynası)
///     ├─ followingCount: int     — denormalized sayaç
///     └─ followersCount: int     — denormalized sayaç
///
///   events/{eventId}
///     ├─ participants:   [uid, ...]        — katılımcı listesi
///     └─ attendeeCount:  int              — katılımcı sayısı (denormalized)
///
///   communityGroups/{groupId}
///     ├─ members/{uid}           — alt-koleksiyon; grubun gerçek üye listesi
///     └─ memberCount: int        — denormalized sayaç (FieldValue.increment)
///
///   posts/{postId}
///     └─ comments/{commentId}    — alt-koleksiyon; her yorum kendi dokümanı
///                                  (authorId/authorName/authorPhoto/text/
///                                  timestamp) — bkz. [CommentModel]
///
/// Not: `following` ve `bookmarks` artık doküman dizisi DEĞİL alt-koleksiyondur.
/// Bu sayede 1 MB doküman sınırı aşılmaz ve koleksiyonlar sınırsız büyüyebilir.
///
/// Follow/Unfollow, Bookmark ve Event join işlemleri Firestore transaction
/// veya batch ile atomik olarak gerçekleştirilir; hiçbir zaman yarım güncelleme
/// kalmaz.
class FirestoreSocialRepository implements ISocialRepository {
  FirestoreSocialRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _kPosts = 'posts';
  static const _kUsers = 'users';
  static const _kEvents = 'events';
  static const _kCommunityGroups = 'communityGroups';

  String? get _uid => _auth.currentUser?.uid;

  // ── Pati (like) ─────────────────────────────────────────────────────────────

  /// Pati verir — patiUserIds arrayUnion + patiCount +1.
  ///
  /// Not: Temel pati akışı [FirestorePostRepository.togglePati] üzerinden
  /// çalışır (transaction). Bu metot yalnızca arayüz tamamlığı için mevcuttur.
  @override
  Future<Result<int>> patiVer(String postId) async {
    try {
      final uid = _uid;
      if (uid == null) return const Failure('Giriş yapmanız gerekiyor.');

      await _firestore.collection(_kPosts).doc(postId).set(
        {
          'patiUserIds': FieldValue.arrayUnion([uid]),
          'patiCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
      return const Success(0); // gerçek sayı stream üzerinden gelir
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Pati gönderilemedi.', exception: e);
    }
  }

  /// Pati geri alır — patiUserIds arrayRemove + patiCount -1.
  @override
  Future<Result<int>> patiGeri(String postId) async {
    try {
      final uid = _uid;
      if (uid == null) return const Failure('Giriş yapmanız gerekiyor.');

      await _firestore.collection(_kPosts).doc(postId).set(
        {
          'patiUserIds': FieldValue.arrayRemove([uid]),
          'patiCount': FieldValue.increment(-1),
        },
        SetOptions(merge: true),
      );
      return const Success(0);
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Pati geri alınamadı.', exception: e);
    }
  }

  // ── Yorum (comment) ──────────────────────────────────────────────────────────

  /// Yorumu `posts/{postId}/comments` alt koleksiyonuna ekler ve
  /// `commentsCount` sayacını artırır (batch ile atomik). [authorName]/
  /// [authorPhoto] denormalize edilir — bkz. [CommentModel].
  @override
  Future<Result<bool>> addYorum(
    String postId,
    String yorum, {
    required String authorName,
    required String authorPhoto,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return const Failure('Giriş yapmanız gerekiyor.');

      final trimmed = yorum.trim();
      if (trimmed.isEmpty) {
        return const Failure('Yorum boş olamaz.');
      }

      final batch = _firestore.batch();

      // Yorum dokümanı
      final commentRef = _firestore
          .collection(_kPosts)
          .doc(postId)
          .collection('comments')
          .doc();
      batch.set(commentRef, {
        'authorId': uid,
        'authorName': authorName,
        'authorPhoto': authorPhoto,
        'text': trimmed,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Post sayacını artır
      batch.set(
        _firestore.collection(_kPosts).doc(postId),
        {'commentsCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );

      await batch.commit();
      return const Success(true);
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Yorum eklenemedi.', exception: e);
    }
  }

  /// Bir gönderinin yorumlarını eskiden yeniye canlı dinler. Bozuk bir
  /// doküman tüm akışı çökertmez, atlanır — [FirestorePostRepository
  /// .getSocialFeed]'in kullandığı desenin aynısı.
  @override
  Stream<List<CommentModel>> watchComments(String postId) {
    return _firestore
        .collection(_kPosts)
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      final comments = <CommentModel>[];
      for (final doc in snapshot.docs) {
        try {
          comments.add(CommentModel.fromFirestore(doc));
        } catch (_) {
          // Bozuk doküman — atla, akışı çökertme.
        }
      }
      return comments;
    });
  }

  // ── Follow / Unfollow ────────────────────────────────────────────────────────

  /// Kullanıcıyı takibe alır.
  ///
  /// **Sub-collection mimarisi** — follow ilişkisi artık alan dizileri yerine
  /// ayrı Firestore dokümanları olarak saklanır:
  ///   • `users/{currentUid}/following/{targetUid}` → doküman oluşturulur
  ///   • `users/{targetUid}/followers/{currentUid}` → doküman oluşturulur
  ///
  /// **Transaction garantisi** — alt-koleksiyon yazmaları + sayaç artışları
  /// atomik olarak gerçekleşir; ya hepsi başarılı olur ya da hiçbirisi.
  ///
  ///   • `users/{currentUid}.followingCount` → +1
  ///   • `users/{targetUid}.followersCount`  → +1
  @override
  Future<Result<bool>> followUser(String targetUid) async {
    try {
      final currentUid = _uid;
      if (currentUid == null) return const Failure('Giriş yapmanız gerekiyor.');
      if (currentUid == targetUid) {
        return const Failure('Kendinizi takip edemezsiniz.');
      }

      final currentUserRef = _firestore.collection(_kUsers).doc(currentUid);
      final targetUserRef = _firestore.collection(_kUsers).doc(targetUid);
      final followingDocRef =
          currentUserRef.collection('following').doc(targetUid);
      final followerDocRef =
          targetUserRef.collection('followers').doc(currentUid);

      await _firestore.runTransaction((tx) async {
        // Sub-collection: current user → following → target
        tx.set(followingDocRef, {'followedAt': FieldValue.serverTimestamp()});
        // Sub-collection: target user → followers → current
        tx.set(followerDocRef, {'followedAt': FieldValue.serverTimestamp()});
        // Denormalized counters on parent documents
        tx.set(currentUserRef, {'followingCount': FieldValue.increment(1)},
            SetOptions(merge: true));
        tx.set(targetUserRef, {'followersCount': FieldValue.increment(1)},
            SetOptions(merge: true));
      });

      return const Success(true);
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Takip edilemedi.', exception: e);
    }
  }

  /// Takipten çıkar — [followUser]'ın tam tersi.
  ///
  /// Alt-koleksiyon dokümanları silinir ve sayaçlar düşürülür:
  ///   • `users/{currentUid}/following/{targetUid}` → silindi
  ///   • `users/{targetUid}/followers/{currentUid}` → silindi
  ///   • `users/{currentUid}.followingCount`         → -1
  ///   • `users/{targetUid}.followersCount`          → -1
  @override
  Future<Result<bool>> unfollowUser(String targetUid) async {
    try {
      final currentUid = _uid;
      if (currentUid == null) return const Failure('Giriş yapmanız gerekiyor.');

      final currentUserRef = _firestore.collection(_kUsers).doc(currentUid);
      final targetUserRef = _firestore.collection(_kUsers).doc(targetUid);
      final followingDocRef =
          currentUserRef.collection('following').doc(targetUid);
      final followerDocRef =
          targetUserRef.collection('followers').doc(currentUid);

      await _firestore.runTransaction((tx) async {
        tx.delete(followingDocRef);
        tx.delete(followerDocRef);
        tx.set(currentUserRef, {'followingCount': FieldValue.increment(-1)},
            SetOptions(merge: true));
        tx.set(targetUserRef, {'followersCount': FieldValue.increment(-1)},
            SetOptions(merge: true));
      });

      return const Success(true);
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Takip bırakılamadı.', exception: e);
    }
  }

  // ── Events ───────────────────────────────────────────────────────────────────

  /// `events` koleksiyonunu [dateTime]'a göre sıralı getirir.
  ///
  /// Koleksiyon henüz yoksa boş liste döner — uygulama çökmez.
  /// [isJoined] alanı, mevcut kullanıcının UID'sinin `participants` dizisinde
  /// olup olmadığına göre set edilir.
  @override
  Future<Result<List<EventModel>>> getEvents() async {
    try {
      final currentUid = _uid;

      final snapshot = await _firestore
          .collection(_kEvents)
          .orderBy('dateTime')
          .get();

      final events = snapshot.docs
          .map((doc) =>
              EventModel.fromFirestore(doc, currentUserUid: currentUid))
          .toList();

      return Success(events);
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Etkinlikler yüklenemedi.', exception: e);
    }
  }

  /// Etkinliğe katılır.
  ///
  /// **Transaction garantisi**: Mevcut kullanıcı `participants` dizisine
  /// eklenir ve `attendeeCount` bir artırılır. Kullanıcı zaten katılmışsa
  /// işlem idempotent olarak geçilir.
  @override
  Future<Result<int>> joinEvent(String eventId) async {
    try {
      final uid = _uid;
      if (uid == null) return const Failure('Giriş yapmanız gerekiyor.');

      final eventRef = _firestore.collection(_kEvents).doc(eventId);

      final newCount = await _firestore.runTransaction<int>((tx) async {
        final snapshot = await tx.get(eventRef);
        final data = snapshot.data() ?? {};
        final participants = List<String>.from(data['participants'] as List? ?? []);
        final currentCount = data['attendeeCount'] as int? ?? 0;

        // Idempotent: already joined → return current count unchanged
        if (participants.contains(uid)) return currentCount;

        tx.set(
          eventRef,
          {
            'participants': FieldValue.arrayUnion([uid]),
            'attendeeCount': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
        return currentCount + 1;
      });

      return Success(newCount);
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Etkinliğe katılınamadı.', exception: e);
    }
  }

  // ── Bookmark ─────────────────────────────────────────────────────────────────

  /// Kaydedildi durumunu toggle eder.
  ///
  /// **[FIX RISK-FB-02] Sub-collection mimarisi** — bookmark ilişkisi artık
  /// `users/{uid}.bookmarks[]` dizisi yerine `users/{uid}/bookmarks/{postId}`
  /// alt-koleksiyonunda saklanır. Bu sayede:
  ///   • 1 MB doküman sınırı aşılamaz.
  ///   • Kaydedilen gönderi sayısı sınırsız büyüyebilir.
  ///   • Security rules `resource.id == postId` ile tek satırda yazılabilir.
  ///
  /// **Transaction garantisi**: `bookmarks/{postId}` dokümanının varlığı
  /// atomik olarak kontrol edilir; ya set edilir ya da silinir.
  /// Yeni durum (true/false) döner.
  @override
  Future<Result<bool>> toggleBookmark(String postId) async {
    try {
      final uid = _uid;
      if (uid == null) return const Failure('Giriş yapmanız gerekiyor.');

      // Sub-collection ref — document ID is the postId itself.
      final bookmarkRef = _firestore
          .collection(_kUsers)
          .doc(uid)
          .collection('bookmarks')
          .doc(postId);

      final newState = await _firestore.runTransaction<bool>((tx) async {
        final snap = await tx.get(bookmarkRef);
        if (snap.exists) {
          tx.delete(bookmarkRef);
          return false;
        } else {
          tx.set(bookmarkRef, {'savedAt': FieldValue.serverTimestamp()});
          return true;
        }
      });

      return Success(newState);
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Kaydet işlemi başarısız.', exception: e);
    }
  }

  /// İlan kaydetme durumunu toggle eder — [toggleBookmark] ile birebir aynı
  /// desen, sadece ayrı bir alt-koleksiyonda (`savedListings`): postId ve
  /// listingId aynı ID uzayını paylaşmadığı için tek bir `bookmarks`
  /// koleksiyonunda karışmaları güvenli değil.
  @override
  Future<Result<bool>> toggleListingBookmark(String listingId) async {
    try {
      final uid = _uid;
      if (uid == null) return const Failure('Giriş yapmanız gerekiyor.');

      final savedRef = _firestore
          .collection(_kUsers)
          .doc(uid)
          .collection('savedListings')
          .doc(listingId);

      final newState = await _firestore.runTransaction<bool>((tx) async {
        final snap = await tx.get(savedRef);
        if (snap.exists) {
          tx.delete(savedRef);
          return false;
        } else {
          tx.set(savedRef, {'savedAt': FieldValue.serverTimestamp()});
          return true;
        }
      });

      return Success(newState);
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Kaydet işlemi başarısız.', exception: e);
    }
  }

  // ── Topluluk üyeliği ─────────────────────────────────────────────────────────

  /// Grup üyeliğini toggle eder — [followUser]/[unfollowUser] ile aynı
  /// eşleştirilmiş-alt-koleksiyon + transaction şekli, [toggleBookmark]'ın
  /// tek-metotlu "toggle" kolaylığıyla:
  ///   • `communityGroups/{groupId}/members/{uid}` → üyeliğin kendisi
  ///   • `users/{uid}/joinedGroups/{groupId}` → "gruplarım" için ayna
  ///   • `communityGroups/{groupId}.memberCount` → `FieldValue.increment`
  /// Üçü de tek bir transaction içinde, ya hepsi ya hiçbiri.
  @override
  Future<Result<bool>> toggleGroupMembership(String groupId) async {
    try {
      final uid = _uid;
      if (uid == null) return const Failure('Giriş yapmanız gerekiyor.');

      final memberRef = _firestore
          .collection(_kCommunityGroups)
          .doc(groupId)
          .collection('members')
          .doc(uid);
      final joinedRef = _firestore
          .collection(_kUsers)
          .doc(uid)
          .collection('joinedGroups')
          .doc(groupId);
      final groupRef = _firestore.collection(_kCommunityGroups).doc(groupId);

      final newState = await _firestore.runTransaction<bool>((tx) async {
        final snap = await tx.get(memberRef);
        if (snap.exists) {
          tx.delete(memberRef);
          tx.delete(joinedRef);
          tx.set(groupRef, {'memberCount': FieldValue.increment(-1)},
              SetOptions(merge: true));
          return false;
        } else {
          final joinedAt = {'joinedAt': FieldValue.serverTimestamp()};
          tx.set(memberRef, joinedAt);
          tx.set(joinedRef, joinedAt);
          tx.set(groupRef, {'memberCount': FieldValue.increment(1)},
              SetOptions(merge: true));
          return true;
        }
      });

      return Success(newState);
    } on FirebaseException catch (e) {
      return Failure(_mapError(e), exception: e);
    } on Exception catch (e) {
      return Failure('İşlem başarısız.', exception: e);
    }
  }

  // ── Startup state ────────────────────────────────────────────────────────────

  /// Mevcut kullanıcının takip ettiği kullanıcıların UID setini döner.
  ///
  /// Artık `users/{uid}.following[]` dizisi yerine `users/{uid}/following`
  /// alt-koleksiyonunu sorgular. Her dokümanın ID'si bir takip edilen UID'dir.
  ///
  /// [SocialViewModel] başlangıcında çağrılır; böylece uygulama
  /// yeniden açıldığında takip durumu doğru gösterilir.
  @override
  Future<Result<Set<String>>> getFollowingIds() async {
    try {
      final uid = _uid;
      if (uid == null) return const Success({});

      final snapshot = await _firestore
          .collection(_kUsers)
          .doc(uid)
          .collection('following')
          .get();

      return Success(snapshot.docs.map((d) => d.id).toSet());
    } on Exception catch (e) {
      return Failure('Takip listesi yüklenemedi.', exception: e);
    }
  }

  /// Belirtilen kullanıcının takip edilip edilmediğini gerçek zamanlı izler.
  ///
  /// `users/{me}/following/{targetUid}` dokümanının var olup olmadığını
  /// `.snapshots()` ile dinler. Başka bir cihazdan follow/unfollow yapılsa
  /// bile UI anında güncellenir.
  @override
  Stream<bool> isFollowingStream(String targetUid) {
    final uid = _uid;
    if (uid == null) return Stream.value(false);
    return _firestore
        .collection(_kUsers)
        .doc(uid)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Mevcut kullanıcının kaydettiği gönderi ID setini döner.
  ///
  /// **[FIX RISK-FB-02]** Artık `users/{uid}.bookmarks[]` dizisi yerine
  /// `users/{uid}/bookmarks` alt-koleksiyonunu sorgular. Her dokümanın ID'si
  /// bir kaydedilmiş gönderi ID'sidir.
  ///
  /// [SocialViewModel] başlangıcında çağrılır; böylece uygulama
  /// yeniden açıldığında kayıtlı gönderiler doğru gösterilir.
  @override
  Future<Result<Set<String>>> getBookmarkedPostIds() async {
    try {
      final uid = _uid;
      if (uid == null) return const Success({});

      // [FIX RISK-FB-02] Read from the bookmarks sub-collection; each
      // document ID is a postId — no array parsing required.
      final snapshot = await _firestore
          .collection(_kUsers)
          .doc(uid)
          .collection('bookmarks')
          .get();

      return Success(snapshot.docs.map((d) => d.id).toSet());
    } on Exception catch (e) {
      return Failure('Kaydedilenler yüklenemedi.', exception: e);
    }
  }

  /// Mevcut kullanıcının kaydettiği ilan ID setini döner — [getBookmarkedPostIds]
  /// ile aynı desen, `savedListings` alt-koleksiyonundan okur.
  @override
  Future<Result<Set<String>>> getBookmarkedListingIds() async {
    try {
      final uid = _uid;
      if (uid == null) return const Success({});

      final snapshot = await _firestore
          .collection(_kUsers)
          .doc(uid)
          .collection('savedListings')
          .get();

      return Success(snapshot.docs.map((d) => d.id).toSet());
    } on Exception catch (e) {
      return Failure('Kaydedilenler yüklenemedi.', exception: e);
    }
  }

  /// Mevcut kullanıcının üye olduğu grup ID setini döner —
  /// [getBookmarkedPostIds] ile aynı desen, `joinedGroups` alt-koleksiyonundan
  /// okur.
  @override
  Future<Result<Set<String>>> getJoinedGroupIds() async {
    try {
      final uid = _uid;
      if (uid == null) return const Success({});

      final snapshot = await _firestore
          .collection(_kUsers)
          .doc(uid)
          .collection('joinedGroups')
          .get();

      return Success(snapshot.docs.map((d) => d.id).toSet());
    } on Exception catch (e) {
      return Failure('Gruplarım yüklenemedi.', exception: e);
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  String _mapError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok.';
      case 'not-found':
        return 'İçerik bulunamadı.';
      case 'unavailable':
        return 'Sunucu şu an kullanılamıyor. Lütfen tekrar deneyin.';
      case 'deadline-exceeded':
        return 'İstek zaman aşımına uğradı.';
      default:
        return e.message ?? 'Beklenmedik bir hata oluştu.';
    }
  }
}
