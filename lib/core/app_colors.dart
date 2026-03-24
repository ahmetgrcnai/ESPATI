import 'package:flutter/material.dart';

/// Espati app color palette
/// These colors define the visual identity of the app.
class AppColors {
  AppColors._(); // Prevent instantiation

  /// Primary blue — used for bottom navigation bar background
  static const Color primary = Color(0xFF2196F3);

  /// Peach — used for bottom navigation icon backgrounds
  static const Color peach = Color(0xFFFFB6A0);

  /// Light cream — used for screen backgrounds
  static const Color background = Color(0xFFFFEEBF);

  /// Charcoal gray — used for text
  static const Color textPrimary = Color(0xFF36454F);

  /// White — used for cards and surfaces
  static const Color surface = Color(0xFFFFFFFF);

  /// Light gray — used for dividers and borders
  static const Color divider = Color(0xFFE0E0E0);

  /// Subtle shadow color
  static const Color shadow = Color(0x1A000000);

  /// Success green
  static const Color success = Color(0xFF4CAF50);

  /// Warning amber
  static const Color warning = Color(0xFFFFC107);

  /// Error / Lost pet red
  static const Color error = Color(0xFFE53935);

  /// Light peach — used for chip backgrounds, highlights
  static const Color peachLight = Color(0xFFFFD9CF);

  /// Dark blue — for active/selected states
  static const Color primaryDark = Color(0xFF1976D2);

  /// Light blue — for secondary highlights
  static const Color primaryLight = Color(0xFFBBDEFB);

  /// Deep Peach — splash screen background (light mode)
  static const Color splashPeach = Color(0xFFFFCBA4);

  /// Soft Teal — active bottom nav item (both modes)
  static const Color softTeal = Color(0xFF4DB6AC);

  /// Soft Teal Light — teal pill background / highlights
  static const Color softTealLight = Color(0xFFB2DFDB);
}
