import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/neo_brutalist_tokens.dart';

/// Espati floating Neo-Brutalist bottom navigation — a sharp-edged,
/// white bar with a thick black border and hard offset shadow, floating
/// above the screen content.
///
/// 5 fixed tabs, `currentIndex`/`onTap` maps 1:1 to `MainScreen._screens`.
///
/// The container is a plain `Container` + `Row`, not Flutter's
/// `BottomNavigationBar` — there's no `BottomNavigationBarType` here to set.
/// `MainAxisAlignment.spaceEvenly` + `Expanded` children already gives every
/// slot equal width regardless of item count, the same "fixed, non-shifting"
/// guarantee `BottomNavigationBarType.fixed` provides on the native widget.
///
/// Icons use the "outlined" Material variant — [Icons.map_outlined] for
/// Harita rather than a rounded variant, so it doesn't stand out as the one
/// non-outlined icon among its siblings. Keşfet/Harita/Paties keep their
/// original stock icons (Step 51 brief); Profil and Topluluk were switched
/// to paw motifs — Profil to a bare single paw ([Icons.pets_outlined]) and
/// Topluluk to that same paw ringed by a circle ([_PawBadge]) — a "circle of
/// community" badge — replacing the generic 3-person [Icons.groups_outlined]
/// so the brand's paw identity carries through instead of a stock "people"
/// icon. An earlier 3-overlapping-paws version was tried and dropped: at
/// nav-bar icon size the paws' toe-dots visually merged into noise.
class EspatiBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double height = 64;

  static const _items = [
    (icon: Icons.explore_outlined, label: 'Keşfet'),
    (icon: Icons.map_outlined, label: 'Harita'),
    (icon: null, label: 'Topluluk'), // _PawCluster — see [_navItem]
    (icon: Icons.video_library_outlined, label: 'Paties'),
    (icon: Icons.pets_outlined, label: 'Profil'),
  ];

  const EspatiBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.black;
    final inactiveColor = Colors.black.withValues(alpha: 0.35);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(),
        boxShadow: NeoBrutal.shadow(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < _items.length; i++)
            _navItem(i, activeColor, inactiveColor),
        ],
      ),
    );
  }

  Widget _navItem(int index, Color activeColor, Color inactiveColor) {
    final item = _items[index];
    final isSelected = currentIndex == index;
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            item.icon != null
                ? Icon(item.icon, color: color, size: 23)
                : _PawBadge(color: color),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: GoogleFonts.nunitoSans(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Topluluk's icon — a single [Icons.pets_outlined] ringed by a thin circle
/// outline, reading as a "community circle" badge rather than a lone paw.
/// The ring is what distinguishes this from Profil's bare paw, so it's kept
/// deliberately light (matches the icon's own stroke weight) rather than
/// the bar's thick Neo-Brutalist border weight, which would read as a solid
/// disc rather than a ring at this size.
class _PawBadge extends StatelessWidget {
  final Color color;

  const _PawBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.6),
      ),
      child: Icon(Icons.pets_outlined, color: color, size: 15),
    );
  }
}
