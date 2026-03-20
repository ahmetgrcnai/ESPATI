import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../data/models/map_point.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../widgets/place_card.dart';

/// Map screen — interactive Google Map centered on Eskişehir
/// with pet-friendly markers, category filter chips, and a detail bottom sheet.
///
/// All business logic is delegated to [MapViewModel].
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _locationRequested = false;

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  /// Requests user location and updates the ViewModel.
  Future<void> _requestLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        final vm = context.read<MapViewModel>();
        vm.updateUserLocation(position.latitude, position.longitude);
        vm.animateToCenter();
      }
    } catch (_) {
      // Silently fall back to Eskişehir center
    } finally {
      if (mounted) {
        setState(() => _locationRequested = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Eskişehir Pet Map',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.peachLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.my_location_rounded,
                  color: AppColors.textPrimary, size: 20),
            ),
            onPressed: () {
              context.read<MapViewModel>().animateToCenter();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<MapViewModel>(
        builder: (context, viewModel, child) {
          // ── Error State ──
          if (viewModel.errorMessage != null && !viewModel.isLoading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 56, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => viewModel.loadMapPoints(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Loading State ──
          if (viewModel.isLoading && viewModel.filteredPoints.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Map + UI ──
          return Stack(
            children: [
              // ── Google Map ──
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: viewModel.currentCenter,
                  zoom: 13.0,
                ),
                onMapCreated: viewModel.onMapCreated,
                markers: viewModel.markers,
                myLocationEnabled: _locationRequested,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                onTap: (_) => viewModel.clearSelection(),
                style: _mapStyle,
              ),

              // ── Filter Chips (top) ──
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        isSelected: viewModel.selectedCategory == null,
                        icon: Icons.pets_rounded,
                        onSelected: () => viewModel.filterByCategory(null),
                      ),
                      ...MapPointCategory.values.map((cat) {
                        return _buildFilterChip(
                          label: cat.label,
                          isSelected: viewModel.selectedCategory == cat,
                          icon: MapViewModel.categoryIcons[cat] ??
                              Icons.place_rounded,
                          color: MapViewModel.categoryColors[cat],
                          onSelected: () => viewModel.filterByCategory(cat),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── Place Count Badge ──
              Positioned(
                bottom: viewModel.selectedPoint != null ? 210 : 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.place_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${viewModel.filteredPoints.length} places',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom Sheet (selected point) ──
              if (viewModel.selectedPoint != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _PointDetailSheet(
                    point: viewModel.selectedPoint!,
                    onClose: () => viewModel.clearSelection(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    Color? color,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        elevation: 2,
        shadowColor: AppColors.shadow,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected ? (color ?? AppColors.primary) : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : (color ?? AppColors.textPrimary),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Detail Bottom Sheet ──
class _PointDetailSheet extends StatelessWidget {
  final MapPoint point;
  final VoidCallback onClose;

  const _PointDetailSheet({required this.point, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Place card
              PlaceCard(
                name: point.name,
                category: point.category.label,
                iconType: point.iconType,
                rating: point.rating,
                distance: '',
                address: point.address,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Navigate to ${point.name}'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),

              // Description
              if (point.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  point.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<MapViewModel>().animateToPoint(point);
                        onClose();
                      },
                      icon: const Icon(Icons.near_me_rounded, size: 18),
                      label: const Text('Zoom In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A clean, minimalist silver map style for Google Maps.
const String _mapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f5"}]},
  {"featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#bdbdbd"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#eeeeee"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#c8e6c9"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#388e3c"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
  {"featureType": "road.arterial", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#dadada"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
  {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]},
  {"featureType": "transit.line", "elementType": "geometry", "stylers": [{"color": "#e5e5e5"}]},
  {"featureType": "transit.station", "elementType": "geometry", "stylers": [{"color": "#eeeeee"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#bbdefb"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#1976d2"}]}
]
''';
