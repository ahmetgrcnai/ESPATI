import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/result.dart';
import '../data/models/map_point.dart';
import '../data/repositories/interfaces/i_map_repository.dart';

/// ViewModel for the Map screen.
///
/// Manages map points, category filtering, marker generation,
/// selected point state, and user location.
class MapViewModel extends ChangeNotifier {
  final IMapRepository _mapRepository;

  MapViewModel(this._mapRepository) {
    loadMapPoints();
  }

  // ── Eskişehir Center ──
  static const LatLng eskisehirCenter = LatLng(39.7713, 30.5107);

  // ── State Fields ──

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MapPoint> _allPoints = [];
  List<MapPoint> _filteredPoints = [];
  List<MapPoint> get filteredPoints => List.unmodifiable(_filteredPoints);

  MapPointCategory? _selectedCategory;
  MapPointCategory? get selectedCategory => _selectedCategory;

  MapPoint? _selectedPoint;
  MapPoint? get selectedPoint => _selectedPoint;

  Set<Marker> _markers = {};
  Set<Marker> get markers => _markers;

  LatLng _currentCenter = eskisehirCenter;
  LatLng get currentCenter => _currentCenter;

  GoogleMapController? _mapController;

  // ── Category Colors ──
  static const Map<MapPointCategory, Color> categoryColors = {
    MapPointCategory.vet: Color(0xFF2196F3),
    MapPointCategory.park: Color(0xFF4CAF50),
    MapPointCategory.cafe: Color(0xFF8D6E63),
    MapPointCategory.petShop: Color(0xFF9C27B0),
  };

  // ── Category Icons ──
  static const Map<MapPointCategory, IconData> categoryIcons = {
    MapPointCategory.vet: Icons.local_hospital_rounded,
    MapPointCategory.park: Icons.park_rounded,
    MapPointCategory.cafe: Icons.coffee_rounded,
    MapPointCategory.petShop: Icons.store_rounded,
  };

  // ── Public Methods ──

  /// Sets the GoogleMapController when the map is created.
  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Loads all map points from the repository.
  Future<void> loadMapPoints() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _mapRepository.getMapPoints();

    switch (result) {
      case Success(:final data):
        _allPoints = data;
        _applyFilter();
      case Failure(:final message):
        _errorMessage = message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Filters points by [category]. Pass `null` to show all.
  void filterByCategory(MapPointCategory? category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  /// Selects a point (triggers bottom sheet in UI).
  void selectPoint(MapPoint point) {
    _selectedPoint = point;
    notifyListeners();
  }

  /// Clears the selected point (dismisses bottom sheet).
  void clearSelection() {
    _selectedPoint = null;
    notifyListeners();
  }

  /// Animates the map camera to a specific point.
  Future<void> animateToPoint(MapPoint point) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(point.latitude, point.longitude),
        16.0,
      ),
    );
  }

  /// Animates the map camera to the user's location or Eskişehir center.
  Future<void> animateToCenter() async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentCenter, 13.0),
    );
  }

  /// Updates the current center position (e.g., from geolocator).
  void updateUserLocation(double lat, double lng) {
    _currentCenter = LatLng(lat, lng);
    notifyListeners();
  }

  /// Clears error message after UI has displayed it.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Private Methods ──

  /// Applies the current category filter and regenerates markers.
  void _applyFilter() {
    if (_selectedCategory == null) {
      _filteredPoints = List.from(_allPoints);
    } else {
      _filteredPoints =
          _allPoints.where((p) => p.category == _selectedCategory).toList();
    }
    _generateMarkers();
  }

  /// Generates Google Map markers from the filtered points.
  void _generateMarkers() {
    _markers = _filteredPoints.map((point) {
      final color = _markerHue(point.category);
      return Marker(
        markerId: MarkerId(point.id),
        position: LatLng(point.latitude, point.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(color),
        infoWindow: InfoWindow(
          title: point.name,
          snippet: '${point.category.label} • ⭐ ${point.rating}',
        ),
        onTap: () => selectPoint(point),
      );
    }).toSet();
  }

  /// Maps categories to marker hue values.
  double _markerHue(MapPointCategory category) {
    switch (category) {
      case MapPointCategory.vet:
        return BitmapDescriptor.hueAzure;
      case MapPointCategory.park:
        return BitmapDescriptor.hueGreen;
      case MapPointCategory.cafe:
        return BitmapDescriptor.hueOrange;
      case MapPointCategory.petShop:
        return BitmapDescriptor.hueViolet;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
