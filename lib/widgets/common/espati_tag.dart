import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable neo-brutalist pill tag — filled with [color] (e.g.
/// `EspatiColors.mintGreen` / `EspatiColors.peach`), solid dark-brown
/// border, subtle hard offset shadow. An optional leading [icon] sits
/// before [label].
class EspatiTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const EspatiTag({
    super.key,
    required this.label,
    this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.black),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.nunitoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
