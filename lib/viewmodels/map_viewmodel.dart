import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../core/result.dart';
import '../data/models/map_point.dart';
import '../data/repositories/interfaces/i_map_repository.dart';
import '../widgets/common/map_pin.dart' show mapPinColor, mapPinIcon;

/// ViewModel for the Map (Harita) tab.
///
/// Loads [MapPoint]s and tracks the user's live location. Filtering,
/// marker/pin building, and selected-point UI state used to live here too,
/// but [PoiMapScreen] (the screen that actually replaced the old
/// `MapScreen`/`UnifiedDiscoveryScreen` this ViewModel predates) reimplements
/// all of that itself as local State — its markers are custom-rendered
/// Neo-Brutalist bitmaps, not the plain [Marker]s this class used to build,
/// and its filter/selection are single-screen concerns with no other
/// consumer. That left `filterByCategory`/`selectPoint`/`clearSelection`/
/// `animateToPoint`/`animateToCenter`/`onMapCreated` and their backing
/// fields dead — nothing in the live app called them, confirmed by search
/// before removal. [currentCenter]/[hasUserLocation]/[updateUserLocation]
/// survive because [HealthEducationHubScreen]'s vet-clinic distance display
/// genuinely reads [currentCenter] — see [updateUserLocation]'s doc comment.
class MapViewModel extends ChangeNotifier {
  final IMapRepository _mapRepository;

  MapViewModel(this._mapRepository) {
    loadMapPoints();
  }

  // ── Eskişehir Center ──
  static const LatLng eskisehirCenter = LatLng(39.7767, 30.5206);

  // ── State Fields ──

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MapPoint> _allPoints = [];

  /// Every loaded point, unfiltered — [PoiMapScreen] applies its own
  /// category filter over this list itself.
  List<MapPoint> get allPoints => List.unmodifiable(_allPoints);

  LatLng _currentCenter = eskisehirCenter;

  /// The user's live location once [updateUserLocation] has been called,
  /// otherwise [eskisehirCenter]. [PoiMapScreen] tracks its own copy of this
  /// for its map camera (a View-layer concern) and calls [updateUserLocation]
  /// once Geolocator resolves it, so this ViewModel's copy — read by
  /// [HealthEducationHubScreen] for its vet-clinic distance display — stays
  /// in sync instead of silently drifting from what the map itself is
  /// centered on.
  LatLng get currentCenter => _currentCenter;

  bool _hasUserLocation = false;
  bool get hasUserLocation => _hasUserLocation;

  // ── Category Colors/Icons ──
  // Derived from [mapPinColor]/[mapPinIcon] (the same palette
  // [NeoBrutalistMapPin] paints on the map itself) instead of their own
  // separate Material palette, so a category always looks the same whether
  // it's a pin on the map or the icon chip in [PoiMapScreen]'s info card.
  static final Map<MapPointCategory, Color> categoryColors = {
    for (final c in MapPointCategory.values) c: mapPinColor(c),
  };

  static final Map<MapPointCategory, IconData> categoryIcons = {
    for (final c in MapPointCategory.values) c: mapPinIcon(c),
  };

  // ── Public Methods ──

  /// Loads all map points from the repository.
  Future<void> loadMapPoints() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _mapRepository.getMapPoints();

    switch (result) {
      case Success(:final data):
        _allPoints = data;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Updates the current center position — called by [PoiMapScreen] once
  /// Geolocator resolves the user's real position, so [currentCenter]
  /// reflects it here too instead of staying frozen at [eskisehirCenter].
  void updateUserLocation(double lat, double lng) {
    _currentCenter = LatLng(lat, lng);
    _hasUserLocation = true;
    notifyListeners();
  }

  /// Clears error message after UI has displayed it.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
