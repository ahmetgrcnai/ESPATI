import 'package:flutter/material.dart';

/// Neo-brutalist "Lex-inspired" visual system — Dark Walnut Brown / Cream.
///
/// Pure styling constants + decoration builders. No state, no logic — every
/// member here is either a [Color] or a function that returns a
/// [BoxDecoration]/[TextStyle], safe to call from any StatelessWidget.
class NeoBrutalism {
  NeoBrutalism._();

  // ── Palette ──────────────────────────────────────────────────────────────
  // Kept in sync with EspatiColors.darkBrown (core/constants/app_colors.dart)
  // — this is a separate constant, not derived from it, since the 4 screens
  // still on NeoBrutalism predate that consolidation; update both together.
  static const Color walnut = Color(0xFF4A3732); // scaffold bg / hard shadow / borders — "Deep Espresso"
  static const Color cream = Color(0xFFF6EFE6); // card background
  static const Color mint = Color(0xFF7ED1B2); // pill accent 1
  static const Color peach = Color(0xFFF2A07E); // pill accent 2

  static const double borderWidth = 2;
  static const Offset shadowOffset = Offset(4, 4);
  static const Offset pillShadowOffset = Offset(3, 3);

  // ── Card decoration ─────────────────────────────────────────────────────
  //
  // Solid walnut border + a hard, non-blurred offset shadow (blurRadius: 0)
  // — the signature neo-brutalist "sticker" look, as opposed to a soft
  // Material drop shadow.
  static BoxDecoration card({
    Color background = cream,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: background,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(color: walnut, width: borderWidth),
      boxShadow: [
        BoxShadow(color: walnut, offset: shadowOffset, blurRadius: 0),
      ],
    );
  }

  // ── Pill / tag decoration ───────────────────────────────────────────────
  //
  // Same hard-shadow language as [card], scaled down for chip-sized filter
  // pills. [background] is expected to be [mint] or [peach] per the spec.
  static BoxDecoration pill({
    required Color background,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: background,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: Border.all(color: walnut, width: borderWidth),
      boxShadow: [
        BoxShadow(color: walnut, offset: pillShadowOffset, blurRadius: 0),
      ],
    );
  }

  /// Text color for content drawn on top of [cream]/[mint]/[peach] — always
  /// [walnut] for AA contrast against every pastel in this palette.
  static const Color onLight = walnut;

  /// Text color for content drawn on top of the [walnut] scaffold.
  static const Color onDark = cream;
}
