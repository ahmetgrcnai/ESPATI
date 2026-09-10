import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/map_launcher_service.dart';
import 'neo_brutalist_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEO-BRUTALIST AD LOCATION MAP (Design System Step 76)
//
// Wraps a non-interactive GoogleMap preview in the same blocky
// border/hard-shadow container language as the rest of the app, replacing
// Google's default rounded, elevated map card. Pairs with
// [NeoBrutalistMapMarker] — a single fixed terracotta paw-print pin used
// for every ad location, unlike [NeoBrutalistMapPin] (map_pin.dart), which
// is category-colored for the POI discovery map.
// ─────────────────────────────────────────────────────────────────────────────

/// Blocky map marker: a terracotta square with a paw icon and a downward
/// triangle tail, built the same way as [NeoBrutalistMapPin] (square block +
/// `CustomPaint` tail, tip aligned to a [Marker]'s default bottom-center
/// anchor) so no custom `anchor` needs setting.
class NeoBrutalistMapMarker extends StatelessWidget {
  const NeoBrutalistMapMarker({super.key});

  static const double _blockSize = 44;
  static const double _borderWidth = 3;
  static const double _shadowOffset = 3;
  static const double _tailWidth = 16;
  static const double _tailHeight = 12;

  /// The full canvas this widget paints into — pass this exact [Size] as
  /// `logicalSize` to `toBitmapDescriptor()` so the render capture isn't
  /// clipped or off-center.
  static const Size logicalSize = Size(
    _blockSize + _shadowOffset,
    _blockSize + _shadowOffset + _tailHeight,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: logicalSize.width,
      height: logicalSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: _blockSize,
              height: _blockSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EspatiColors.terracotta,
                border: Border.all(
                  color: Colors.black,
                  width: _borderWidth,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(_shadowOffset, _shadowOffset),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.pets,
                  color: Colors.white, size: 22),
            ),
          ),
          // Tail — pinned right under the block, 1px overlap so no seam
          // shows between the block's bottom border and the triangle.
          Positioned(
            left: (_blockSize - _tailWidth) / 2,
            top: _blockSize - 1,
            child: CustomPaint(
              size: const Size(_tailWidth, _tailHeight + 1),
              painter: const _MarkerTailPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerTailPainter extends CustomPainter {
  const _MarkerTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MarkerTailPainter oldDelegate) => false;
}

/// Renders [NeoBrutalistMapMarker] to a [BitmapDescriptor] for use as a
/// [Marker.icon]. The design never varies per listing, so
/// [_AdLocationMapWidgetState] builds this once per widget instance rather
/// than per rebuild.
Future<BitmapDescriptor> buildNeoBrutalistMapMarkerIcon() {
  return const NeoBrutalistMapMarker().toBitmapDescriptor(
    logicalSize: NeoBrutalistMapMarker.logicalSize,
    imageSize: NeoBrutalistMapMarker.logicalSize * 2,
  );
}

/// Neo-Brutalist wrapper around a non-interactive [GoogleMap] preview of a
/// single ad's location: thick dark-brown border, hard offset shadow, the
/// custom [NeoBrutalistMapMarker] pin, and a blocky "Yol Tarifi Al" button
/// overlaid bottom-right that hands off to the device's maps app via
/// [MapLauncherService].
class AdLocationMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  /// Shown as the marker's info-window title.
  final String label;

  const AdLocationMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  @override
  State<AdLocationMapWidget> createState() => _AdLocationMapWidgetState();
}

class _AdLocationMapWidgetState extends State<AdLocationMapWidget> {
  // Starts null so the map can render immediately with a stand-in marker;
  // `toBitmapDescriptor()` needs a frame to rasterize and can't block
  // `build()`.
  BitmapDescriptor? _markerIcon;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcon();
  }

  Future<void> _loadMarkerIcon() async {
    final icon = await buildNeoBrutalistMapMarkerIcon();
    if (mounted) setState(() => _markerIcon = icon);
  }

  @override
  Widget build(BuildContext context) {
    final position = LatLng(widget.latitude, widget.longitude);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.fromBorderSide(
          BorderSide(color: Colors.black, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: position, zoom: 14.5),
              markers: {
                Marker(
                  markerId: const MarkerId('ad_location'),
                  position: position,
                  // Stand-in hue used only for the brief window before the
                  // custom icon finishes rasterizing.
                  icon: _markerIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange),
                  infoWindow: InfoWindow(title: widget.label),
                ),
              },
              zoomControlsEnabled: false,
              zoomGesturesEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: NeoBrutalistButton(
                onPressed: () => MapLauncherService.launchGoogleMaps(
                    widget.latitude, widget.longitude, NavMode.driving),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: EspatiColors.sageGreen,
                    borderRadius: BorderRadius.zero,
                    border:
                        Border.all(color: Colors.black, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.navigation_rounded,
                          color: Colors.black, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'Yol Tarifi Al',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
