import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Light palette ──────────────────────────────────────────────────────────
  static const _lightText = Color(0xFF36454F); // charcoal — AppColors.textPrimary
  static const _lightBg   = AppColors.background;
  static const _lightSurf = AppColors.surface;
  static const _lightDiv  = AppColors.divider;

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const _darkBg   = Color(0xFF121212);
  static const _darkSurf = Color(0xFF1E1E1E);
  static const _darkCard = Color(0xFF2A2A2A);
  static const _darkText = Color(0xFFEEEEEE); // bright off-white for max contrast
  static const _darkDiv  = Color(0xFF3A3A3A);

  // ── Shared accent (readable on both backgrounds) ───────────────────────────
  // Primary blue — contrast ratio on dark (#121212) ≈ 4.6 : 1  ✓ AA
  // Primary blue — contrast ratio on light (#FFEEBD) ≈ 3.2 : 1  ~ (AA large)
  // Peach stays as accent only (icons / chips), not on body text

  // ════════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ════════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    final base = _buildTextTheme(_lightText);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.peach,
        onSecondary: _lightText,
        surface: _lightSurf,
        onSurface: _lightText,
        error: AppColors.error,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: _lightBg,

      // ── Full TextTheme ──
      textTheme: base,
      primaryTextTheme: base,

      // ── TextField cursor + selection ──
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.primary,
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBg,
        foregroundColor: _lightText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _lightText,
        ),
        iconTheme: const IconThemeData(color: _lightText),
      ),

      // ── Input Fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurf,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: _lightDiv, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          color: _lightText.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(color: _lightText, fontSize: 14),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: _lightSurf,
        elevation: 2,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.peach,
        foregroundColor: _lightText,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.peachLight,
        selectedColor: AppColors.peach,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: _lightText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
          color: _lightDiv, thickness: 1, space: 0),

      // ── Bottom Nav ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.softTeal,
        unselectedItemColor: Color(0xFFAAAAAA),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ════════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final base = _buildTextTheme(_darkText);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.peach,
        onSecondary: _darkText,
        surface: _darkSurf,
        onSurface: _darkText,
        error: AppColors.error,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: _darkBg,

      // ── Full TextTheme ──
      textTheme: base,
      primaryTextTheme: base,

      // ── TextField cursor + selection ──
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.peach,
        selectionColor: AppColors.peach.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.peach,
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBg,
        foregroundColor: _darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _darkText,
        ),
        iconTheme: const IconThemeData(color: _darkText),
      ),

      // ── Input Fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: _darkDiv, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          color: _darkText.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(color: _darkText, fontSize: 14),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 2,
        shadowColor: const Color(0x33000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.peach,
        foregroundColor: _darkText,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: _darkCard,
        selectedColor: AppColors.peach,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: _darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
          color: _darkDiv, thickness: 1, space: 0),

      // ── Bottom Nav — pure AMOLED black for zero-power dark mode ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: AppColors.softTeal,
        unselectedItemColor: Color(0xFF666666),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SHARED TEXT THEME BUILDER
  // Every variant is explicitly typed so widgets that inherit from the theme
  // always get the right color — no widget needs to hardcode a text color.
  // ════════════════════════════════════════════════════════════════════════════
  static TextTheme _buildTextTheme(Color textColor) {
    return GoogleFonts.poppinsTextTheme().copyWith(
      // ── Display ──
      displayLarge:  GoogleFonts.poppins(fontSize: 57, fontWeight: FontWeight.w400, color: textColor),
      displayMedium: GoogleFonts.poppins(fontSize: 45, fontWeight: FontWeight.w400, color: textColor),
      displaySmall:  GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w400, color: textColor),

      // ── Headline ──
      headlineLarge:  GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
      headlineSmall:  GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),

      // ── Title ──
      titleLarge:  GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleSmall:  GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),

      // ── Body ──
      bodyLarge:  GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodySmall:  GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: textColor.withValues(alpha: 0.7)),

      // ── Label ──
      labelLarge:  GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      labelMedium: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      labelSmall:  GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: textColor.withValues(alpha: 0.6)),
    );
  }
}
