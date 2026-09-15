import 'dart:async';
import 'dart:io';

import '../../../core/result.dart';
import '../../models/listing_model.dart';
import '../../models/chat_group_model.dart';
import '../interfaces/i_form_repository.dart';

/// Mock implementation of [IFormRepository].
///
/// Returns realistic Turkish-language data seeded with Eskişehir
/// neighbourhoods and local pet-culture references.
/// Simulates ~600ms network latency.
class MockFormRepository implements IFormRepository {
  static const _delay = Duration(milliseconds: 600);

  // Mutable working copy so createListing() can prepend to it and the
  // broadcast stream can replay the current state to each new subscriber.
  final List<ListingModel> _listingsState = List.of(_listings);
  final _listingsController =
      StreamController<List<ListingModel>>.broadcast();

  // ── Listings ──────────────────────────────────────────────────────────────

  @override
  Stream<List<ListingModel>> watchListings() async* {
    // Replay current state immediately to a new subscriber, then forward
    // every subsequent update — mirrors a Firestore snapshots() listener's
    // "immediate current value, then live updates" behaviour.
    yield List.unmodifiable(_listingsState);
    yield* _listingsController.stream;
  }

  // ── Groups ────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<ChatGroupModel>>> getChatGroups() async {
    try {
      await Future.delayed(_delay);
      return Success(_groups);
    } on Exception catch (e) {
      return Failure('Gruplar yüklenemedi.', exception: e);
    }
  }

  @override
  Future<Result<ChatGroupModel>> createGroup({
    required String name,
    required String description,
    required PetCategory petCategory,
    String? customCategory,
    required String creatorName,
    required String creatorPhoto,
    File? coverImage,
    List<String> bannedWords = const [],
  }) async {
    try {
      await Future.delayed(_delay);
      // No Storage in mock mode — the picked file's local path can't
      // become a real download URL, so it's simply not persisted here.
      // The real (Firebase) path does the actual upload.
      final created = ChatGroupModel(
        id: 'grp_mock_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        description: description.trim(),
        petCategory: petCategory,
        memberCount: 1,
        creatorId: 'current_user',
        customCategory: customCategory?.trim(),
        bannedWords: bannedWords
            .map((w) => w.trim())
            .where((w) => w.isNotEmpty)
            .toList(),
      );
      _groups.insert(0, created);
      return Success(created);
    } on Exception catch (e) {
      return Failure('Grup oluşturulamadı. Lütfen tekrar deneyin.', exception: e);
    }
  }

  @override
  Future<Result<void>> deleteGroup(String groupId) async {
    try {
      await Future.delayed(_delay);
      _groups.removeWhere((g) => g.id == groupId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure('Grup silinemedi. Lütfen tekrar deneyin.', exception: e);
    }
  }

  // ── Create Listing ────────────────────────────────────────────────────────

  @override
  Future<Result<ListingModel>> createListing(
    ListingModel listing,
    List<File> images,
  ) async {
    try {
      // Simulates a real network + upload latency.
      await Future.delayed(const Duration(milliseconds: 1500));

      final created = listing.copyWith(
        id: 'lst_mock_${DateTime.now().millisecondsSinceEpoch}',
        imageUrls: images.isEmpty
            ? const ['https://placekitten.com/400/400']
            : List.generate(images.length, (_) => 'https://placekitten.com/400/400'),
      );
      _listingsState.insert(0, created);
      _listingsController.add(List.unmodifiable(_listingsState));

      return Success(created);
    } on Exception catch (e) {
      return Failure('İlan kaydedilemedi. Lütfen tekrar deneyin.', exception: e);
    }
  }

  // ── Discovery / search ───────────────────────────────────────────────────

  @override
  Future<Result<List<ListingModel>>> searchListings({
    String? species,
    String? district,
    ListingStatus? status,
    String? keyword,
  }) async {
    try {
      await Future.delayed(_delay);

      final normalizedKeyword = keyword?.trim().toLowerCase();
      final results = _listingsState.where((listing) {
        if (species != null && species.isNotEmpty && listing.species != species) {
          return false;
        }
        if (district != null && district.isNotEmpty && listing.location != district) {
          return false;
        }
        if (status != null && listing.status != status) return false;
        if (normalizedKeyword != null && normalizedKeyword.isNotEmpty) {
          final haystack = '${listing.name} ${listing.species} ${listing.type} '
                  '${listing.description} ${listing.location}'
              .toLowerCase();
          if (!haystack.contains(normalizedKeyword)) return false;
        }
        return true;
      }).toList();

      return Success(results);
    } on Exception catch (e) {
      return Failure('Arama başarısız oldu.', exception: e);
    }
  }

  // ── Delete listing ───────────────────────────────────────────────────────

  @override
  Future<Result<void>> deleteListing(String listingId) async {
    try {
      await Future.delayed(_delay);
      _listingsState.removeWhere((l) => l.id == listingId);
      _listingsController.add(List.unmodifiable(_listingsState));
      return const Success(null);
    } on Exception catch (e) {
      return Failure('İlan silinemedi. Lütfen tekrar deneyin.', exception: e);
    }
  }

  /// Call when the repository is no longer needed to release the [StreamController].
  void dispose() {
    _listingsController.close();
  }
}

