import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart' show EspatiColors;
import '../core/neo_brutalist_tokens.dart';
import 'common/neo_brutalist_button.dart';

/// Neo-Brutalist Edit/Delete action sheet for a long-pressed pet card.
///
/// Draws its own blocky bordered container, so callers must pass
/// `backgroundColor: Colors.transparent` to `showModalBottomSheet` —
/// otherwise the sheet's default rounded/elevated Material surface shows
/// through behind this one, doubling up the background.
class PetActionBottomSheet extends StatelessWidget {
  final String petName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PetActionBottomSheet({
    super.key,
    required this.petName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(3),
          boxShadow: NeoBrutal.shadow(const Offset(4, 4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patiyi Yönet',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              petName,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            _ActionButton(
              label: 'Düzenle',
              icon: Icons.edit_rounded,
              backgroundColor: EspatiColors.sageGreen,
              textColor: Colors.black,
              onPressed: () {
                Navigator.of(context).pop();
                onEdit();
              },
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'Sil',
              icon: Icons.delete_rounded,
              backgroundColor: EspatiColors.terracotta,
              textColor: Colors.black,
              onPressed: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'Vazgeç',
              backgroundColor: Colors.white,
              textColor: Colors.black,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blocky Neo-Brutalist button used for each row in [PetActionBottomSheet]:
/// zero radius, a thick solid border, and an offset hard shadow — the same
/// tactile press feel as the rest of the design system, via
/// [NeoBrutalistButton].
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(3),
          boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
