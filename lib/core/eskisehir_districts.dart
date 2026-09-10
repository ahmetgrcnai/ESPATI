import 'dart:math';

/// Approximate town-center coordinates for Eskişehir's 14 districts.
///
/// Used to auto-geotag listings from [ListingFormScreen]'s district dropdown
/// (Sprint 9 — Interactive Map). Keys match the `_districts` list there
/// exactly, plus the free-form neighbourhood strings used by legacy/seed
/// listings (`location` field) so both sources resolve to a pin.
class EskisehirDistricts {
  EskisehirDistricts._();

  static const Map<String, (double, double)> centers = {
    'Odunpazarı': (39.7767, 30.5206),
    'Tepebaşı': (39.7902, 30.4864),
    'Sivrihisar': (39.4508, 31.5354),
    'İnönü': (39.8377, 30.1500),
    'Alpu': (39.8058, 30.9127),
    'Beylikova': (39.7508, 31.1428),
    'Çifteler': (39.3743, 31.0453),
    'Günyüzü': (39.1868, 31.3221),
    'Han': (39.2908, 31.6941),
    'Mahmudiye': (39.5083, 31.1667),
    'Mihalgazi': (39.9622, 30.7719),
    'Mihalıççık': (39.8931, 31.4808),
    'Sarıcakaya': (40.0666, 30.8898),
    'Seyitgazi': (39.4442, 30.7139),
    // Free-form aliases seen in legacy/seed `location` strings.
    'Eskişehir Merkez': (39.7767, 30.5206),
    'Bağlar': (39.7625, 30.5395),
    'Porsuk': (39.7739, 30.5108),
    '71 Evler': (39.7594, 30.4735),
  };

  static final Random _rng = Random();

  /// Resolves a district or free-form location string to a jittered
  /// `(lat, lng)` pair, so listings in the same district don't stack
  /// exactly on top of each other on the map. Falls back to the
  /// Eskişehir city-center coordinates for unrecognised input.
  static (double, double) resolve(String districtOrLocation) {
    final match = centers.entries.firstWhere(
      (e) => districtOrLocation.contains(e.key),
      orElse: () => const MapEntry('', (39.7713, 30.5107)),
    );
    final (lat, lng) = match.value;
    // ~±0.006° jitter (roughly ±650m) keeps pins within the district
    // while avoiding exact overlap.
    final jitterLat = (_rng.nextDouble() - 0.5) * 0.012;
    final jitterLng = (_rng.nextDouble() - 0.5) * 0.012;
    return (lat + jitterLat, lng + jitterLng);
  }
}
