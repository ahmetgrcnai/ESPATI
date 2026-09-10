import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart' show EspatiColors;
import '../../../core/neo_brutalist_tokens.dart';
import '../../../widgets/common/neo_brutalist_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHARED AUTH SCREEN WIDGETS (Neo-Brutalist pass — aligned to the app's
// current design system). Used by LoginScreen / SignUpScreen /
// ForgotPasswordScreen so all three read as one family instead of each
// defining its own private `_PrimaryButton`/`_OrDivider` copy.
// ─────────────────────────────────────────────────────────────────────────────

/// Full-width Neo-Brutalist submit block — terracotta fill, thick black
/// border, hard offset shadow.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      semanticLabel: label,
      onPressed: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isLoading
              ? EspatiColors.terracotta.withValues(alpha: 0.5)
              : EspatiColors.terracotta,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2.5),
          boxShadow: isLoading ? null : NeoBrutal.shadow(const Offset(3, 3)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : Text(
                label,
                style: GoogleFonts.baloo2(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
              ),
      ),
    );
  }
}

/// "veya" divider — a thin black rule on either side of the label.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 2, color: Colors.black12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya',
            style: GoogleFonts.nunitoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ),
        Expanded(child: Container(height: 2, color: Colors.black12)),
      ],
    );
  }
}

/// Square Neo-Brutalist icon badge — accent fill, thick black border, hard
/// offset shadow. Replaces the old soft circular tinted-icon badges.
class AuthIconBadge extends StatelessWidget {
  const AuthIconBadge({
    super.key,
    required this.icon,
    this.size = 88,
    this.color = EspatiColors.terracotta,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(3),
        boxShadow: NeoBrutal.shadow(const Offset(4, 4)),
      ),
      child: Icon(icon, size: size * 0.5, color: Colors.black),
    );
  }
}

/// Sharp square back-button block, top-left of the form — same convention
/// as every other current-generation screen's app bar back button.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: NeoBrutalistButton(
        semanticLabel: 'Geri',
        onPressed: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: NeoBrutal.border(2.5),
            boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.black, size: 20),
        ),
      ),
    );
  }
}
