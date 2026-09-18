import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/result.dart';
import '../../models/post_model.dart';
import '../../models/story_model.dart';
import '../interfaces/i_post_repository.dart';

/// [IPostRepository]'nin Firestore + Firebase Storage implementasyonu.
///
/// Tüm okuma/yazma işlemleri [Result<T>] sarmalıyla döner;
/// Firebase hataları kullanıcıya gösterilmek üzere Türkçe mesajlara çevrilir.
/// Firebase bağımlılıkları constructor injection ile alınır — bu tasarım
/// unit testlerde sahte (fake) nesnelerin enjekte edilmesine olanak tanır.
class FirestorePostRepository implements IPostRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  FirestorePostRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Firestore koleksiyon adı — merkezi sabit, her metotta tekrar yazılmaz.
  static const _kPosts = 'posts';

  /// Alt koleksiyon: `posts/{postId}/likes/{uid}`.
  /// Bir kullanıcının bir gönderiyi beğendiğini kanıtlayan tek belge buradadır.
  /// Array-tabanlı [patiUserIds] yaklaşımını değiştirir: 1 MB doc limiti aşılmaz,
  /// beğenenleri sayfalamak mümkün olur, security rule'lar daha sade yazılır.
  static const _kLikes = 'likes';

  // ─────────────────────────────────────────────────────────────────────────
  // OKUMA — Global sayfalı akış (infinite_scroll_pagination)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<Result<({List<PostModel> posts, Object? nextPageToken})>> getGlobalFeed({
    required int pageSize,
    Object? pageToken,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(_kPosts)
          .orderBy('timestamp', descending: true)
          .limit(pageSize);

      if (pageToken is DocumentSnapshot) {
        query = query.startAfterDocument(pageToken);
      }

      final snapshot = await query.get();
      final posts = <PostModel>[];

      for (final doc in snapshot.docs) {
        try {
          posts.add(PostModel.fromFirestore(doc));
        } catch (_) {
          // Bozuk dokümanı atla — stream davranışıyla tutarlı.
        }
      }

      // Sayfa doluysa son dokümanı cursor olarak döndür; boş/eksik sayfa = son sayfa.
      final Object? nextToken =
          posts.length < pageSize ? null : snapshot.docs.last;

      return Success((posts: posts, nextPageToken: nextToken));
    } on FirebaseException catch (e) {
      return Failure(
        'Akış yüklenemedi: ${_mapFirebaseError(e)}',
        exception: e,
      );
    } on Exception catch (e) {
      return Failure('Akış yüklenirken beklenmedik bir hata oluştu.',
          exception: e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OKUMA — Gerçek zamanlı akış
  // ─────────────────────────────────────────────────────────────────────────

  /// Eskişehir sosyal akışını [timestamp]'e göre azalan sırada canlı olarak yayınlar.
  ///
  /// [snapshots()] kullandığı için herhangi biri yeni bir gönderi paylaşır
  /// paylaşmaz tüm dinleyiciler otomatik olarak güncellenir.
  ///
  /// Bozuk (parse edilemeyen) bir doküman, stream'in tamamını kesmez;
  /// sadece o doküman atlanır. Bu sayede bir kullanıcının hatalı verisi
  /// diğerlerinin akışını bloke etmez.
  ///
  /// [FIX GAP-01 / RISK-FB-01] `.limit(50)` zorunludur. Limitsiz bir gerçek
  /// zamanlı dinleyici, koleksiyon büyüdükçe her snapshot olayında tüm
  /// `posts` koleksiyonunu okur ve kontrol edilemeyen bir maliyet bombası
  /// oluşturur. 50 doküman, Sosyal sekmesinin görünür alanını ve üzeri için
  /// yeterli tamponu kapsar.
  @override
  Stream<List<PostModel>> getSocialFeed() {
    return _firestore
        .collection(_kPosts)
        .orderBy('timestamp', descending: true)
        .limit(50) // [FIX RISK-FB-01] Unbounded listener cost guard.
        .snapshots()
        .map((snapshot) {
      final posts = <PostModel>[];
      for (final doc in snapshot.docs) {
        try {
          posts.add(PostModel.fromFirestore(doc));
        } catch (e) {
          // Bozuk dokümanı akışı kesmeden geç — loglama burada yapılabilir.
        }
      }
      return posts;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OKUMA — Tek seferlik Future
  // ─────────────────────────────────────────────────────────────────────────

  /// Gönderi listesini tek seferlik çeker.
  ///
  /// Pull-to-refresh ve [HomeViewModel] için kullanılır.
  /// Canlı güncellemeler için [getSocialFeed] tercih edilmelidir.
  @override
  Future<Result<List<PostModel>>> getPosts() async {
    try {
      final snapshot = await _firestore
          .collection(_kPosts)
          .orderBy('timestamp', descending: true)
          .get();

      final posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      return Success(posts);
    } on FirebaseException catch (e) {
      return Failure(
        'Gönderiler yüklenemedi: ${_mapFirebaseError(e)}',
        exception: e,
      );
    } on Exception catch (e) {
      return Failure('Gönderiler yüklenirken beklenmedik bir hata oluştu.',
          exception: e);
    }
  }

  /// Hikayeler henüz Firestore'a taşınmadı — boş liste döner.
  @override
  Future<Result<List<StoryModel>>> getStories() async {
    return const Success([]);
  }

  /// [uid] kullanıcısının gönderilerini [timestamp]'e göre azalan sırada
  /// gerçek zamanlı yayınlar — Profil ekranı "Gönderilerim" ızgarası içindir.
  ///
  /// [FIX SYNC-01] `where('authorId', ...).orderBy('timestamp', ...)`
  /// birleşimi Firestore'da bir composite index gerektirir; bu index Firebase
  /// konsolunda önceden oluşturulmamışsa sorgu `failed-precondition` hatasıyla
  /// başarısız olur ve akış sessizce boş kalır — yeni paylaşılan gönderiler
  /// hiç görünmez. Bunu önlemek için sıralama sunucu tarafında yapılmaz;
  /// yalnızca `where` filtresi (index gerektirmeyen tek-alanlı bir sorgu)
  /// Firestore'a gönderilir, azalan zaman sıralaması istemci tarafında
  /// uygulanır. Bir kullanıcının gönderi sayısı bu maliyeti göz ardı edilebilir
  /// kılacak kadar küçüktür.
  @override
  Stream<List<PostModel>> watchUserPosts(String uid) {
    return _firestore
        .collection(_kPosts)
        .where('authorId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final posts = <PostModel>[];
      for (final doc in snapshot.docs) {
        try {
          posts.add(PostModel.fromFirestore(doc));
        } catch (_) {
          // Bozuk dokümanı akışı kesmeden geç.
        }
      }
      posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return posts;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // YAZMA — Yeni gönderi oluştur
  // ─────────────────────────────────────────────────────────────────────────

  /// Yeni gönderi oluşturma akışı:
  ///
  /// **Adım 1 — Storage yüklemesi**
  /// [imageFile], `posts/{authorId}/{timestamp_ms}.jpg` yoluna yüklenir.
  /// Zaman damgası (ms) dosya adı olarak kullanılır — bu sayede aynı kullanıcı
  /// çok hızlı gönderi paylaşsa bile çakışma olmaz.
  ///
  /// **Adım 2 — Download URL**
  /// Yükleme tamamlanmadan URL alınamaz; bu yüzden [putFile] awaited edilir
  /// ve ardından [getDownloadURL] çağrılır.
  ///
  /// **Adım 3 — Firestore kaydı**
  /// [PostModel.copyWith(imageUrl: downloadUrl)] ile URL güncellenir ve
  /// `posts/{postId}` dokümanı [toFirestore()] çıktısıyla kaydedilir.
  ///
  /// [post.id] gelen değeri yok sayılır: [CreatePostViewModel] onu sadece
  /// yükleme akışı boyunca tekil bir client-side referans olarak dolduruyor
  /// (`DateTime.now().millisecondsSinceEpoch.toString()`), Firestore
  /// doküman ID'si olarak güvenli değil — iki farklı kullanıcının aynı
  /// milisaniyede paylaştığı gönderiler burada aynı doküman ID'sine
  /// çarpar ve `.doc(id).set(...)` sessizce birini diğerinin üzerine yazar.
  /// Bunun yerine burada gerçek bir Firestore auto-ID üretilip kullanılıyor
  /// — [PatiesService.uploadVideo]'nun zaten kullandığı çakışmasız desenin
  /// aynısı.
  ///
  /// Herhangi bir adımda hata alınırsa [Failure] döner.
  /// Storage yüklemesi başarılı ancak Firestore kaydı başarısız olursa
  /// yetim bir Storage dosyası kalabilir — bu durum bir Cloud Function ile
  /// temizlenmelidir (teknik borç olarak kaydedildi).
  @override
  Future<Result<PostModel>> createPost(
    PostModel post,
    File? imageFile, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final docRef = _firestore.collection(_kPosts).doc();

      // Metin-only tartışma gönderisi (fotoğraf seçilmemiş) — Storage
      // adımı tamamen atlanır, imageUrl boş string kalır.
      var downloadUrl = '';

      if (imageFile != null) {
        // Adım 1 — Görseli Storage'a yükle (progress'i stream üzerinden rapor et)
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef =
            _storage.ref().child('posts/${post.authorId}/$fileName');

        final uploadTask = storageRef.putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // [UploadTask.snapshotEvents] bytesTransferred/totalBytes'ı akış
        // olarak yayınlar; biz 0..1 aralığına normalize edip callback'e
        // iletiyoruz. totalBytes == 0 olan ilk tick'lerde NaN üretmemek için
        // guard ekliyoruz.
        final progressSub = onProgress == null
            ? null
            : uploadTask.snapshotEvents.listen((snap) {
                final total = snap.totalBytes;
                if (total <= 0) return;
                final ratio = snap.bytesTransferred / total;
                onProgress(ratio.clamp(0.0, 1.0));
              });

        try {
          await uploadTask;
        } finally {
          await progressSub?.cancel();
        }

        // Adım 2 — İndirme URL'sini al
        downloadUrl = await storageRef.getDownloadURL();
      }

      // Adım 3 — URL'yi ve gerçek doküman ID'sini post'a ekle, Firestore'a kaydet
      final postWithImage =
          post.copyWith(id: docRef.id, imageUrl: downloadUrl);
      await docRef.set(postWithImage.toFirestore());

      return Success(postWithImage);
    } on FirebaseException catch (e) {
      return Failure(
        'Gönderi oluşturulamadı: ${_mapFirebaseError(e)}',
        exception: e,
      );
    } on Exception catch (e) {
      return Failure('Gönderi oluşturulurken beklenmedik bir hata oluştu.',
          exception: e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // YAZMA — Pati (beğeni) aç/kapat
  // ─────────────────────────────────────────────────────────────────────────

  /// Geçerli kullanıcının pati'sini toggle eder.
  ///
  /// **Kullanıcı doğrulama**
  /// Oturum açık değilse işlem yapılmadan [Failure] döner.
  ///
  /// **Veri modeli — Sub-collection tabanlı**
  /// Beğeniler, post dokümanındaki `patiUserIds` array'i yerine
  /// `posts/{postId}/likes/{uid}` alt koleksiyonunda saklanır:
  /// • 1 MB doküman limiti aşılmaz — binlerce beğeni güvenli büyür.
  /// • Beğenenleri sayfalı listelemek mümkün olur.
  /// • Security rule'larda `resource.id == request.auth.uid` ile
  ///   "kullanıcı yalnızca kendi beğenisini yazabilir" kuralı tek satırda yazılır.
  ///
  /// **Atomik Transaction**
  /// `likes/{uid}` belgesi ve post dokümanındaki [patiCount] sayacı tek bir
  /// Firestore transaction içinde birlikte güncellenir:
  /// 1. `tx.get(likeRef)` — kullanıcı daha önce pati verdi mi?
  /// 2. Varsa  → `tx.delete(likeRef)` + `patiCount -1`
  ///    Yoksa → `tx.set(likeRef, {...})` + `patiCount +1`
  ///
  /// Bu sayede ağ kesintisinde yarım kalan güncelleme olmaz; eş zamanlı iki
  /// isteğin aynı sayacı bozması imkânsızdır.
  @override
  Future<Result<void>> togglePati(String postId) async {
    // Oturum kontrolü — repository'nin kendi sorumluluğu.
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Failure(
        'Pati vermek için giriş yapmanız gerekiyor.',
      );
    }
    final userId = currentUser.uid;
    final postRef = _firestore.collection(_kPosts).doc(postId);
    final likeRef = postRef.collection(_kLikes).doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final likeSnap = await transaction.get(likeRef);

        if (likeSnap.exists) {
          // Pati geri alma — alt koleksiyondan sil + sayacı azalt.
          transaction.delete(likeRef);
          transaction.update(postRef, {
            'patiCount': FieldValue.increment(-1),
          });
        } else {
          // Pati verme — alt koleksiyona yaz + sayacı artır.
          // `createdAt` rozet/sıralama için; `userId` security rule'lar için.
          transaction.set(likeRef, {
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(postRef, {
            'patiCount': FieldValue.increment(1),
          });
        }
      });

      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(
        'Pati işlemi başarısız: ${_mapFirebaseError(e)}',
        exception: e,
      );
    } on Exception catch (e) {
      return Failure(
        'Pati işlemi sırasında beklenmedik bir hata oluştu.',
        exception: e,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE — Firebase hata kodu → Türkçe mesaj
  // ─────────────────────────────────────────────────────────────────────────

  /// [FirebaseException.code] değerini kullanıcıya gösterilecek
  /// Türkçe bir mesaja dönüştürür.
  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok.';
      case 'not-found':
        return 'İstenen içerik bulunamadı.';
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
        return e.message ?? 'Bilinmeyen bir hata oluştu.';
    }
  }
}
