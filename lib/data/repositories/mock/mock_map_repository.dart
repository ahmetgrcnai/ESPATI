import '../../../core/result.dart';
import '../../models/map_point.dart';
import '../interfaces/i_map_repository.dart';

/// Mock implementation of [IMapRepository].
///
/// Returns real-world Eskişehir coordinates with simulated network latency.
class MockMapRepository implements IMapRepository {
  static const _delay = Duration(milliseconds: 800);

  /// Seed data with real Eskişehir coordinates.
  static const List<MapPoint> _eskisehirPoints = [
    // ── Parks ──
    MapPoint(
      id: 'park_1',
      name: 'Sazova Bilim Kültür ve Sanat Parkı',
      latitude: 39.7497,
      longitude: 30.4806,
      category: MapPointCategory.park,
      rating: 4.9,
      address: 'Sazova, Tepebaşı, Eskişehir',
      description:
          'Eskişehir\'in en büyük parkı. Hayvanat bahçesi, lunapark ve gölet alanları.',
    ),
    MapPoint(
      id: 'park_2',
      name: 'Kanlıkavak Parkı',
      latitude: 39.7673,
      longitude: 30.5245,
      category: MapPointCategory.park,
      rating: 4.7,
      address: 'Kanlıkavak, Odunpazarı, Eskişehir',
      description:
          'Geniş yeşil alanlar ve yürüyüş parkurları ile evcil hayvan dostu park.',
    ),
    MapPoint(
      id: 'park_3',
      name: 'Adalar Bölgesi',
      latitude: 39.7713,
      longitude: 30.5107,
      category: MapPointCategory.park,
      rating: 4.8,
      address: 'Adalar, Odunpazarı, Eskişehir',
      description:
          'Porsuk Çayı üzerindeki adalar. Gondol turu ve pati-dostu yürüyüş alanları.',
    ),
    MapPoint(
      id: 'park_4',
      name: 'Kent Park',
      latitude: 39.7631,
      longitude: 30.4981,
      category: MapPointCategory.park,
      rating: 4.6,
      address: 'Batıkent, Tepebaşı, Eskişehir',
      description: 'Modern ve bakımlı park. Köpek gezdirme alanları mevcut.',
    ),

    // ── Veterinary Clinics ──
    MapPoint(
      id: 'vet_1',
      name: 'Eskişehir Hayvan Hastanesi',
      latitude: 39.7752,
      longitude: 30.5163,
      category: MapPointCategory.vet,
      rating: 4.8,
      address: 'Hoşnudiye Mah., Tepebaşı, Eskişehir',
      description: '7/24 acil veteriner hizmeti. Cerrahi ve dahili bölümler.',
    ),
    MapPoint(
      id: 'vet_2',
      name: 'Patiler Veteriner Kliniği',
      latitude: 39.7689,
      longitude: 30.5289,
      category: MapPointCategory.vet,
      rating: 4.7,
      address: 'Odunpazarı Mah., Odunpazarı, Eskişehir',
      description: 'Aşılama, mikroçip ve genel sağlık kontrolleri.',
    ),
    MapPoint(
      id: 'vet_3',
      name: 'Dostlar Veteriner',
      latitude: 39.7598,
      longitude: 30.4921,
      category: MapPointCategory.vet,
      rating: 4.5,
      address: 'Batıkent, Tepebaşı, Eskişehir',
      description: 'Pet kuaför ve veteriner hizmetleri bir arada.',
    ),

    // ── Pet-Friendly Cafes ──
    MapPoint(
      id: 'cafe_1',
      name: 'Paws & Coffee Eskişehir',
      latitude: 39.7721,
      longitude: 30.5121,
      category: MapPointCategory.cafe,
      rating: 4.8,
      address: 'Köprübaşı, Odunpazarı, Eskişehir',
      description:
          'Evcil hayvanlarla birlikte kahve keyfi. Köpek bisküvileri mevcut!',
    ),
    MapPoint(
      id: 'cafe_2',
      name: 'Kedi Evi Kafe',
      latitude: 39.7705,
      longitude: 30.5195,
      category: MapPointCategory.cafe,
      rating: 4.6,
      address: 'Odunpazarı Evleri, Eskişehir',
      description: 'Tarihi Odunpazarı evlerinde kedi temalı kafe.',
    ),
    MapPoint(
      id: 'cafe_3',
      name: 'Bark & Brunch',
      latitude: 39.7651,
      longitude: 30.5059,
      category: MapPointCategory.cafe,
      rating: 4.5,
      address: 'Hamamyolu Cad., Eskişehir',
      description: 'Brunch menüsü ve pati-dostu bahçe alanı.',
    ),

    // ── Pet Shops ──
    MapPoint(
      id: 'shop_1',
      name: 'Pet Paradise Eskişehir',
      latitude: 39.7734,
      longitude: 30.5073,
      category: MapPointCategory.petShop,
      rating: 4.6,
      address: 'İsmet İnönü Cad., Tepebaşı, Eskişehir',
      description:
          'Mama, aksesuar ve oyuncak çeşitleri. Online sipariş de mevcut.',
    ),
    MapPoint(
      id: 'shop_2',
      name: 'Patili Dostlar Pet Shop',
      latitude: 39.7668,
      longitude: 30.5313,
      category: MapPointCategory.petShop,
      rating: 4.4,
      address: 'Arifiye Mah., Odunpazarı, Eskişehir',
      description: 'Her tür evcil hayvan için ürünler ve bakım malzemeleri.',
    ),
  ];

  @override
  Future<Result<List<MapPoint>>> getMapPoints() async {
    try {
      await Future.delayed(_delay);
      return const Success(_eskisehirPoints);
    } on Exception catch (e) {
      return Failure('Failed to load map points', exception: e);
    }
  }

  @override
  Future<Result<List<MapPoint>>> getMapPointsByCategory(
      MapPointCategory category) async {
    try {
      await Future.delayed(_delay);
      final filtered =
          _eskisehirPoints.where((p) => p.category == category).toList();
      return Success(filtered);
    } on Exception catch (e) {
      return Failure('Failed to load map points', exception: e);
    }
  }
}
