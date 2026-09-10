import 'dart:io';

import '../../../core/result.dart';
import '../../models/post_model.dart';
import '../../models/story_model.dart';
import '../../sample_data.dart';
import '../interfaces/i_post_repository.dart';

/// [IPostRepository]'nin offline mock implementasyonu.
///
/// [SampleData]'yı kullanır ve gerçekçi ağ gecikmesini simüle etmek için
/// [Future.delayed] uygular. Uçuş modunda veya Firebase yapılandırması
/// henüz tamamlanmamışken geliştirme sürecini bloke etmez.
class MockPostRepository implements IPostRepository {
  static const _delay = Duration(milliseconds: 800);

  // ─────────────────────────────────────────────────────────────────────────
  // OKUMA — Global sayfalı akış (mock)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<Result<({List<PostModel> posts, Object? nextPageToken})>>
      getGlobalFeed({
    required int pageSize,
    Object? pageToken,
  }) async {
    try {
      await Future.delayed(_delay);

      // Mock'ta pageToken bir int offset'tir (null ise 0).
      final offset = (pageToken as int?) ?? 0;

      // getPosts() tüm sample veriyi döndürür — yeniden kullan.
      final allResult = await getPosts();
      if (allResult case Failure(:final message)) {
        return Failure(message);
      }
      final all = (allResult as Success<List<PostModel>>).data;

      final page = all.skip(offset).take(pageSize).toList();
      final nextOffset = offset + page.length;
      final Object? nextToken =
          page.length < pageSize ? null : nextOffset;

      return Success((posts: page, nextPageToken: nextToken));
    } on Exception catch (e) {
      return Failure('Akış yüklenemedi.', exception: e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OKUMA
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<PostModel>>> getPosts() async {
    try {
      await Future.delayed(_delay);

      final posts = SampleData.posts.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;

        // SampleData anahtarları: 'id', 'username', 'avatar', 'image',
        // 'caption', 'pati', 'yorum' — PostModel yeni alan adlarıyla eşleştirilir.
        return PostModel(
          id: p['id'] as String? ?? 'post_$i',
          authorId: 'mock_user_$i',
          authorName: p['username'] as String? ?? '',
          authorImage: p['avatar'] as String? ?? '',
          imageUrl: p['image'] as String? ?? '',
          description: p['caption'] as String? ?? '',
          location: _eskisehirDistricts[i % _eskisehirDistricts.length],
          timestamp: DateTime.now().subtract(Duration(hours: (i + 1) * 2)),
          petName: p['petName'] as String? ?? '',
          patiCount: p['pati'] as int? ?? 0,
          commentsCount: p['yorum'] as int? ?? 0,
        );
      }).toList();

      return Success(posts);
    } on Exception catch (e) {
      return Failure('Gönderiler yüklenemedi.', exception: e);
    }
  }

  @override
  Future<Result<List<StoryModel>>> getStories() async {
    try {
      await Future.delayed(_delay);

      final stories = SampleData.stories.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return StoryModel(
          id: 'story_$i',
          userId: 'mock_user_$i',
          imageUrl: s['avatar'] ?? '',
          isViewed: false,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );
      }).toList();

      return Success(stories);
    } on Exception catch (e) {
      return Failure('Hikayeler yüklenemedi.', exception: e);
    }
  }

  /// Mock gerçek zamanlı akış — [getPosts] sonucunu tek seferlik bir [Stream] olarak sarar.
  @override
  Stream<List<PostModel>> getSocialFeed() async* {
    final result = await getPosts();
    switch (result) {
      case Success(:final data):
        yield data;
      case Failure():
        yield const [];
    }
  }

  /// Mock "Gönderilerim" akışı — [MockPetRepository.watchUserPets] ile aynı
  /// esnek yaklaşımla [uid] filtrelemesi yapmadan tüm örnek gönderileri döner,
  /// böylece hangi mock hesapla giriş yapılırsa yapılsın grid boş kalmaz.
  @override
  Stream<List<PostModel>> watchUserPosts(String uid) async* {
    final result = await getPosts();
    switch (result) {
      case Success(:final data):
        yield data;
      case Failure():
        yield const [];
    }
  }

  /// Mock gönderi oluşturma — Storage çağrısı yok, ancak UX testinde ViewModel'in
  /// progress-driven UI'ını görebilmek için ilerlemeyi birkaç adımda simüle eder.
  @override
  Future<Result<PostModel>> createPost(
    PostModel post,
    File imageFile, {
    void Function(double progress)? onProgress,
  }) async {
    if (onProgress != null) {
      for (final p in const [0.15, 0.4, 0.7, 0.95, 1.0]) {
        await Future.delayed(const Duration(milliseconds: 160));
        onProgress(p);
      }
    } else {
      await Future.delayed(_delay);
    }
    return Success(post);
  }

  /// Mock pati toggle — gerçek veri değiştirmeden başarı döner.
  @override
  Future<Result<void>> togglePati(String postId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const Success(null);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOCK DATA
  // ─────────────────────────────────────────────────────────────────────────

  /// Mock gönderilere gerçekçi Eskişehir lokasyonu atar.
  static const _eskisehirDistricts = [
    'Odunpazarı',
    'Tepebaşı',
    'Sazova Parkı',
    'Porsuk Bulvarı',
    'Kent Parkı',
    'Atlasjet Caddesi',
    'Çarşı',
    'Vişnelik',
  ];
}
