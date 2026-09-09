import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';

/// Neo-Brutalist 2-column "Gönderilerim" gallery grid (Design System Step
/// 61) — replaces the old 3-column, soft-rounded-corner grid that sat
/// inside a single [EspatiCard] wrapper (no per-tile border/shadow, so
/// tiles blended into each other and into the card behind them).
///
/// Generic over image URL + tap-by-index (not [PostModel]-typed), so it
/// stays reusable for any future profile gallery, not just posts.
///
/// Defaults to a standalone-scrollable grid. Pass `shrinkWrap: true,
/// physics: const NeverScrollableScrollPhysics()` when embedding inside
/// another scrollable — e.g. ProfileScreen's outer SingleChildScrollView.
class ProfilePostsGrid extends StatelessWidget {
  final List<String> imageUrls;

  /// Called with the tapped tile's index. Leave null during early
  /// integration (falls back to a [debugPrint] on tap, per the task's
  /// "wire to a full-screen post view later" note) or pass a real handler
  /// once one exists.
  final ValueChanged<int>? onTapItem;

  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;

  const ProfilePostsGrid({
    super.key,
    required this.imageUrls,
    this.onTapItem,
    this.shrinkWrap = false,
    this.physics,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      // crossAxisSpacing/mainAxisSpacing: 16 — generous gutters so each
      // tile's hard offset shadow has room to read against its neighbors
      // instead of colliding with them.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final imageUrl = imageUrls[index];
        return PostGridItem(
          imageUrl: imageUrl,
          onTap: onTapItem != null
              ? () => onTapItem!(index)
              : () => debugPrint('[PostGridItem] tapped index $index: $imageUrl'),
        );
      },
    );
  }
}

/// One square gallery tile — BorderRadius.zero, thick darkBrown border,
/// hard offset shadow, image filling the frame.
class PostGridItem extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onTap;

  /// Hard-shadow color — defaults to black (the app-wide default); pass
  /// EspatiColors.sageGreen for an accent tile.
  final Color shadowColor;

  const PostGridItem({
    super.key,
    required this.imageUrl,
    this.onTap,
    this.shadowColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: NeoBrutal.border(2.5),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: const Offset(4, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: EspatiColors.sageGreen.withValues(alpha: 0.25),
              child: const Icon(Icons.pets_rounded,
                  color: Colors.black, size: 28),
            ),
            errorWidget: (_, __, ___) => Container(
              color: EspatiColors.sageGreen.withValues(alpha: 0.25),
              child: const Icon(Icons.pets_rounded,
                  color: Colors.black, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
