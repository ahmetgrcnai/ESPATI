import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

/// A single Neo-Brutalist chat message bubble (Design System Step 39,
/// rebuilt Step 68) — sharp rectangles (BorderRadius.zero, was a near-zero
/// but not literal circular(2)), thick dark-brown border, hard offset
/// shadow. Mine (terracotta/cream) and Theirs (sageGreen/darkBrown) are now
/// two genuinely distinct fills, not the previous mintGreen-vs-peach pair.
///
/// Deliberately takes plain [text]/[timestamp]/[isMine] rather than a
/// Firestore-shaped `MessageModel`, so it stays reusable for any future
/// message source with a different backend shape — [ChatScreen] adapts its
/// real `MessageModel`s onto this shape rather than this widget depending
/// on that model.
class NeoBrutalistChatBubble extends StatelessWidget {
  final String text;
  final DateTime timestamp;
  final bool isMine;

  const NeoBrutalistChatBubble({
    super.key,
    required this.text,
    required this.timestamp,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        isMine ? EspatiColors.terracotta : EspatiColors.sageGreen;
    final textColor = isMine ? Colors.white : Colors.black;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
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
            Text(
              text,
              style: GoogleFonts.poppins(fontSize: 14, color: textColor),
            ),
            const SizedBox(height: 3),
            Text(
              _formatTime(timestamp),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
