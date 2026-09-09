import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/map_point.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEO-BRUTALIST MAP PIN (Design System Step 22, categories expanded Step 27)
//
// Replaces Google's default teardrop markers on [PoiMapScreen] with a
// blocky, Minecraft-style pin: a sharp square block (thick dark-brown
// border, hard offset shadow) with a small downward triangle tail. The
// tail's tip lines up with a [Marker]'s default anchor (bottom-center,
// `Offset(0.5, 1.0)`) — same trick classic teardrop pins use to point at
// their exact geo-coordinate — so no custom `anchor` needs setting.
// ─────────────────────────────────────────────────────────────────────────────

/// Cafe's own accent — not (yet) an [EspatiColors] token. Step 22 had Cafe
/// share Park's cream block (distinguished only by icon); Step 27 asked for
/// a dedicated color, and since [EspatiColors.mintGreen] is already Vet's
/// color, reusing it for Cafe too would make two categories share a hue —
/// this warm amber keeps all four categories distinguishable at a glance.
const Color _cafeAccent = Color(0xFFF6C453);

/// The single source of truth for "what color represents this category" —
/// used by [NeoBrutalistMapPin] itself and by [MapViewModel.categoryColors]
/// so the map pin and the [PoiMapScreen] info-card icon chip for the same
/// point always agree, instead of drifting into two separate palettes.
Color mapPinColor(MapPointCategory category) {
  switch (category) {
    case MapPointCategory.vet:
      return EspatiColors.mintGreen;
    case MapPointCategory.petShop:
      return EspatiColors.peach;
    case MapPointCategory.park:
      return EspatiColors.lightBlue;
    case MapPointCategory.cafe:
      return _cafeAccent;
  }
}

/// The single source of truth for "what icon represents this category" —
/// same reasoning as [mapPinColor].
IconData mapPinIcon(MapPointCategory category) {
  switch (category) {
    case MapPointCategory.vet:
      return Icons.local_hospital_rounded;
    case MapPointCategory.petShop:
      return Icons.shopping_bag_rounded;
    case MapPointCategory.park:
      return Icons.park_rounded;
    case MapPointCategory.cafe:
      return Icons.coffee_rounded;
  }
}

class NeoBrutalistMapPin extends StatelessWidget {
  final MapPointCategory category;

  const NeoBrutalistMapPin({super.key, required this.category});

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
                color: mapPinColor(category),
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
              child: Icon(mapPinIcon(category),
                  color: Colors.black, size: 22),
            ),
          ),
          // Tail — pinned right under the block, 1px overlap so no seam
          // shows between the block's bottom border and the triangle.
          Positioned(
            left: (_blockSize - _tailWidth) / 2,
            top: _blockSize - 1,
            child: CustomPaint(
              size: const Size(_tailWidth, _tailHeight + 1),
              painter: const _PinTailPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  const _PinTailPainter();

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
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) => false;
}

/// Renders [NeoBrutalistMapPin] to a [BitmapDescriptor] for use as a
/// [Marker.icon]. Every point in a given [MapPointCategory] looks
/// identical, so callers should build this once per category and cache the
/// result rather than re-rendering per point — see
/// `_PoiMapScreenState._loadPinIcons`.
Future<BitmapDescriptor> buildNeoBrutalistPinIcon(
  MapPointCategory category,
) {
  return NeoBrutalistMapPin(category: category).toBitmapDescriptor(
    logicalSize: NeoBrutalistMapPin.logicalSize,
    imageSize: NeoBrutalistMapPin.logicalSize * 2,
  );
}
