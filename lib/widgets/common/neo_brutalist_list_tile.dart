import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import 'neo_brutalist_button.dart';

/// A reusable Neo-Brutalist settings row (Design System Step 54) — a
/// rectangular cream block with a thick darkBrown border and a hard offset
/// shadow, a leading icon in its own solid-colored square, bold Fredoka
/// title (+ optional muted subtitle), and a trailing chevron by default.
///
/// Built on [NeoBrutalistButton] (Step 44) rather than a hand-rolled
/// [GestureDetector]/[AnimatedScale] pair — it already provides exactly the
/// "slight scale-down on tap, spring back on release" feedback every other
/// tappable block in the app uses, so reusing it keeps the press feel
/// consistent for free instead of re-implementing it here.
class NeoBrutalistListTile extends StatelessWidget {
  final IconData icon;
  final Color iconBoxColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Overrides the default trailing chevron — e.g. a [Switch] for a toggle
  /// row. Pass an explicit empty [SizedBox] to render nothing.
  final Widget? trailing;

  const NeoBrutalistListTile({
    super.key,
    required this.icon,
    required this.title,
    this.iconBoxColor = EspatiColors.mintGreen,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.fromBorderSide(
            BorderSide(color: Colors.black, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBoxColor,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Icon(icon, size: 19, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.black),
          ],
        ),
      ),
    );
  }
}
