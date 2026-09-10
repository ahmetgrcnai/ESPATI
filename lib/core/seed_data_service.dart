import 'package:cloud_firestore/cloud_firestore.dart';

/// Returned by [SeedDataService.seedEskisehirData] so the caller can
/// surface a meaningful result to the user (e.g. via SnackBar).
class SeedResult {
  final int added;
  final int skipped;
  const SeedResult({required this.added, required this.skipped});
}

/// One-time data seeding utility for the Firestore `places` collection.
///
/// Designed for a single call during development or first-run setup.
/// Duplicate-safe: queries existing names before writing so repeated
/// invocations never create duplicate documents.
class SeedDataService {
  final FirebaseFirestore _firestore;
  static const _kPlaces = 'places';

  SeedDataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Seed payload ─────────────────────────────────────────────────────────
  // category stores the Turkish UI label so documents are self-describing
  // in the Firebase Console.  MapPointCategory.fromString() accepts both
  // the Turkish label and the Dart enum name, so the parser handles both.

  static const List<Map<String, dynamic>> _eskisehirPlaces = [
    // ── Veterinerler ────────────────────────────────────────────────────────
    {
      'name': 'Anadolu Üni. Hayvan Hastanesi',
      'category': 'Veteriner',
      'latitude': 39.7915,
      'longitude': 30.5255,
      'address': 'Yunus Emre Kampüsü, Tepebaşı, Eskişehir',
      'description':
          'Anadolu Üniversitesi bünyesindeki tam donanımlı hayvan hastanesi. '
          'Acil, dahili ve cerrahi birimler 7/24 hizmet verir.',
      'rating': 4.8,
      'imageUrl': '',
    },
    {
      'name': 'Tepebaşı Doğal Yaşam Merkezi',
      'category': 'Veteriner',
      'latitude': 39.8150,
      'longitude': 30.4850,
      'address': 'Tepebaşı İlçesi, Eskişehir',
      'description':
          'Doğal yaşam ve rehabilitasyon merkezi. '
          'Yaban hayatı koruma ile evcil hayvan sağlık hizmetleri bir arada.',
      'rating': 4.7,
      'imageUrl': '',
    },
    {
      'name': 'Pati Park Veteriner',
      'category': 'Veteriner',
      'latitude': 39.7745,
      'longitude': 30.5090,
      'address': 'Köprübaşı Mah., Tepebaşı, Eskişehir',
      'description':
          'Aşılama, muayene ve grooming hizmetleri sunan güler yüzlü klinik. '
          'Randevusuz muayene imkânı.',
      'rating': 4.6,
      'imageUrl': '',
    },
    {
      'name': 'Odunpazarı Veteriner Kliniği',
      'category': 'Veteriner',
      'latitude': 39.7620,
      'longitude': 30.5380,
      'address': 'Odunpazarı Mah., Odunpazarı, Eskişehir',
      'description':
          'Tarihi Odunpazarı semtinde hizmet veren, 15 yıllık deneyimli '
          'veteriner kliniği. Mikroçip ve aşılama servisi.',
      'rating': 4.5,
      'imageUrl': '',
    },

    // ── Kafeler ─────────────────────────────────────────────────────────────
    {
      'name': 'Hey Dostum Kafe',
      'category': 'Kafe',
      'latitude': 39.7760,
      'longitude': 30.5135,
      'address': 'Adalar Bölgesi, Odunpazarı, Eskişehir',
      'description':
          'Evcil hayvan dostu kafe. Köpekler için özel ikramlar ve dış mekân '
          'su kapları mevcut. İç mekâna da alınır.',
      'rating': 4.7,
      'imageUrl': '',
    },
    {
      'name': 'Adalar Mado Çevresi',
      'category': 'Kafe',
      'latitude': 39.7775,
      'longitude': 30.5160,
      'address': 'Porsuk Adaları, Odunpazarı, Eskişehir',
      'description':
          'Porsuk kıyısında açık alan. Evcil hayvanlarıyla vakit geçirmek '
          'isteyenler için gondol manzaralı ideal buluşma noktası.',
      'rating': 4.5,
      'imageUrl': '',
    },
    {
      'name': 'Cassaba Modern Pati Alanı',
      'category': 'Kafe',
      'latitude': 39.7890,
      'longitude': 30.5050,
      'address': 'Cassaba, Odunpazarı, Eskişehir',
      'description':
          'Tarihi Cassaba dokusunda modern pati dostu kafe. '
          'Organik beslenme anlayışıyla hazırlanan menüsüyle öne çıkıyor.',
      'rating': 4.4,
      'imageUrl': '',
    },
    {
      'name': 'Porsuk Kıyısı Pati Kafe',
      'category': 'Kafe',
      'latitude': 39.7680,
      'longitude': 30.5200,
      'address': 'Porsuk Bulvarı, Odunpazarı, Eskişehir',
      'description':
          'Porsuk çayı kenarında açık hava kafe. Evcil hayvanlar için '
          'özel köşe ve mama kabı servisi mevcut.',
      'rating': 4.6,
      'imageUrl': '',
    },

    // ── Parklar ─────────────────────────────────────────────────────────────
    {
      'name': 'Batıkent Pati Parkı',
      'category': 'Park',
      'latitude': 39.8020,
      'longitude': 30.4780,
      'address': 'Batıkent Mah., Tepebaşı, Eskişehir',
      'description':
          'Çevrilmiş köpek koşturma alanı ve evcil hayvan oyun bölgesi içeren '
          'modern kentsel park. Mama otomatı bulunur.',
      'rating': 4.6,
      'imageUrl': '',
    },
    {
      'name': 'Kanlıkavak Parkı',
      'category': 'Park',
      'latitude': 39.7640,
      'longitude': 30.5010,
      'address': 'Kanlıkavak, Odunpazarı, Eskişehir',
      'description':
          'Geniş yeşil alanlar ve yürüyüş yolları. '
          'Pati dostları için serbest koşma bölgesi ve küçük gölet.',
      'rating': 4.7,
      'imageUrl': '',
    },
    {
      'name': 'Kentpark Evcil Hayvan Bölümü',
      'category': 'Park',
      'latitude': 39.7820,
      'longitude': 30.5420,
      'address': 'Kentpark, Odunpazarı, Eskişehir',
      'description':
          'Kent Parkı içindeki özel evcil hayvan oyun ve dinlenme alanı. '
          'Çim alan, engel parkuru ve çeşmeler mevcut.',
      'rating': 4.5,
      'imageUrl': '',
    },
    {
      'name': 'Sazova Bilim Kültür Parkı',
      'category': 'Park',
      'latitude': 39.7497,
      'longitude': 30.4806,
      'address': 'Sazova Mah., Tepebaşı, Eskişehir',
      'description':
          'Eskişehir\'in en büyük parkı. Evcil hayvan dostu geniş yürüyüş '
          'güzergahları, gölet çevresi ve hafta sonu etkinlikleri.',
      'rating': 4.9,
      'imageUrl': '',
    },

    // ── Pet Marketler ────────────────────────────────────────────────────────
    {
      'name': 'Eskişehir Pet Center',
      'category': 'Pet Mağazası',
      'latitude': 39.7710,
      'longitude': 30.5210,
      'address': 'Köprübaşı Mah., Tepebaşı, Eskişehir',
      'description':
          'Geniş yelpazede premium mama, aksesuar, oyuncak ve bakım ürünleri. '
          'Online sipariş ve eve teslimat imkânı.',
      'rating': 4.6,
      'imageUrl': '',
    },
    {
      'name': 'Zoo Market Tepebaşı',
      'category': 'Pet Mağazası',
      'latitude': 39.7850,
      'longitude': 30.5080,
      'address': 'Tepebaşı Mah., Tepebaşı, Eskişehir',
      'description':
          'Tüm evcil hayvan türleri için ürün çeşitliliği. '
          'Uzman personel beslenme ve bakım danışmanlığı sağlar.',
      'rating': 4.4,
      'imageUrl': '',
    },
  ];

