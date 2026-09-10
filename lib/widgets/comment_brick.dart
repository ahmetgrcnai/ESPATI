import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart' show EspatiColors;

/// Neo-Brutalist comment row (Design System Step 73) — flat, no border-all/
/// shadow like a card; just a 4px colored left border on a plain cream
/// block, so a long comment thread doesn't turn into a wall of competing
/// bordered boxes. Alternating terracotta/sageGreen accents (by [accent])
/// keep consecutive comments visually distinct without needing avatars.
class CommentBrick extends StatelessWidget {
  final String authorName;
  final String text;
  final String timeAgo;
  final Color accent;

  const CommentBrick({
    super.key,
    required this.authorName,
    required this.text,
    required this.timeAgo,
    this.accent = EspatiColors.terracotta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                timeAgo,
                style: GoogleFonts.nunitoSans(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.nunitoSans(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