// ── Seed Data ─────────────────────────────────────────────────────────────────

final List<ListingModel> _listings = [
  // ── Kayıp ──
  ListingModel(
    id: 'lst_001',
    name: 'Rocky',
    type: 'Golden Retriever',
    species: 'Köpek',
    status: ListingStatus.kayip,
    location: 'Odunpazarı, Eskişehir',
    date: '15 Mar 2026',
    imageUrls: ['https://placekitten.com/400/400'],
    description: '3 yaşında erkek, kırmızı tasmalı. Odunpazarı Tarihi Çarşı çevresinde son görüldü.',
    createdAt: DateTime(2026, 3, 15),
    latitude: 39.7784,
    longitude: 30.5195,
  ),
  ListingModel(
    id: 'lst_002',
    name: 'Mimi',
    type: 'Tekir Kedi',
    species: 'Kedi',
    status: ListingStatus.kayip,
    location: 'Tepebaşı, Eskişehir',
    date: '14 Mar 2026',
    imageUrls: ['https://placekitten.com/401/401'],
    description: 'Küçük dişi kedi, gri çizgili. Tepebaşı Belediyesi yakınında son görüldü. Çok ürkek.',
    createdAt: DateTime(2026, 3, 14),
    latitude: 39.7891,
    longitude: 30.4886,
  ),
  ListingModel(
    id: 'lst_003',
    name: 'Karamel',
    type: 'Fransız Bulldog',
    species: 'Köpek',
    status: ListingStatus.kayip,
    location: 'Eskişehir Merkez',
    date: '13 Mar 2026',
    imageUrls: ['https://placekitten.com/402/402'],
    description: '2 yaşında erkek, kahverengi-bej renkli. Mavi tasmalı, Gar Meydanı çevresinde kayboldu.',
    createdAt: DateTime(2026, 3, 13),
    latitude: 39.7740,
    longitude: 30.5245,
  ),
  ListingModel(
    id: 'lst_004',
    name: 'Snowball',
    type: 'Ankara Kedisi',
    species: 'Kedi',
    status: ListingStatus.kayip,
    location: 'Bağlar, Eskişehir',
    date: '12 Mar 2026',
    imageUrls: ['https://placekitten.com/403/403'],
    description: 'Uzun tüylü, mavi gözlü beyaz kedi. Bağlar Parkı yakınında son görüldü.',
    createdAt: DateTime(2026, 3, 12),
    latitude: 39.7636,
    longitude: 30.5374,
  ),
  // ── Sahiplendirme ──
  ListingModel(
    id: 'lst_005',
    name: 'Pamuk',
    type: 'Beyaz Kedi',
    species: 'Kedi',
    status: ListingStatus.sahiplendirme,
    location: 'Tepebaşı, Eskişehir',
    date: '10 Mar 2026',
    imageUrls: ['https://placekitten.com/404/404'],
    description: '1,5 yaşında dişi, tüm aşıları tam. Çok uysal ve sevecen, çocuk evlerine uygun.',
    createdAt: DateTime(2026, 3, 10),
    latitude: 39.7918,
    longitude: 30.4841,
  ),
  ListingModel(
    id: 'lst_006',
    name: 'Zeytin',
    type: 'Labrador Mix',
    species: 'Köpek',
    status: ListingStatus.sahiplendirme,
    location: 'Odunpazarı, Eskişehir',
    date: '9 Mar 2026',
    imageUrls: ['https://placekitten.com/405/405'],
    description: '4 aylık yavru, ilk aşıları yapıldı. Enerjik, Sazova Parkı gibi geniş alanı olan evlere uygun.',
    createdAt: DateTime(2026, 3, 9),
    latitude: 39.7749,
    longitude: 30.5163,
  ),
  ListingModel(
    id: 'lst_007',
    name: 'Fındık',
    type: 'Sarman Kedi',
    species: 'Kedi',
    status: ListingStatus.sahiplendirme,
    location: 'Porsuk, Eskişehir',
    date: '8 Mar 2026',
    imageUrls: ['https://placekitten.com/406/406'],
    description: '2 yaşında erkek, kısırlaştırıldı. Porsuk kıyısındaki veterinerden sağlık raporu mevcut.',
    createdAt: DateTime(2026, 3, 8),
    latitude: 39.7748,
    longitude: 30.5119,
  ),
  ListingModel(
    id: 'lst_008',
    name: 'Boncuk',
    type: 'Hollandalı Tavşan',
    species: 'Tavşan',
    status: ListingStatus.sahiplendirme,
    location: '71 Evler, Eskişehir',
    date: '7 Mar 2026',
    imageUrls: ['https://placekitten.com/407/407'],
    description: '1 yaşında dişi. Kafes, suluk ve mama kabı dahil. Sahibi yurt dışına çıkacağı için sahiplendiriliyor.',
    createdAt: DateTime(2026, 3, 7),
    latitude: 39.7583,
    longitude: 30.4746,
  ),
];

