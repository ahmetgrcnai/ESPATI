import 'package:flutter/material.dart';

/// Shared Neo-Brutalist visual tokens for screens migrated to the new
/// design system (Pati AI, Akademi, Veterinere Sor, ...).
///
/// Single source for the border/shadow/background primitives so each
/// restyled screen doesn't redefine its own copy of the same literals —
/// see the ESPATI design-system consolidation notes: this replaces the
/// per-screen `_k...` constants that `pati_ai_screen.dart` previously
/// defined privately.
class NeoBrutal {
  NeoBrutal._();

  static const Color scaffoldBg = Color(0xFFFAFAFA);
  static const Color userBubble = Color(0xFFD6F599);
  static const Color aiSurface = Colors.white;

  /// Active-state accent for tab bars / selected chips.
  static const Color activeAccent = Color(0xFFB999F5);
  static const Color inactiveFill = Color(0xFFE0E0E0);
  static const Color inactiveContent = Color(0xFF757575);

  static const double borderWidth = 3.0;

  static Border border([double width = borderWidth]) =>
      Border.all(color: Colors.black, width: width);

  /// A rigid, unblurred offset shadow — the signature Neo-Brutalist "hard
  /// shadow". Pass [Offset.zero] to render no shadow at all (flat/pressed
  /// state).
  static List<BoxShadow> shadow([Offset offset = const Offset(4, 4)]) =>
      offset == Offset.zero
          ? const []
          : [
              BoxShadow(
                color: Colors.black,
                offset: offset,
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ];
}
