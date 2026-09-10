import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';

/// Neo-Brutalist "Benim İlanlarım" list shell (Design System Step 62) —
/// just the list mechanics (16px vertical spacing, scroll/shrinkWrap
/// passthrough); [AdListCard] is the actual per-item widget, kept separate
/// so this stays decoupled from any concrete listing model.
///
/// Defaults to a standalone-scrollable list. Pass `shrinkWrap: true,
/// physics: const NeverScrollableScrollPhysics()` when embedding inside
/// another scrollable — e.g. ProfileScreen's outer SingleChildScrollView.
class ProfileAdsList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;

  const ProfileAdsList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.shrinkWrap = false,
    this.physics,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: itemBuilder,
    );
  }
}

/// Wide horizontal ad card — square image on the left (separated from the
/// details by a thick darkBrown vertical border), status badge/title/
/// date-location on the right.
class AdListCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  /// e.g. "KAYIP" / "SAHİPLENDİRME" — pass [statusColor] to match
  /// (terracotta for urgent/lost states, sageGreen for adoption/resolved).
  final String statusLabel;
  final Color statusColor;

  /// Date • location snippet shown muted at the bottom.
  final String subtitle;

  final VoidCallback? onTap;

  static const double _imageWidth = 104;

  const AdListCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.statusLabel,
    required this.subtitle,
    this.statusColor = EspatiColors.terracotta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2.5),
          boxShadow: NeoBrutal.shadow(),
        ),
        // IntrinsicHeight + stretch: the image column has no fixed height
        // of its own, so it always matches whatever height the details
        // side's content naturally needs, instead of leaving a gap (short
        // title) or overflowing (2-line title) against a hardcoded square.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _imageWidth,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.black, width: 2.5),
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: EspatiColors.sageGreen.withValues(alpha: 0.25),
                      child: const Icon(Icons.pets_rounded,
                          color: Colors.black, size: 26),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: EspatiColors.sageGreen.withValues(alpha: 0.25),
                      child: const Icon(Icons.pets_rounded,
                          color: Colors.black, size: 26),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Status badge, top-right ──
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.zero,
                            border: NeoBrutal.border(2),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.baloo2(
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── Title ──
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.baloo2(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),

                      const Spacer(),

                      // ── Date / location ──
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
