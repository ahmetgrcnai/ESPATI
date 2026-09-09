import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/neo_brutalist_tokens.dart';
import '../../../widgets/common/neo_brutalist_button.dart';

/// A branded Google Sign-In button matching Google's identity guidelines —
/// the "G" mark keeps its own circular logo treatment (per Google's brand
/// rules), the surrounding button is the app's Neo-Brutalist white block.
///
/// Shows a loading spinner when [isLoading] is true and disables the tap.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      semanticLabel: 'Google ile devam et',
      onPressed: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo reproduced with Text + colours
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    'Google ile devam et',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Paints the four-colour Google "G" using a [RichText].
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
      ),
      alignment: Alignment.center,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'G',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                // Google blue — the most recognisable part of the "G"
                color: const Color(0xFF4285F4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
