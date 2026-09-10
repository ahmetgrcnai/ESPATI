import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart' show EspatiColors;
import '../widgets/common/neo_brutalist_button.dart';

/// Neo-Brutalist user search result row (Design System Step 69) — square
/// avatar, bold username, and a "Mesaj At" CTA block. Decoupled from
/// [UserModel] (same pattern as [InboxChatTile]/[DiscoverPostCard]): plain
/// params, no ViewModel reads baked in.
class UserSearchTile extends StatelessWidget {
  final String avatarUrl;
  final String username;
  final VoidCallback onMessageTap;

  const UserSearchTile({
    super.key,
    required this.avatarUrl,
    required this.username,
    required this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.fromBorderSide(
          BorderSide(color: Colors.black, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Avatar — square, separated by a right border ──────────────
          Container(
            width: 56,
            decoration: const BoxDecoration(
              color: EspatiColors.sageGreen,
              border: Border(
                right: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Icon(Icons.pets_rounded,
                        color: Colors.black, size: 24),
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.pets_rounded,
                        color: Colors.black,
                        size: 24),
                  )
                : const Icon(Icons.pets_rounded,
                    color: Colors.black, size: 24),
          ),

          // ── Username ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),

          // ── "Mesaj At" CTA ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(8),
            child: NeoBrutalistButton(
              semanticLabel: 'Mesaj At — $username',
              onPressed: onMessageTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: EspatiColors.sageGreen,
                  borderRadius: BorderRadius.zero,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: Text(
                  'Mesaj At',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
