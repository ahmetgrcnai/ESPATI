import 'package:flutter/material.dart';

/// Core color tokens for the ESPATI neo-brutalist design system.
///
/// Named `EspatiColors` (not `AppColors`) — `lib/core/app_colors.dart`
/// already declares an `AppColors` class used throughout the existing
/// screens (different `peach` shade, different purpose). Two classes with
/// the same name in different files can't coexist without import aliasing,
/// so this system gets its own name rather than colliding with the legacy
/// one. [EspatiCard]/[EspatiTag] (`lib/widgets/common/`) and [AppTheme]
/// consume these tokens.
class EspatiColors {
  EspatiColors._(); // Prevent instantiation

  /// Scaffold background / border / hard-shadow color.
  /// "Deep Espresso" — softer/warmer/more visible than the original
  /// #231713 (near-black in many lighting conditions).
  static const Color darkBrown = Color(0xFF4A3732);

  /// Card / surface background.
  static const Color cream = Color(0xFFF6EFE6);

  /// Tag/pill accent — muted Sage Green. Step 56.5: replaces the original
  /// #7ED1B2 mint, which vibrated against the light cream canvas
  /// (Step 56) badly enough to cause eye strain. This is the canonical
  /// name going forward — prefer it in new code.
  static const Color sageGreen = Color(0xFF8A9A5B);

  /// Tag/pill accent — rich, warm Terracotta. Step 56.5: replaces the
  /// original #F2A07E peach for the same reason as [sageGreen]. Canonical
  /// name going forward — prefer it in new code.
  static const Color terracotta = Color(0xFFD96C4A);

  /// Kept as an alias so the ~15+ existing call sites across the app don't
  /// need a mass find/replace to pick up the Step 56.5 palette swap — same
  /// technique as [peach] below. New code should reach for [sageGreen]
  /// directly; a future cleanup pass can retire this name once every call
  /// site has been migrated (`EspatiColors.mintGreen` → `EspatiColors.sageGreen`).
  static const Color mintGreen = sageGreen;

  /// Kept as an alias — see [mintGreen]. New code should reach for
  /// [terracotta] directly (`EspatiColors.peach` → `EspatiColors.terracotta`).
  static const Color peach = terracotta;

  /// Tag/pill accent — pastel sky blue, same saturation/brightness family
  /// as [mintGreen]/[peach]. Added for the Topluluklar (Communities) grid's
  /// 4-color card rotation.
  static const Color lightBlue = Color(0xFF8FC7E8);

  /// Neutral near-black — icons/text needing more weight than [darkBrown].
  static const Color black = Color(0xFF1E1E1E);

  /// Destructive/error accent — delete actions, error snackbars, validation
  /// states. Same saturation/brightness family as [mintGreen]/[peach] so it
  /// reads as a fifth member of the palette rather than a bolted-on
  /// Material red. Added so screens on the Neo-Brutalist system never need
  /// to reach back into the legacy `AppColors.error` for this.
  static const Color red = Color(0xFFE8604C);
}
