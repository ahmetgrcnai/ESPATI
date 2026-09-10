import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart' show EspatiColors;
import '../widgets/common/neo_brutalist_button.dart';

/// Neo-Brutalist message-request row (Design System Step 70) — square
/// avatar + username + snippet on top, Accept/Decline action row below.
/// Decoupled (same pattern as [InboxChatTile]/[UserSearchTile]): plain
/// params, no backend model dependency.
class RequestChatTile extends StatelessWidget {
  final String avatarUrl;
  final String username;
  final String messageSnippet;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const RequestChatTile({
    super.key,
    required this.avatarUrl,
    required this.username,
    required this.messageSnippet,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Avatar + username + snippet ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: EspatiColors.sageGreen,
                  borderRadius: BorderRadius.zero,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(Icons.pets_rounded,
                            color: Colors.black, size: 22),
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.pets_rounded,
                            color: Colors.black,
                            size: 22),
                      )
                    : const Icon(Icons.pets_rounded,
                        color: Colors.black, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.baloo2(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      messageSnippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Accept / Decline ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              NeoBrutalistButton(
                semanticLabel: 'Sil — $username',
                onPressed: onDecline,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  child: Text(
                    'Sil',
                    style: GoogleFonts.nunitoSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              NeoBrutalistButton(
                semanticLabel: 'Kabul Et — $username',
                onPressed: onAccept,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: const BoxDecoration(
                    color: EspatiColors.sageGreen,
                    borderRadius: BorderRadius.zero,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.black, width: 2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    'Kabul Et',
                    style: GoogleFonts.nunitoSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
