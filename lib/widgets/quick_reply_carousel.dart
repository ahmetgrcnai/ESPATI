import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart' show EspatiColors;
import 'common/neo_brutalist_button.dart';

/// Neo-Brutalist quick-reply chip row (Design System Step 71) — sits above
/// [ChatInputField], one canned reply per tap. Only meaningful while a chat
/// has ad context and no message has been sent yet — [ChatScreen] owns that
/// visibility logic; this widget just renders whatever [replies] it's
/// given.
class QuickReplyCarousel extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onSelect;

  static const List<String> defaultReplies = [
    'İlan hala güncel mi?',
    'Sahiplenmek istiyorum',
    'Fotoğraf gönderebilir misiniz?',
    'Nerede buluşabiliriz?',
  ];

  const QuickReplyCarousel({
    super.key,
    this.replies = defaultReplies,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = replies[index];
          return _QuickReplyChip(
            label: reply,
            onTap: () => onSelect(reply),
          );
        },
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickReplyChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      semanticLabel: label,
      onPressed: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
