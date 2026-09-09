import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/neo_brutalist_tokens.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/request_chat_tile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE REQUESTS SCREEN ("Gelen İstekler") — Design System Step 70.
//
// Honest gap, flagged not hidden: there is no "message request" concept in
// the real chat backend today — [ChatRoomModel]/[IChatRepository] treat
// every room [getOrCreateChatRoom] returns as immediately visible in
// InboxScreen's list, with no pending/known-sender distinction. Building
// that for real needs a `status` field on the room (pending/accepted),
// server-side logic deciding who counts as "unknown", and repository
// methods to accept/decline — a backend feature on the scale of Step 55's
// "Backend Architect" framing, not this UI-scoped step.
//
// So this screen is real, working UI over a local mock request list (the
// task's own banner spec explicitly calls for "a mock count") — Accept/
// Decline are real interactions (they remove the tile and confirm via
// toast), just not yet backed by a Firestore write. [RequestChatTile]
// itself is fully decoupled and ready to be driven by real data the moment
// that backend piece exists.
// ─────────────────────────────────────────────────────────────────────────────

class MessageRequestsScreen extends StatefulWidget {
  const MessageRequestsScreen({super.key});

  @override
  State<MessageRequestsScreen> createState() => _MessageRequestsScreenState();
}

/// Local-only mock shape — not a Firestore model. See file header.
class _PendingRequest {
  final String id;
  final String avatarUrl;
  final String username;
  final String snippet;

  const _PendingRequest({
    required this.id,
    required this.avatarUrl,
    required this.username,
    required this.snippet,
  });
}

class _MessageRequestsScreenState extends State<MessageRequestsScreen> {
  // Mock seed data — matches the banner's mock "3" badge. No live Firestore
  // read backs this list yet (see file header).
  final List<_PendingRequest> _requests = const [
    _PendingRequest(
      id: 'req_1',
      avatarUrl: '',
      username: 'Ada',
      snippet: 'Merhaba! Kedini sahiplenmek istiyorum, hâlâ müsait mi?',
    ),
    _PendingRequest(
      id: 'req_2',
      avatarUrl: '',
      username: 'Kerem',
      snippet: 'Selam, ilanındaki Golden hâlâ duruyor mu?',
    ),
    _PendingRequest(
      id: 'req_3',
      avatarUrl: '',
      username: 'Zeynep',
      snippet: 'Merhaba, veteriner önerisi için yazmıştım.',
    ),
  ].toList();

  void _accept(_PendingRequest request) {
    setState(() => _requests.removeWhere((r) => r.id == request.id));
    _showToast('${request.username} kabul edildi.');
  }

  void _decline(_PendingRequest request) {
    setState(() => _requests.removeWhere((r) => r.id == request.id));
    _showToast('${request.username} silindi.');
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.white, width: 1.5),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBrutalistButton(
              semanticLabel: 'Geri',
              onPressed: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
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
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.black, size: 20),
              ),
            ),
          ),
        ),
        title: Text(
          'Gelen İstekler',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: Colors.black,
          ),
        ),
      ),
      body: _requests.isEmpty
          ? const _EmptyRequests()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                return RequestChatTile(
                  avatarUrl: request.avatarUrl,
                  username: request.username,
                  messageSnippet: request.snippet,
                  onAccept: () => _accept(request),
                  onDecline: () => _decline(request),
                );
              },
            ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mail_lock_rounded,
              size: 64, color: Colors.black),
          const SizedBox(height: 12),
          Text(
            'Bekleyen istek yok',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
