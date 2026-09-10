import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/map_launcher_service.dart';
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/map_point.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common/map_pin.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POI MAP SCREEN (Phase 3 Step 6)
//
// Extracted from the former `UnifiedDiscoveryScreen`, which used to be Tab
// 0's root ("Keşfet"). Per the Summit A pivot, Tab 0 is now
// [AlgorithmicFeedScreen] (a scrolling feed) and this map is no longer a
// root tab at all — it's a normal pushed route, reached only via the
// "🗺️ Haritada Gör" button on the feed (`Navigator.push`). That's why this
// screen now owns a back button it never needed as a tab root.
//
// Content/behavior is otherwise unchanged from Step 3's mandate: a pure POI
// (Point of Interest) map — Park / Veteriner / Kafe / Pet Mağazası from
// [MapViewModel.allPoints]. It still never fetches or plots [ListingModel]
// data — a listing's last-known location renders in its own contextual
// mini-map inside [FeedDetailScreen] instead.
//
// Minimalist per CTO mandate: stark white scaffold, no AppBar, no pastel
// containers — orange (EspatiColors.peach) reserved for the active filter
// chip only.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// NEO-BRUTALIST MAP STYLE (Design System Step 26 — "vibrant" rework)
//
// Step 25's version read flat/gray ("ruhsuz") once bounds opened up to a
// whole-country view. This is a full replacement, not a tweak: near-white
// land so the map feels bright, bold near-black outlines on every road for
// the coloring-book/Neo-Brutalist look, a saturated blue for water, mint
// for parks, and peach for highways — high-contrast color blocks instead of
// the previous muted beige-on-beige. POI/transit icon clutter stays off so
// the custom [NeoBrutalistMapPin] markers remain the focal point; country/
// province borders stay on (bold + thin dark-brown respectively) since
// they're the only orientation cue left once you can zoom out to see all of
// Turkey (Step 26 also dropped [CameraTargetBounds]). Applied via
// `GoogleMap.style`.
// ─────────────────────────────────────────────────────────────────────────────
const String _neoBrutalistMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#FAFAFA"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#000000"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#FFFFFF"}, {"weight": 3}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"visibility": "off"}]},
  {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
  {"featureType": "administrative.neighborhood", "stylers": [{"visibility": "off"}]},
  {"featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [{"visibility": "on"}, {"color": "#000000"}, {"weight": 1.4}]},
  {"featureType": "administrative.province", "elementType": "geometry.stroke", "stylers": [{"visibility": "on"}, {"color": "#000000"}, {"weight": 0.8}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#7ED1B2"}]},
  {"featureType": "poi.park", "elementType": "geometry.stroke", "stylers": [{"color": "#000000"}, {"weight": 1.2}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#FFFFFF"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#000000"}, {"weight": 1}]},
  {"featureType": "road", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "road.arterial", "elementType": "geometry.fill", "stylers": [{"color": "#FBE4D8"}]},
  {"featureType": "road.highway", "elementType": "geometry.fill", "stylers": [{"color": "#F2A07E"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#000000"}, {"weight": 1.6}]},
  {"featureType": "road.local", "elementType": "geometry.fill", "stylers": [{"color": "#FFFFFF"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry.fill", "stylers": [{"color": "#3AB6E0"}]},
  {"featureType": "water", "elementType": "geometry.stroke", "stylers": [{"color": "#000000"}, {"weight": 1}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#FFFFFF"}]}
]
''';

/// Top filter bar labels (Design System Step 27), in display order — "Hepsi"
/// always first. A plain [String] rather than a [MapPointCategory]? because
/// "Hepsi" (All) has no corresponding category; [_PoiMapScreenState._categoryForFilter]
/// maps each of the other four back to their category to actually filter points.
const List<String> _filterLabels = ['Hepsi', 'Veteriner', 'Petshop', 'Park', 'Kafe'];

class PoiMapScreen extends StatefulWidget {
  /// Pre-selects one of [_filterLabels] on first build (e.g. a "Nöbetçi
  /// Veteriner Bul" CTA elsewhere in the app wants to land here already
  /// filtered to vets). Defaults to `'Hepsi'` — every existing call site is
  /// unaffected.
  final String initialFilter;

  const PoiMapScreen({super.key, this.initialFilter = 'Hepsi'});

  @override
  State<PoiMapScreen> createState() => _PoiMapScreenState();
}

class _PoiMapScreenState extends State<PoiMapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentCenter = MapViewModel.eskisehirCenter;
  bool _hasUserLocation = false;

  /// Drives the top filter bar (Design System Step 27) — one of
  /// [_filterLabels]. `'Hepsi'` shows every category.
  late String selectedFilter = widget.initialFilter;

  /// The pin the user last tapped — drives the custom Neo-Brutalist info
  /// card (Design System Step 24). `null` hides the card; set on marker
  /// tap, cleared on a bare map tap.
  MapPoint? _selectedLocationInfo;

  /// Clears MainScreen's floating [EspatiBottomNavBar] overlay. That bar's
  /// own bottom margin (24) is private to `_MainScreenState`, so this
  /// mirrors the literal rather than importing it, plus a little extra
  /// breathing room above the bar.
  static const double _infoCardBottomClearance =
      EspatiBottomNavBar.height + 24 + 16;

  /// Custom Neo-Brutalist marker bitmaps, one per [MapPointCategory] —
  /// rendered once (widget → PNG is not free) and reused for every point in
  /// that category. Falls back to a hued default marker for the brief
  /// window before this finishes loading.
  final Map<MapPointCategory, BitmapDescriptor> _pinIcons = {};

  /// Step 25's [LatLngBounds]/[CameraTargetBounds] lock (Eskişehir-only
  /// panning) is gone as of Step 26 — the map now pans freely across
  /// Turkey. Only the zoom range stays bounded: 4.0 comfortably fits the
  /// whole country on screen: 20.0 still allows close street-level detail.
  static const MinMaxZoomPreference _zoomPreference =
      MinMaxZoomPreference(4.0, 20.0);

  @override
  void initState() {
    super.initState();
    _requestLocation();
    _loadPinIcons();
  }

  Future<void> _loadPinIcons() async {
    final entries = await Future.wait(MapPointCategory.values.map(
      (category) async =>
          MapEntry(category, await buildNeoBrutalistPinIcon(category)),
    ));
    if (!mounted) return;
    setState(() => _pinIcons.addEntries(entries));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _hasUserLocation = true;
      });
      // Feeds the same real position into MapViewModel — HealthEducationHub's
      // vet-clinic distance display reads MapViewModel.currentCenter and
      // would otherwise stay stuck on eskisehirCenter forever, since nothing
      // else ever calls this.
      context
          .read<MapViewModel>()
          .updateUserLocation(position.latitude, position.longitude);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentCenter, 13.0),
      );
    } catch (_) {
      // Silently fall back to Eskişehir center.
    }
  }

  void _selectPoint(MapPoint point) {
    HapticFeedback.selectionClick();
    setState(() => _selectedLocationInfo = point);
  }

  void _clearSelection() {
    setState(() => _selectedLocationInfo = null);
  }

  // ── Local filtering (never touches shared ViewModel filter state) ──

  /// Maps a [_filterLabels] entry to the [MapPointCategory] it selects, or
  /// `null` for `'Hepsi'` (no category restriction — everything matches).
  MapPointCategory? _categoryForFilter(String filter) {
    switch (filter) {
      case 'Veteriner':
        return MapPointCategory.vet;
      case 'Petshop':
        return MapPointCategory.petShop;
      case 'Park':
        return MapPointCategory.park;
      case 'Kafe':
        return MapPointCategory.cafe;
      default: // 'Hepsi'
        return null;
    }
  }

  List<MapPoint> _filteredPoints(List<MapPoint> all) {
    final category = _categoryForFilter(selectedFilter);
    if (category == null) return all;
    return all.where((p) => p.category == category).toList();
  }

  Set<Marker> _buildMarkers(List<MapPoint> points) {
    final markers = <Marker>{};

    for (final p in points) {
      markers.add(Marker(
        markerId: MarkerId('point_${p.id}'),
        position: LatLng(p.latitude, p.longitude),
        icon: _pinIcons[p.category] ??
            BitmapDescriptor.defaultMarkerWithHue(_fallbackHue(p.category)),
        // No infoWindow — Google's default info bubble overlapped the
        // floating bottom nav bar and didn't match the Neo-Brutalist
        // language. [_LocationInfoCard] replaces it (Design System Step 24).
        onTap: () => _selectPoint(p),
      ));
    }

    return markers;
  }

  /// Stand-in hue used only for the brief window before [_loadPinIcons]
  /// finishes rendering the real blocky bitmaps.
  double _fallbackHue(MapPointCategory category) {
    switch (category) {
      case MapPointCategory.vet:
        return BitmapDescriptor.hueGreen;
      case MapPointCategory.petShop:
        return BitmapDescriptor.hueOrange;
      case MapPointCategory.park:
      case MapPointCategory.cafe:
        return BitmapDescriptor.hueYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<MapViewModel>(
      builder: (context, mapVm, _) {
        final points = _filteredPoints(mapVm.allPoints);
        final markers = _buildMarkers(points);

        return Scaffold(
          // ── Strict minimalist background: stark white, no pastel tint ──
          backgroundColor: isDark ? theme.scaffoldBackgroundColor : NeoBrutal.scaffoldBg,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // ── Full-screen map ──
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentCenter,
                  zoom: 13.5,
                ),
                style: _neoBrutalistMapStyle,
                minMaxZoomPreference: _zoomPreference,
                // Keeps the mandatory Google logo clear of the floating
                // info card / bottom nav bar hovering over the map's
                // bottom edge (Design System Step 24) — Google's TOS
                // requires the logo stay visible and unobstructed.
                padding: const EdgeInsets.only(bottom: 120),
                onMapCreated: (controller) => _mapController = controller,
                markers: markers,
                myLocationEnabled: _hasUserLocation,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                onTap: (_) => _clearSelection(),
              ),

              // ── Loading indicator (first paint only) ──
              if (mapVm.isLoading && mapVm.allPoints.isEmpty)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: EspatiColors.peach,
                    backgroundColor: Colors.transparent,
                  ),
                ),

              // ── Top filter bar — blocky Neo-Brutalist chips (Step 27) ──
              // No back button when this is MainScreen's "Harita" tab root
              // (Design System Step 12) — a pop()-based button would pop the
              // root navigator instead of itself, and there's nothing to
              // return to anyway. But this screen is *also* still a genuine
              // pushed route from elsewhere (HealthEducationHubScreen's
              // "Nöbetçi Veteriner" CTA pushes `PoiMapScreen(initialFilter:
              // 'Veteriner')` on top of whatever tab the user was on) — that
              // path had silently lost its only way back once this screen's
              // AppBar was removed for the tab-root case, since a bare
              // Scaffold with no AppBar draws no back affordance at all
              // (Android's system back still works; there was still no
              // in-app control, inconsistent with every other pushed screen
              // in this app). `Navigator.canPop` is exactly "was this
              // pushed", so the button only appears for that case.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  // Was 44 with 4px of vertical ListView padding eaten out
                  // of it (→ only 36px of actual cross-axis room) — less
                  // than the chip's own content needed (2px border + 2×9px
                  // padding + the Fredoka label's rendered line height), so
                  // the ListView's default hard-edge clip sliced the bottom
                  // of the text off. 52px, with only horizontal padding on
                  // the ListView, gives the chip its full height to work with.
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        if (Navigator.of(context).canPop()) ...[
                          const SizedBox(width: 16),
                          _RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.only(
                              left: Navigator.of(context).canPop() ? 4 : 16,
                              right: 16,
                            ),
                            children: _filterLabels
                                .map((label) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _FilterChip(
                                        label: label,
                                        selected: selectedFilter == label,
                                        onTap: () => setState(
                                            () => selectedFilter = label),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Konumuma Git — small, neutral (orange stays chip-only) ──
              if (_hasUserLocation && _selectedLocationInfo == null)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _RoundIconButton(
                    icon: Icons.my_location_rounded,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentCenter, 13.0),
                      );
                    },
                  ),
                ),

              // ── Selected pin — custom Neo-Brutalist info card ──────────
              // Hovers clear of MainScreen's floating bottom nav bar
              // instead of the old full-width sheet pinned to bottom: 0.
              if (_selectedLocationInfo != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: _infoCardBottomClearance,
                  child: _LocationInfoCard(
                    point: _selectedLocationInfo!,
                    onDirections: () => MapLauncherService.launchGoogleMaps(
                      _selectedLocationInfo!.latitude,
                      _selectedLocationInfo!.longitude,
                      NavMode.driving,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER CHIP — blocky, sharp-edged (Design System Step 27): mintGreen fill
// when selected, cream otherwise, both with a 2px dark-brown border and a
// hard offset shadow. Replaces the earlier fully-rounded mint/peach pill.
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? NeoBrutal.userBubble : Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
          boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
        ),
        child: Text(
          label,
          // Fredoka's rendered line box runs tall relative to its font
          // size — without an explicit line-height its descender room ran
          // right up against (and, at the old 36px cross-axis, past) the
          // chip's edge.
          style: GoogleFonts.baloo2(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUND ICON BUTTON — neutral utility button (back / my-location); never
// orange, so the filter chip stays the single unmistakable accent on screen.
// ─────────────────────────────────────────────────────────────────────────────

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: NeoBrutal.border(2),
          boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
        ),
        child: Icon(icon, size: 20, color: Colors.black),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCATION INFO CARD — compact Neo-Brutalist card for a selected pin
// (Design System Step 24). Replaces both the default GoogleMap InfoWindow
// (disabled — no `infoWindow` on the Marker) and the old full-width,
// rounded-Material `_PointPreview` sheet that sat flush at bottom: 0 and
// overlapped MainScreen's floating bottom nav bar.
// ─────────────────────────────────────────────────────────────────────────────

class _LocationInfoCard extends StatelessWidget {
  final MapPoint point;
  final VoidCallback onDirections;

  const _LocationInfoCard({required this.point, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    final catColor = MapViewModel.categoryColors[point.category]!;
    final catIcon = MapViewModel.categoryIcons[point.category]!;

    return Container(
      height: 108,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2),
        boxShadow: NeoBrutal.shadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Category icon block — same blocky language as the map pins
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: catColor,
              border: NeoBrutal.border(2),
              boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
            ),
            child: Icon(catIcon, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 12),

          // ── Left side: title + category subtitle ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  point.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  point.category.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Right side: compact blocky directions button ──
          GestureDetector(
            onTap: onDirections,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: NeoBrutal.userBubble,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(2),
                boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.navigation_rounded,
                      size: 18, color: Colors.black),
                  const SizedBox(height: 3),
                  Text(
                    'YOL TARİFİ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.baloo2(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
