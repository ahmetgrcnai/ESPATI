import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../viewmodels/chat_thread_viewmodel.dart';
import '../../widgets/ad_context_banner.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/common/neo_brutalist_chat_bubble.dart';
import '../../widgets/quick_reply_carousel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CHAT SCREEN ("ChatDetailScreen") — 1-on-1 thread, Neo-Brutalist rebuild
// (Design System Step 39, redone Step 68 on the cream canvas, ad-context +
// quick replies redone Step 71). This *is* the real "ChatDetailScreen" the
// brief describes — reached by tapping an [InboxChatTile] (Step 67) —
// rebuilt in place rather than forked, matching every other screen this
// design pass has touched. [chatTitle] is deliberately generic (not
// "otherUserName") so this same screen shape can carry a non-user title
// like "Pati AI" if a future step ever routes an AI conversation through
// it — nothing here assumes the title names a Firestore user.
//
// Expects a [ChatThreadViewModel] to already be provided above it in the
// widget tree (screen-scoped — see the push call sites in
// [FeedDetailScreen] and [InboxScreen]).
// ─────────────────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String chatTitle;
  final String otherUserPhoto;

  /// Optional reminder banner shown just below the AppBar — e.g.
  /// "Lucy - Sahiplendirme" when this thread was opened from a listing, so
  /// both sides keep seeing which ad they're discussing. `null` hides both
  /// the banner and the quick-reply carousel — quick replies only make
  /// sense in an ad-initiated thread.
  final String? adContext;

  /// The ad's own cover photo, shown as [AdContextBanner]'s tiny square
  /// image. `null`/empty falls back to a paw icon — see
  /// [FeedDetailScreen]'s push call site for the real `listing.imageUrl`
  /// this is wired from.
  final String? adContextImageUrl;

  const ChatScreen({
    super.key,
    required this.chatTitle,
    required this.otherUserPhoto,
    this.adContext,
    this.adContextImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();

  /// Step 71 — set the instant a quick reply is tapped, so the carousel
  /// disappears immediately rather than waiting on the Firestore
  /// round-trip. Combined with `vm.messages.isEmpty` at the render site
  /// (see build()) so reopening a thread that already has history never
  /// shows quick replies either, even though this flag itself resets to
  /// false on every fresh mount.
  bool _hasSentFirstMessage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatThreadViewModel>().addListener(_onViewModelChanged);
    });
  }

  @override
  void dispose() {
    context.read<ChatThreadViewModel>().removeListener(_onViewModelChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final vm = context.read<ChatThreadViewModel>();
    if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!,
              style: GoogleFonts.nunitoSans(fontSize: 13, color: Colors.white)),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.white, width: 1.5),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ),
      );
      vm.clearError();
    }
  }

  void _send() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    context.read<ChatThreadViewModel>().sendMessage(text);
    _textController.clear();
    if (!_hasSentFirstMessage) setState(() => _hasSentFirstMessage = true);
  }

  /// Quick-reply tap — sends through the exact same real,
  /// Firestore-backed [ChatThreadViewModel.sendMessage] the input field
  /// uses (not a fake local-only splice into the message list), then hides
  /// the carousel.
  void _sendQuickReply(String text) {
    context.read<ChatThreadViewModel>().sendMessage(text);
    setState(() => _hasSentFirstMessage = true);
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
        titleSpacing: 8,
        // Step 68 — thick darkBrown bottom border separating the AppBar
        // from the chat body, instead of relying on elevation/shadow.
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2.5),
          child: ColoredBox(color: Colors.black),
        ),
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
        title: Row(
          children: [
            // Square receiver avatar — BorderRadius.zero, was circular(2).
            Container(
              width: 38,
              height: 38,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: EspatiColors.sageGreen,
                borderRadius: BorderRadius.zero,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: widget.otherUserPhoto.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.otherUserPhoto,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                          Icons.pets_rounded,
                          color: Colors.black,
                          size: 18),
                    )
                  : const Icon(Icons.pets_rounded,
                      color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.chatTitle,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.baloo2(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Ad-context banner — strictly below the AppBar ──────────────
            if (widget.adContext != null)
              AdContextBanner(
                imageUrl: widget.adContextImageUrl ?? '',
                text: widget.adContext!,
              ),

            Expanded(
              child: Consumer<ChatThreadViewModel>(
                builder: (context, vm, _) {
                  if (vm.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: EspatiColors.sageGreen),
                    );
                  }
                  if (vm.messages.isEmpty) {
                    return _EmptyThread(chatTitle: widget.chatTitle);
                  }
                  final reversed = vm.messages.reversed.toList();
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    itemCount: reversed.length,
                    itemBuilder: (context, index) {
                      final message = reversed[index];
                      return NeoBrutalistChatBubble(
                        text: message.text,
                        timestamp: message.timestamp,
                        isMine: message.isMine(vm.currentUserId),
                      );
                    },
                  );
                },
              ),
            ),

            // ── Quick replies — ad-context threads only, hidden the
            // instant a first message exists (tapped or typed) ────────────
            if (widget.adContext != null)
              Consumer<ChatThreadViewModel>(
                builder: (context, vm, _) {
                  final showQuickReplies =
                      !_hasSentFirstMessage && vm.messages.isEmpty;
                  if (!showQuickReplies) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: QuickReplyCarousel(onSelect: _sendQuickReply),
                  );
                },
              ),

            ChatInputField(
              controller: _textController,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY THREAD STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyThread extends StatelessWidget {
  final String chatTitle;
  const _EmptyThread({required this.chatTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: Colors.black),
            const SizedBox(height: 12),
            Text(
              'Henüz mesaj yok',
              style: GoogleFonts.baloo2(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$chatTitle ile sohbete başla!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT INPUT FIELD — pinned to the bottom. Blocky cream field + a square
// terracotta send block with a paw icon instead of a send arrow (Step 68 —
// brand identity: "Pati", not "Send").
// ─────────────────────────────────────────────────────────────────────────────

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatThreadViewModel>(
      builder: (context, vm, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.black, width: 2.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.nunitoSans(
                        fontSize: 14, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Mesaj yaz...',
                      hintStyle: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              NeoBrutalistButton(
                semanticLabel: 'Gönder',
                onPressed: vm.isSending ? null : onSend,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: EspatiColors.terracotta,
                    borderRadius: BorderRadius.zero,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.black, width: 2.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: vm.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : const Icon(Icons.pets_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
