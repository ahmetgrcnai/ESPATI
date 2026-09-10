import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart' show EspatiColors;
import '../core/neo_brutalist_tokens.dart';
import '../data/models/post_model.dart';
import '../widgets/common/neo_brutalist_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DISCOVER POST CARD (Design System Step 66) — the Discover feed's
// Neo-Brutalist post card. Wide rectangular block, thick darkBrown border,
// hard offset shadow — replaces the soft-rounded, blurred-shadow card
// language every other feed card in the app used before this step.
//
// Deliberately decoupled from live like/bookmark state (Step 60-62's
// established pattern): [isLiked]/[isBookmarked] and the tap callbacks are
// plain params, not a `Consumer<SocialViewModel>` baked into this widget.
// The caller (DiscoverScreen) owns the `Selector<SocialViewModel, ...>`
// scoping so only the one card whose like/bookmark state actually changed
// rebuilds, not the whole feed.
// ─────────────────────────────────────────────────────────────────────────────

class DiscoverPostCard extends StatelessWidget {
  final PostModel post;

  /// Live like count — pass `SocialViewModel.getPatiCount(post.id)` (after
  /// seeding it from `post.patiCount`), not the possibly-stale
  /// `post.patiCount` snapshot directly.
  final int likeCount;
  final bool isLiked;
  final bool isBookmarked;

  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onBookmarkTap;

  const DiscoverPostCard({
    super.key,
    required this.post,
    required this.likeCount,
    required this.isLiked,
    required this.isBookmarked,
    this.onTap,
    this.onLikeTap,
    this.onCommentTap,
    this.onShareTap,
    this.onBookmarkTap,
  });

  static String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
    if (diff.inHours < 24) return '${diff.inHours}sa';
    if (diff.inDays < 7) return '${diff.inDays}g';
    return '${(diff.inDays / 7).floor()}h';
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header — square avatar + username + time ──────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: EspatiColors.sageGreen,
                      borderRadius: BorderRadius.zero,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: post.authorImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: post.authorImage,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Icon(
                                Icons.pets_rounded,
                                size: 18,
                                color: Colors.black),
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.pets_rounded,
                                size: 18,
                                color: Colors.black),
                          )
                        : const Icon(Icons.pets_rounded,
                            size: 18, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          post.authorName.isEmpty
                              ? 'Pati Dostu'
                              : post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.baloo2(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          _timeAgo(post.timestamp),
                          style: GoogleFonts.nunitoSans(
                            fontSize: 11,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Image — full width, thick top/bottom border ────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                      color: Colors.black, width: 2.5),
                ),
              ),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: EspatiColors.sageGreen.withValues(alpha: 0.25),
                    child: const Icon(Icons.pets_rounded,
                        size: 40, color: Colors.black),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: EspatiColors.sageGreen.withValues(alpha: 0.25),
                    child: const Icon(Icons.pets_rounded,
                        size: 40, color: Colors.black),
                  ),
                ),
              ),
            ),

            // ── Action row — Paw / Comment / Share (left), Save (right) ────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: Row(
                children: [
                  _DiscoverActionIcon(
                    icon: isLiked ? Icons.pets_rounded : Icons.pets_outlined,
                    active: isLiked,
                    semanticLabel: isLiked ? 'Patiyi geri al' : 'Pati at',
                    onTap: onLikeTap,
                  ),
                  const SizedBox(width: 8),
                  _DiscoverActionIcon(
                    icon: Icons.chat_bubble_outline_rounded,
                    semanticLabel: 'Yorumlar',
                    onTap: onCommentTap,
                  ),
                  const SizedBox(width: 8),
                  _DiscoverActionIcon(
                    icon: Icons.send_rounded,
                    semanticLabel: 'Paylaş',
                    onTap: onShareTap,
                  ),
                  const Spacer(),
                  _DiscoverActionIcon(
                    icon: isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    active: isBookmarked,
                    semanticLabel: isBookmarked ? 'Kaydedildi' : 'Kaydet',
                    onTap: onBookmarkTap,
                  ),
                ],
              ),
            ),

            // ── Footer — like count + caption ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$likeCount Pati',
                    style: GoogleFonts.baloo2(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  if (post.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      post.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION ICON — small, subtle square block (thin border, no shadow) rather
// than a heavy hard-shadow button, per the task's "subtle" instruction.
// Active state (Pati liked / bookmarked) turns terracotta.
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoverActionIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String semanticLabel;
  final VoidCallback? onTap;

  const _DiscoverActionIcon({
    required this.icon,
    required this.semanticLabel,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? EspatiColors.terracotta : Colors.black;

    return NeoBrutalistButton(
      semanticLabel: semanticLabel,
      onPressed: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