  // ── Other-city Petshop/Kafe places (Design System Step 27) ────────────────
  // Step 26 unlocked map panning across all of Turkey (previously locked to
  // an Eskişehir-only camera bounds). These few real-city Petshop/Kafe
  // entries — same shape and quality bar as [_eskisehirPlaces], just not
  // Eskişehir — let a dev actually see pins appear when panning to
  // İstanbul/Ankara/İzmir, instead of that unlocked range being visually
  // empty. Kept in their own list (rather than folded into
  // [_eskisehirPlaces]) so that list's name stays accurate.
  static const List<Map<String, dynamic>> _otherCityPlaces = [
    {
      'name': 'Kadıköy Pati Butik',
      'category': 'Pet Mağazası',
      'latitude': 40.9905,
      'longitude': 29.0277,
      'address': 'Caferağa Mah., Kadıköy, İstanbul',
      'description':
          'Kadıköy çarşı içinde butik pet mağazası. Doğal mama ve el yapımı '
          'aksesuar seçkisiyle biliniyor.',
      'rating': 4.5,
      'imageUrl': '',
    },
    {
      'name': 'Kızılay Petzone',
      'category': 'Pet Mağazası',
      'latitude': 39.9208,
      'longitude': 32.8541,
      'address': 'Kızılay Mah., Çankaya, Ankara',
      'description':
          'Ankara merkezde geniş ürün gamına sahip pet mağazası zinciri şubesi. '
          'Aşı ve mikroçip hizmeti de sunar.',
      'rating': 4.3,
      'imageUrl': '',
    },
    {
      'name': 'Kızılay Pati Kafe',
      'category': 'Kafe',
      'latitude': 39.9180,
      'longitude': 32.8570,
      'address': 'Kızılay Mah., Çankaya, Ankara',
      'description':
          'Evcil hayvan dostu, geniş bahçeli kafe. Köpekler için özel menü ve '
          'su istasyonu bulunur.',
      'rating': 4.6,
      'imageUrl': '',
    },
    {
      'name': 'Alsancak Sahil Pati Kafe',
      'category': 'Kafe',
      'latitude': 38.4356,
      'longitude': 27.1428,
      'address': 'Alsancak Mah., Konak, İzmir',
      'description':
          'İzmir Kordon üzerinde deniz manzaralı, evcil hayvan dostu kafe. '
          'Açık hava oturma alanı ve pati ikramları mevcut.',
      'rating': 4.7,
      'imageUrl': '',
    },
  ];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Adds the seed locations — Eskişehir plus a handful of other-city
  /// Petshop/Kafe entries (Step 27) — to the `places` collection.
  ///
  /// Queries existing document names first and skips any place whose name
  /// is already present, so this method is safe to call multiple times.
  /// Uses a single [WriteBatch] for atomicity.
  ///
  /// Returns a [SeedResult] with counts of added and skipped documents.
  /// Throws on Firestore errors (caller should catch and surface to the user).
  Future<SeedResult> seedEskisehirData() async {
    final allPlaces = [..._eskisehirPlaces, ..._otherCityPlaces];

    // 1. Collect names already in Firestore.
    final existing = await _firestore.collection(_kPlaces).get();
    final existingNames = existing.docs
        .map((doc) => (doc.data()['name'] as String?) ?? '')
        .toSet();

    // 2. Filter out duplicates.
    final toAdd = allPlaces
        .where((p) => !existingNames.contains(p['name'] as String))
        .toList();

    final skipped = allPlaces.length - toAdd.length;

    if (toAdd.isEmpty) return SeedResult(added: 0, skipped: skipped);

    // 3. WriteBatch — all-or-nothing write.
    final batch = _firestore.batch();
    for (final data in toAdd) {
      batch.set(_firestore.collection(_kPlaces).doc(), data);
    }
    await batch.commit();

    return SeedResult(added: toAdd.length, skipped: skipped);
  }
}
