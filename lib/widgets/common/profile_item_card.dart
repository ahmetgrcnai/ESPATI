import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;

/// Reusable Neo-Brutalist item card for the Profile ecosystem's lists/grids
/// (Design System Step 60) — "Benim İlanlarım", "Gönderilerim", and any
/// future profile list. Replaces the soft-shadow, rounded Material cards
/// those screens used, which blended into the light cream canvas
/// established in Steps 56–58.
///
/// Image on top (with an overlaid status badge, top-right), a thick
/// darkBrown divider, then title + subtitle below — a fixed layout, not a
/// generic `child:` slot, so every list that adopts it stays visually
/// identical.
class ProfileItemCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  /// Defaults match the task spec exactly ("AKTİF" / sageGreen); pass your
  /// own for other states — e.g. `badgeLabel: 'ACİL', badgeColor:
  /// EspatiColors.terracotta` for an urgent listing.
  final String badgeLabel;
  final Color badgeColor;

  static const double _imageHeight = 110;

  const ProfileItemCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.badgeLabel = 'AKTİF',
    this.badgeColor = EspatiColors.sageGreen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.fromBorderSide(
            BorderSide(color: Colors.black, width: 2.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + status badge ──────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: _imageHeight,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: EspatiColors.terracotta.withValues(alpha: 0.25),
                      child: const Icon(Icons.pets_rounded,
                          color: Colors.black, size: 28),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: EspatiColors.terracotta.withValues(alpha: 0.25),
                      child: const Icon(Icons.pets_rounded,
                          color: Colors.black, size: 28),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.zero,
                      border:
                          Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      badgeLabel,
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Thick divider between image and text areas ────────────────
            Container(height: 2.5, color: Colors.black),

            // ── Text area ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
