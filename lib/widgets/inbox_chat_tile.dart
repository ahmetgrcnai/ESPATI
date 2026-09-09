import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart' show EspatiColors;

/// Neo-Brutalist DM inbox row (Design System Step 67) — a blocky, distinct
/// tile per chat instead of a standard Material `ListTile` + soft divider.
///
/// Decoupled from [ChatRoomModel] (same pattern as [ProfileItemCard]/
/// [AdListCard]/[DiscoverPostCard]): plain params, no ViewModel reads baked
/// in, so the caller owns exactly what "unread" means for its data source.
class InboxChatTile extends StatelessWidget {
  final String avatarUrl;
  final String username;
  final String messageSnippet;
  final String timeLabel;
  final bool isUnread;

  /// Shown in the terracotta badge — only rendered when [isUnread] is true
  /// and this is greater than 0.
  final int unreadCount;

  final VoidCallback? onTap;

  const InboxChatTile({
    super.key,
    required this.avatarUrl,
    required this.username,
    required this.messageSnippet,
    required this.timeLabel,
    required this.isUnread,
    this.unreadCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Unread: hard sageGreen shadow, thicker border. Read: flat darkBrown
    // border only, no shadow, muted time text — a visibly "settled" state
    // rather than the same pop every tile would get otherwise.
    final shadowColor = isUnread ? EspatiColors.sageGreen : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: Colors.black,
            width: isUnread ? 2.5 : 2,
          ),
          boxShadow: shadowColor == null
              ? null
              : [
                  BoxShadow(
                    color: shadowColor,
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Avatar — square, separated by a right border ──────────────
            Container(
              width: 64,
              decoration: const BoxDecoration(
                color: EspatiColors.sageGreen,
                border: Border(
                  right:
                      BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(Icons.pets_rounded,
                          color: Colors.black, size: 26),
                      errorWidget: (_, __, ___) => const Icon(
                          Icons.pets_rounded,
                          color: Colors.black,
                          size: 26),
                    )
                  : const Icon(Icons.pets_rounded,
                      color: Colors.black, size: 26),
            ),

            // ── Content — username + snippet ────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      messageSnippet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.black
                            .withValues(alpha: isUnread ? 0.85 : 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Time + unread badge ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                      color: Colors.black
                          .withValues(alpha: isUnread ? 0.8 : 0.45),
                    ),
                  ),
                  if (isUnread && unreadCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      constraints:
                          const BoxConstraints(minWidth: 22, minHeight: 22),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: EspatiColors.terracotta,
                        borderRadius: BorderRadius.zero,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.white,
                        ),
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