// ── Community Groups ──────────────────────────────────────────────────────────

final List<ChatGroupModel> _groups = [
  ChatGroupModel(
    id: 'grp_001',
    name: 'Kedi Sahipleri',
    description: 'Eskişehir kedi severler buluşma noktası',
    petCategory: PetCategory.cat,
    memberCount: 1247,
    isPinned: true,
  ),
  ChatGroupModel(
    id: 'grp_002',
    name: 'Köpek Dünyası',
    description: 'Sazova Parkı buluşmaları ve köpek eğitimi',
    petCategory: PetCategory.dog,
    memberCount: 2341,
    isPinned: true,
  ),
  ChatGroupModel(
    id: 'grp_003',
    name: 'Kuş Severler',
    description: 'Papağan, muhabbet kuşu ve daha fazlası',
    petCategory: PetCategory.bird,
    memberCount: 456,
  ),
  ChatGroupModel(
    id: 'grp_004',
    name: 'Küçük Dostlar',
    description: 'Tavşan, hamster ve kemirgen sahipleri',
    petCategory: PetCategory.rabbit,
    memberCount: 234,
  ),
  ChatGroupModel(
    id: 'grp_005',
    name: 'Balık & Sürüngenler',
    description: 'Akvaryum kurulumu ve egzotik hayvan bakımı',
    petCategory: PetCategory.fish,
    memberCount: 89,
  ),
  ChatGroupModel(
    id: 'grp_006',
    name: 'ESPATI Genel',
    description: 'Duyurular, etkinlikler ve genel sohbet',
    petCategory: PetCategory.all,
    memberCount: 4891,
  ),
];
