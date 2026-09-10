import 'dart:io';

import '../../../core/result.dart';
import '../../models/post_model.dart';
import '../../models/story_model.dart';

/// ESPATI gönderi veri katmanının sözleşmesi (contract).
///
/// Uygulama katmanı (ViewModel'lar) yalnızca bu arayüzü bilir;
/// arkasında Mock mu Firebase mi çalıştığından haberdar değildir.
/// Implementasyonları değiştirmek için yalnızca [service_locator.dart]
/// dosyasındaki [kUseMock] bayrağını değiştirmek yeterlidir.
abstract class IPostRepository {
  // ─────────────────────────────────────────────────────────────────────────
  // OKUMA
  // ─────────────────────────────────────────────────────────────────────────

  /// Global keşif akışı — tüm gönderileri [timestamp]'e göre azalan sırada getirir.
  ///
  /// Cursor-tabanlı sayfalama:
  ///   • [pageToken] = null  → ilk sayfa
  ///   • [pageToken] ≠ null  → önceki sayfanın son dokümanından sonraki sayfa
  ///
  /// Firestore implementasyonu [pageToken]'i [DocumentSnapshot] olarak kullanır.
  /// Mock implementasyonu [int] offset olarak kullanır.
  ///
  /// Dönüş değeri:
  ///   • [posts]          — bu sayfadaki gönderi listesi
  ///   • [nextPageToken]  — sonraki sayfa için token; null ise son sayfa
  Future<Result<({List<PostModel> posts, Object? nextPageToken})>> getGlobalFeed({
    required int pageSize,
    Object? pageToken,
  });

  /// Eskişehir sosyal akışını gerçek zamanlı olarak yayınlar.
  ///
  /// Firestore implementasyonunda [CollectionReference.snapshots()] kullanılır;
  /// yeni bir gönderi paylaşıldığı anda tüm dinleyiciler otomatik güncellenir.
  /// Mock implementasyonunda tek seferlik bir [Stream] döner.
  Stream<List<PostModel>> getSocialFeed();

  /// Gönderi listesini tek seferlik çeker — [HomeViewModel] için kullanılır.
  ///
  /// Tercih edilen yöntem [getSocialFeed]'dir; bu metot geriye dönük
  /// uyumluluk ve pull-to-refresh senaryoları için burada tutulmaktadır.
  Future<Result<List<PostModel>>> getPosts();

  /// [uid] kullanıcısının paylaştığı gönderileri, [timestamp]'e göre azalan
  /// sırada gerçek zamanlı olarak yayınlar — Profil ekranındaki
  /// "Gönderilerim" ızgarası için kullanılır.
  Stream<List<PostModel>> watchUserPosts(String uid);

  /// Ana ekran story satırı için hikaye listesini çeker.
  Future<Result<List<StoryModel>>> getStories();

  // ─────────────────────────────────────────────────────────────────────────
  // YAZMA
  // ─────────────────────────────────────────────────────────────────────────

  /// Yeni gönderi oluşturur:
  /// 1. [imageFile]'ı Firebase Storage'a yükler
  ///    (`posts/{authorId}/{timestamp_ms}.jpg`).
  /// 2. İndirme URL'sini alır.
  /// 3. [post] dokümanını Firestore'a kaydeder.
  ///
  /// [onProgress] sağlanmışsa, Storage yükleme aşamasının ilerlemesi 0..1
  /// aralığında rapor edilir. Compression aşaması bu metoda gelmeden önce
  /// tamamlandığı için progress yalnızca ağ/Storage süresini yansıtır.
  ///
  /// Hata durumunda [Failure] ile Türkçe mesaj döner;
  /// başarı durumunda Storage download URL'si atanmış [PostModel] döner.
  Future<Result<PostModel>> createPost(
    PostModel post,
    File imageFile, {
    void Function(double progress)? onProgress,
  });

  /// Geçerli kullanıcının pati'sini (beğenisini) açar veya kapatır.
  ///
  /// Kullanıcı kimliği [FirebaseAuth.currentUser] üzerinden alınır;
  /// çağıran tarafın UID'yi iletmesine gerek yoktur.
  ///
  /// Firestore implementasyonunda:
  /// • [FieldValue.arrayUnion] — pati ekleme (idempotent)
  /// • [FieldValue.arrayRemove] — pati geri alma (idempotent)
  /// • [FieldValue.increment(±1)] — [patiCount] sayacını günceller
  /// işlemleri bir Firestore Transaction içinde atomik olarak uygulanır.
  Future<Result<void>> togglePati(String postId);
}
