import '../../../core/result.dart';
import '../../models/listing_model.dart';
import '../../models/chat_group_model.dart';
import '../../models/direct_message_model.dart';
import '../interfaces/i_form_repository.dart';

/// Mock implementation of [IFormRepository].
///
/// Returns realistic Turkish-language data seeded with Eskişehir
/// neighbourhoods and local pet-culture references.
/// Simulates ~600ms network latency.
class MockFormRepository implements IFormRepository {
  static const _delay = Duration(milliseconds: 600);

  // ── Listings ──────────────────────────────────────────────────────────────

  @override
  Future<Result<List<ListingModel>>> getListings() async {
    try {
      await Future.delayed(_delay);
      return Success(_listings);
    } on Exception catch (e) {
      return Failure('İlanlar yüklenemedi.', exception: e);
    }
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

  // ── Direct Messages ───────────────────────────────────────────────────────

  @override
  Future<Result<List<DirectMessageModel>>> getDirectMessages() async {
    try {
      await Future.delayed(_delay);
      return Success(_dms);
    } on Exception catch (e) {
      return Failure('Mesajlar yüklenemedi.', exception: e);
    }
  }

  // ── Create Listing ────────────────────────────────────────────────────────

  @override
  Future<Result<void>> createListing(ListingModel listing) async {
    try {
      // Simulates a real network write with 1.5s latency.
      await Future.delayed(const Duration(milliseconds: 1500));
      return const Success(null);
    } on Exception catch (e) {
      return Failure('İlan kaydedilemedi. Lütfen tekrar deneyin.', exception: e);
    }
  }
}

// ── Seed Data ─────────────────────────────────────────────────────────────────

final List<ListingModel> _listings = [
  // ── Kayıp ──
  ListingModel(
    id: 'lst_001',
    name: 'Rocky',
    type: 'Golden Retriever',
    status: ListingStatus.kayip,
    location: 'Odunpazarı, Eskişehir',
    date: '15 Mar 2026',
    imageUrl: 'https://placekitten.com/400/400',
    contact: '0532 555 01 01',
    description: '3 yaşında erkek, kırmızı tasmalı. Odunpazarı Tarihi Çarşı çevresinde son görüldü.',
    createdAt: DateTime(2026, 3, 15),
  ),
  ListingModel(
    id: 'lst_002',
    name: 'Mimi',
    type: 'Tekir Kedi',
    status: ListingStatus.kayip,
    location: 'Tepebaşı, Eskişehir',
    date: '14 Mar 2026',
    imageUrl: 'https://placekitten.com/401/401',
    contact: '0533 555 02 02',
    description: 'Küçük dişi kedi, gri çizgili. Tepebaşı Belediyesi yakınında son görüldü. Çok ürkek.',
    createdAt: DateTime(2026, 3, 14),
  ),
  ListingModel(
    id: 'lst_003',
    name: 'Karamel',
    type: 'Fransız Bulldog',
    status: ListingStatus.kayip,
    location: 'Eskişehir Merkez',
    date: '13 Mar 2026',
    imageUrl: 'https://placekitten.com/402/402',
    contact: '0534 555 03 03',
    description: '2 yaşında erkek, kahverengi-bej renkli. Mavi tasmalı, Gar Meydanı çevresinde kayboldu.',
    createdAt: DateTime(2026, 3, 13),
  ),
  ListingModel(
    id: 'lst_004',
    name: 'Snowball',
    type: 'Ankara Kedisi',
    status: ListingStatus.kayip,
    location: 'Bağlar, Eskişehir',
    date: '12 Mar 2026',
    imageUrl: 'https://placekitten.com/403/403',
    contact: '0535 555 04 04',
    description: 'Uzun tüylü, mavi gözlü beyaz kedi. Bağlar Parkı yakınında son görüldü.',
    createdAt: DateTime(2026, 3, 12),
  ),
  // ── Sahiplendirme ──
  ListingModel(
    id: 'lst_005',
    name: 'Pamuk',
    type: 'Beyaz Kedi',
    status: ListingStatus.sahiplendirme,
    location: 'Tepebaşı, Eskişehir',
    date: '10 Mar 2026',
    imageUrl: 'https://placekitten.com/404/404',
    contact: '0536 555 05 05',
    description: '1,5 yaşında dişi, tüm aşıları tam. Çok uysal ve sevecen, çocuk evlerine uygun.',
    createdAt: DateTime(2026, 3, 10),
  ),
  ListingModel(
    id: 'lst_006',
    name: 'Zeytin',
    type: 'Labrador Mix',
    status: ListingStatus.sahiplendirme,
    location: 'Odunpazarı, Eskişehir',
    date: '9 Mar 2026',
    imageUrl: 'https://placekitten.com/405/405',
    contact: '0537 555 06 06',
    description: '4 aylık yavru, ilk aşıları yapıldı. Enerjik, Sazova Parkı gibi geniş alanı olan evlere uygun.',
    createdAt: DateTime(2026, 3, 9),
  ),
  ListingModel(
    id: 'lst_007',
    name: 'Fındık',
    type: 'Sarman Kedi',
    status: ListingStatus.sahiplendirme,
    location: 'Porsuk, Eskişehir',
    date: '8 Mar 2026',
    imageUrl: 'https://placekitten.com/406/406',
    contact: '0538 555 07 07',
    description: '2 yaşında erkek, kısırlaştırıldı. Porsuk kıyısındaki veterinerden sağlık raporu mevcut.',
    createdAt: DateTime(2026, 3, 8),
  ),
  ListingModel(
    id: 'lst_008',
    name: 'Boncuk',
    type: 'Hollandalı Tavşan',
    status: ListingStatus.sahiplendirme,
    location: '71 Evler, Eskişehir',
    date: '7 Mar 2026',
    imageUrl: 'https://placekitten.com/407/407',
    contact: '0539 555 08 08',
    description: '1 yaşında dişi. Kafes, suluk ve mama kabı dahil. Sahibi yurt dışına çıkacağı için sahiplendiriliyor.',
    createdAt: DateTime(2026, 3, 7),
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
    lastMessage: 'Odunpazarı\'nda iyi kedi veterineri bilen var mı?',
    lastActivityLabel: '3 dk',
    unreadCount: 5,
    isPinned: true,
  ),
  ChatGroupModel(
    id: 'grp_002',
    name: 'Köpek Dünyası',
    description: 'Sazova Parkı buluşmaları ve köpek eğitimi',
    petCategory: PetCategory.dog,
    memberCount: 2341,
    lastMessage: 'Bu cumartesi Sazova\'da buluşuyoruz, kim gelecek?',
    lastActivityLabel: '12 dk',
    unreadCount: 3,
    isPinned: true,
  ),
  ChatGroupModel(
    id: 'grp_003',
    name: 'Kuş Severler',
    description: 'Papağan, muhabbet kuşu ve daha fazlası',
    petCategory: PetCategory.bird,
    memberCount: 456,
    lastMessage: 'Muhabbet kuşumun tüyleri dökülüyor, öneri?',
    lastActivityLabel: '1 sa',
    unreadCount: 0,
  ),
  ChatGroupModel(
    id: 'grp_004',
    name: 'Küçük Dostlar',
    description: 'Tavşan, hamster ve kemirgen sahipleri',
    petCategory: PetCategory.rabbit,
    memberCount: 234,
    lastMessage: 'Yavru tavşan ilk haftasında ne yemeli?',
    lastActivityLabel: '2 sa',
    unreadCount: 1,
  ),
  ChatGroupModel(
    id: 'grp_005',
    name: 'Balık & Sürüngenler',
    description: 'Akvaryum kurulumu ve egzotik hayvan bakımı',
    petCategory: PetCategory.fish,
    memberCount: 89,
    lastMessage: 'Eskişehir\'de akvaryum malzemesi nerede bulunur?',
    lastActivityLabel: '5 sa',
    unreadCount: 0,
  ),
  ChatGroupModel(
    id: 'grp_006',
    name: 'ESPATI Genel',
    description: 'Duyurular, etkinlikler ve genel sohbet',
    petCategory: PetCategory.all,
    memberCount: 4891,
    lastMessage: 'Uygulamaya yeni özellikler eklendi! Kontrol edin.',
    lastActivityLabel: '1 g',
    unreadCount: 0,
  ),
];

// ── Direct Messages ───────────────────────────────────────────────────────────

final List<DirectMessageModel> _dms = [
  DirectMessageModel(
    id: 'dm_001',
    displayName: 'Dr. Ayşe Kaya',
    avatarUrl: 'https://placekitten.com/70/70',
    lastMessage: 'Kontrol randevunuz yarın saat 10:00\'da, lütfen erken gelin.',
    timeLabel: '2 dk',
    isOnline: true,
    unreadCount: 1,
    isVerified: true,
  ),
  DirectMessageModel(
    id: 'dm_002',
    displayName: 'Odunpazarı Pet Shop',
    avatarUrl: 'https://placekitten.com/71/71',
    lastMessage: 'Siparişiniz hazır, uygun bir zamanda gelip alabilirsiniz.',
    timeLabel: '15 dk',
    isOnline: true,
    unreadCount: 2,
    isVerified: true,
  ),
  DirectMessageModel(
    id: 'dm_003',
    displayName: 'Zeynep H.',
    avatarUrl: 'https://placekitten.com/72/72',
    lastMessage: 'Rocky\'yi bugün Sazova Parkı girişinde gördüm! Koşuyordu.',
    timeLabel: '1 sa',
    isOnline: false,
    unreadCount: 1,
  ),
  DirectMessageModel(
    id: 'dm_004',
    displayName: 'Kemal Arslan',
    avatarUrl: 'https://placekitten.com/73/73',
    lastMessage: 'O tavşanı hâlâ sahiplendirdiniz mi, sormak istedim.',
    timeLabel: '3 sa',
    isOnline: false,
    unreadCount: 0,
  ),
  DirectMessageModel(
    id: 'dm_005',
    displayName: 'Merve Çelik',
    avatarUrl: 'https://placekitten.com/74/74',
    lastMessage: 'Mama tavsiyesi için teşekkürler, çok işe yaradı 🐾',
    timeLabel: 'Dün',
    isOnline: false,
    unreadCount: 0,
  ),
  DirectMessageModel(
    id: 'dm_006',
    displayName: 'ESPATI Destek',
    avatarUrl: 'https://placekitten.com/75/75',
    lastMessage: 'Hoş geldiniz! Herhangi bir sorunuz olursa buradayız.',
    timeLabel: '1 g',
    isOnline: true,
    unreadCount: 0,
    isVerified: true,
  ),
];
