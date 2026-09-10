import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart' as design;
import 'neo_brutalist_tokens.dart';

/// Neo-brutalist visual system — light [NeoBrutal.scaffoldBg] canvas, pure
/// black borders/text, zero-radius corners, hard offset shadows. This is the
/// same "Gen3" system [NeoBrutal] and every migrated screen already use —
/// this file makes it the app's actual Material theme default too, instead
/// of every screen having to override an old dark-brown/cream default on
/// its own Scaffold/AppBar.
///
/// [lightTheme] and [darkTheme] intentionally render the identical palette —
/// this design is a single unified brand look, not a light/dark pair. Both
/// getters are kept (rather than collapsing to one) purely so
/// `MaterialApp.theme`/`darkTheme`/`themeMode` in `main.dart` — and the
/// user-facing "Karanlık Mod" toggle in [ProfileScreen] — keep working
/// exactly as before; no navigation/state logic changes with this overhaul.
///
/// Sourced from [design.EspatiColors] (`core/constants/app_colors.dart`) —
/// the canonical design-system palette, shared with [EspatiCard]/[EspatiTag]
/// (`widgets/common/`). Imported with a prefix only because `design` reads
/// better than an unprefixed `EspatiColors.` throughout this file's own
/// palette section below; no legacy `AppColors` dependency left as of the
/// design-system cleanup pass — [EspatiColors.red] covers `error` now.
class AppTheme {
  AppTheme._();

  // ── Neo-brutalist palette ────────────────────────────────────────────────
  static const _bg = NeoBrutal.scaffoldBg; // scaffold background
  static const _card = Colors.white; // card / surface background
  static const _onBg = Colors.black; // text drawn directly on the scaffold
  static const _onCard = Colors.black; // text drawn on white surfaces
  static const _accentA = design.EspatiColors.peach; // primary accent
  static const _accentB = design.EspatiColors.mintGreen; // secondary accent
  static const _div = Color(0xFFE0E0E0); // light divider, one step darker than bg

  // ════════════════════════════════════════════════════════════════════════════
  // LIGHT THEME — same neo-brutalist palette as dark (see class doc)
  // ════════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  // ════════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ════════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final base = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: _accentA,
        onPrimary: _onCard,
        secondary: _accentB,
        onSecondary: _onCard,
        surface: _card,
        onSurface: _onCard,
        error: design.EspatiColors.red,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: _bg,

      // ── Full TextTheme ──
      textTheme: base,
      primaryTextTheme: base,

      // ── TextField cursor + selection ──
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _accentA,
        selectionColor: _accentA.withValues(alpha: 0.3),
        selectionHandleColor: _accentA,
      ),

      // ── AppBar — heading font, drawn on the walnut scaffold ──
      appBarTheme: AppBarTheme(
        backgroundColor: _bg,
        foregroundColor: _onBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.baloo2(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _onBg,
        ),
        iconTheme: const IconThemeData(color: _onBg),
      ),

      // ── Input Fields ── filled defaults to false: every migrated
      // Neo-Brutalist field widget already draws its own white/black-bordered
      // container around a plain TextField, so a theme-level `filled: true`
      // fill only ever leaked an unwanted background *inside* that container.
      // See NeoBrutalistTextField/NeoBrutalistSearchBar for the pattern this
      // now matches instead of fighting.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _accentA, width: 2.5),
        ),
        hintStyle: GoogleFonts.nunitoSans(
          color: _onCard.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.nunitoSans(color: _onCard, fontSize: 14),
      ),

      // ── Cards — neo-brutalist: solid border + hard offset shadow ──
      cardTheme: CardThemeData(
        color: _card,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.black, width: 2),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accentA,
        foregroundColor: _onCard,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.black, width: 2),
        ),
      ),

      // ── Chips / pills ──
      chipTheme: ChipThemeData(
        backgroundColor: _accentB,
        selectedColor: _accentA,
        labelStyle: GoogleFonts.nunitoSans(
            fontSize: 12, fontWeight: FontWeight.w600, color: _onCard),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.black, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(color: _div, thickness: 1, space: 0),

      // ── Bottom Nav ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _bg,
        selectedItemColor: _accentB,
        unselectedItemColor: _onBg.withValues(alpha: 0.45),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SHARED TEXT THEME BUILDER
  //
  // Headings (display/headline/titleLarge/titleMedium) use Fredoka — the
  // "playful flat design" heading font. Body/label copy stays on Poppins for
  // readability at small sizes. All variants render [_onBg] (cream) since
  // Flutter's default `Text` widgets sit directly on the dark-brown scaffold;
  // the handful of cream-card widgets that need dark-on-cream text set their
  // own color explicitly via `EspatiColors.darkBrown` rather than relying on
  // the theme default (see [_CommunityGroupCard] etc.).
  // ════════════════════════════════════════════════════════════════════════════
  static TextTheme _buildTextTheme() {
    return GoogleFonts.nunitoSansTextTheme().copyWith(
      // ── Display (Fredoka — heading) ──
      displayLarge:  GoogleFonts.baloo2(fontSize: 57, fontWeight: FontWeight.w600, color: _onBg),
      displayMedium: GoogleFonts.baloo2(fontSize: 45, fontWeight: FontWeight.w600, color: _onBg),
      displaySmall:  GoogleFonts.baloo2(fontSize: 36, fontWeight: FontWeight.w600, color: _onBg),

      // ── Headline (Fredoka — heading) ──
      headlineLarge:  GoogleFonts.baloo2(fontSize: 32, fontWeight: FontWeight.w700, color: _onBg),
      headlineMedium: GoogleFonts.baloo2(fontSize: 24, fontWeight: FontWeight.w700, color: _onBg),
      headlineSmall:  GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.w600, color: _onBg),

      // ── Title (Fredoka for Large/Medium — still heading-weight; Small stays body-like) ──
      titleLarge:  GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w600, color: _onBg),
      titleMedium: GoogleFonts.baloo2(fontSize: 16, fontWeight: FontWeight.w600, color: _onBg),
      titleSmall:  GoogleFonts.nunitoSans(fontSize: 14, fontWeight: FontWeight.w500, color: _onBg),

      // ── Body (Poppins — readable copy) ──
      bodyLarge:  GoogleFonts.nunitoSans(fontSize: 16, fontWeight: FontWeight.w400, color: _onBg),
      bodyMedium: GoogleFonts.nunitoSans(fontSize: 14, fontWeight: FontWeight.w400, color: _onBg),
      bodySmall:  GoogleFonts.nunitoSans(fontSize: 12, fontWeight: FontWeight.w400, color: _onBg.withValues(alpha: 0.7)),

      // ── Label (Poppins) ──
      labelLarge:  GoogleFonts.nunitoSans(fontSize: 14, fontWeight: FontWeight.w600, color: _onBg),
      labelMedium: GoogleFonts.nunitoSans(fontSize: 12, fontWeight: FontWeight.w500, color: _onBg),
      labelSmall:  GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.w400, color: _onBg.withValues(alpha: 0.6)),
    );
  }
}
