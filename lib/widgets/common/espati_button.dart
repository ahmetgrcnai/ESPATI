import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/neo_brutalist_tokens.dart';
import 'neo_brutalist_button.dart';

/// Reusable Neo-Brutalist action button — solid black border + hard
/// offset shadow, matching [EspatiCard]/[EspatiTag]'s Design System
/// language. Fills whatever width its parent gives it (wrap in [Expanded]
/// for a half-width button, or use directly in a [Column] for a
/// prominent full-width CTA). Press feedback is [NeoBrutalistButton]'s
/// scale-down/spring-back, not Material's ripple — every existing caller
/// picks up the animation automatically.
class EspatiButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  /// Shows a spinner in place of the icon/label and disables taps —
  /// mirrors the loading state the plain [ElevatedButton]s this widget
  /// replaces already supported.
  final bool isLoading;

  const EspatiButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      onPressed: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: isLoading
              ? backgroundColor.withValues(alpha: 0.6)
              : backgroundColor,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
          boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.nunitoSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
