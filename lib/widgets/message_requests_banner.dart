import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart' show EspatiColors;
import '../widgets/common/neo_brutalist_button.dart';

/// Neo-Brutalist "Gelen İstekler" (Message Requests) banner (Design System
/// Step 70) — a horizontal blocky button pinned just below InboxScreen's
/// search bar, routing to [MessageRequestsScreen].
///
/// [requestCount] is a plain param, not read from a ViewModel here — see
/// the InboxScreen call site for why it's a mock value today (no
/// pending/known-sender concept exists in [ChatRoomModel]/[IChatRepository]
/// yet).
class MessageRequestsBanner extends StatelessWidget {
  final int requestCount;
  final VoidCallback onTap;

  const MessageRequestsBanner({
    super.key,
    required this.requestCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      semanticLabel: 'Gelen İstekler, $requestCount istek',
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.fromBorderSide(
            BorderSide(color: Colors.black, width: 2.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.mail_lock_rounded,
                size: 20, color: Colors.black),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gelen İstekler',
                style: GoogleFonts.baloo2(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
            if (requestCount > 0) ...[
              Container(
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: EspatiColors.terracotta,
                  borderRadius: BorderRadius.zero,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: Text(
                  requestCount > 99 ? '99+' : '$requestCount',
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded,
                color: Colors.black),
          ],
        ),
      ),
    );
  }
}
