import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/chat_message.dart';
import '../../viewmodels/ai_vet_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PATİ AI CHAT BODY (Design System Step 45)
//
// The Pati-AI chat surface itself, embedded directly as [AiVetScreen]'s
// first tab — that screen owns the Scaffold/AppBar. Wired live to
// [AIVetViewModel] (registered app-wide in service_locator.dart, not
// screen-scoped — no provider setup needed at the call site): real Claude
// API calls, image-based triage, conversation history all come for free,
// nothing here is mocked.
//
// A standalone "face" for this chat (its own Scaffold/AppBar, for pushing
// as an independent route) used to live in this file as `PatiAiScreen` —
// removed (along with its private `_PatiAiAppBar`) as confirmed dead code:
// it was never wired into navigation (no entry point ever pushed it; the
// only real entry point, DraggableAIFab, has only ever pushed AiVetScreen).
// ─────────────────────────────────────────────────────────────────────────────

/// The chat itself — message list, empty state, and input bar — with no
/// Scaffold/AppBar of its own, so it can also be embedded directly as a
/// [AiVetScreen] tab body without a duplicate nested app bar.
///
/// Wired live to [AIVetViewModel] (registered app-wide in
/// service_locator.dart, not screen-scoped — no provider setup needed at
/// the call site): real Claude API calls, image-based triage, conversation
/// history all come for free, nothing here is mocked.
class PatiAiChatBody extends StatefulWidget {
  const PatiAiChatBody({super.key});

  @override
  State<PatiAiChatBody> createState() => _PatiAiChatBodyState();
}

class _PatiAiChatBodyState extends State<PatiAiChatBody> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  int _prevMessageCount = 0;
  bool _prevIsProcessing = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _textController.text.trim();
    final vm = context.read<AIVetViewModel>();
    if (text.isEmpty && !vm.hasPendingImage) return;
    _textController.clear();
    vm.sendMessage(text);
  }

  Future<void> _pickImage() async {
    final vm = context.read<AIVetViewModel>();
    if (vm.isProcessing) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1440,
    );
    if (picked != null && mounted) {
      await context.read<AIVetViewModel>().setPendingImage(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Consumer<AIVetViewModel>(
          builder: (context, vm, _) {
            final contentChanged = vm.messages.length != _prevMessageCount ||
                vm.isProcessing != _prevIsProcessing;
            if (contentChanged) {
              _prevMessageCount = vm.messages.length;
              _prevIsProcessing = vm.isProcessing;
              _scrollToBottom();
            }

            if (vm.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(vm.errorMessage!,
                          style: GoogleFonts.nunitoSans(fontSize: 13)),
                      backgroundColor: EspatiColors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(
                            color: Colors.black, width: 2),
                      ),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    ),
                  );
                vm.clearError();
              });
            }

            // Only the local 'welcome' greeting is present — no real turn
            // has happened yet. Swap the message list for the big-avatar +
            // prompt-bricks empty state instead of showing that greeting as
            // an ordinary bubble.
            final showEmptyState =
                vm.messages.length <= 1 && !vm.isProcessing;

            return Column(
              children: [
                Expanded(
                  child: showEmptyState
                      ? _PatiAiEmptyState(
                          onSuggestionTap: (prompt) => context
                              .read<AIVetViewModel>()
                              .sendMessage(prompt),
                          onPickImage: _pickImage,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                          itemCount:
                              vm.messages.length + (vm.isProcessing ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == vm.messages.length) {
                              return const _TypingBubble();
                            }
                            return _PatiAIChatBubble(
                                message: vm.messages[index]);
                          },
                        ),
                ),
                if (vm.hasPendingImage && vm.pendingImageBytes != null)
                  _PendingImageStrip(
                    imageBytes: vm.pendingImageBytes!,
                    onRemove: vm.clearPendingImage,
                  ),
                _AIBottomInput(
                  controller: _textController,
                  hasPendingImage: vm.hasPendingImage,
                  isProcessing: vm.isProcessing,
                  onSend: _send,
                  onPickImage: _pickImage,
                ),
              ],
            );
          },
        ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE — shown before the user's first real turn (only the local
// 'welcome' message exists yet): a centered square AI avatar plus a
// horizontal row of tappable "Prompt Bricks". Text prompts fire straight
// into [AIVetViewModel.sendMessage]; the photo prompt hands off to the
// existing image picker instead.
// ─────────────────────────────────────────────────────────────────────────────

class _PromptSuggestion {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PromptSuggestion({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _PatiAiEmptyState extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onPickImage;

  const _PatiAiEmptyState({
    required this.onSuggestionTap,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = <_PromptSuggestion>[
      _PromptSuggestion(
        label: 'Fotoğraf Analiz Et',
        icon: Icons.camera_alt_rounded,
        onTap: onPickImage,
      ),
      _PromptSuggestion(
        label: 'Zehirli Bitki mi?',
        icon: Icons.local_florist_rounded,
        onTap: () => onSuggestionTap(
            'Evimdeki şu bitki patim için zehirli mi olabilir? Nelere '
            'dikkat etmeliyim?'),
      ),
      _PromptSuggestion(
        label: 'Beslenme Önerisi',
        icon: Icons.restaurant_rounded,
        onTap: () => onSuggestionTap(
            'Patim için dengeli bir beslenme programı önerir misin?'),
      ),
      _PromptSuggestion(
        label: 'Aşı Takvimi',
        icon: Icons.vaccines_rounded,
        onTap: () =>
            onSuggestionTap('Patim için aşı takvimi nasıl olmalı?'),
      ),
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: EspatiColors.peach,
                borderRadius: BorderRadius.zero,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.black, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              "Pati AI'ya Merhaba De!",
              textAlign: TextAlign.center,
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Patin hakkında bir soru sor ya da bir fotoğraf yükle.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final s = suggestions[index];
                  return NeoBrutalistButton(
                    onPressed: s.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: EspatiColors.sageGreen,
                        borderRadius: BorderRadius.zero,
                        border: Border.fromBorderSide(
                          BorderSide(
                              color: Colors.black, width: 2.5),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s.icon,
                              size: 16, color: Colors.black),
                          const SizedBox(width: 6),
                          Text(
                            s.label,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE ROUTER
// ─────────────────────────────────────────────────────────────────────────────

class _PatiAIChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _PatiAIChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return message.isUser
        ? _UserBubble(message: message)
        : _AiBubble(message: message);
  }
}

const double _kBubbleMaxWidthFactor = 0.78;
const BorderSide _kBubbleBorderSide =
    BorderSide(color: Colors.black, width: NeoBrutal.borderWidth);
const List<BoxShadow> _kBubbleShadow = [
  BoxShadow(
      color: Colors.black,
      offset: Offset(4, 4),
      blurRadius: 0,
      spreadRadius: 0),
];

// ── User bubble — terracotta, right-aligned, image thumbnail if present ───

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final maxWidth =
        MediaQuery.of(context).size.width * _kBubbleMaxWidthFactor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: const BoxDecoration(
                  color: NeoBrutal.userBubble,
                  borderRadius: BorderRadius.zero,
                  border: Border.fromBorderSide(_kBubbleBorderSide),
                  boxShadow: _kBubbleShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Text(
                        'Sen',
                        style: GoogleFonts.baloo2(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    if (message.imageBytes != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border.fromBorderSide(
                              BorderSide(
                                  color: Colors.black, width: 2),
                            ),
                          ),
                          child: Image.memory(
                            message.imageBytes!,
                            width: maxWidth - 24,
                            height: 160,
                            fit: BoxFit.cover,
                            cacheWidth: 600,
                          ),
                        ),
                      ),
                    if (message.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Text(
                          message.text,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            color: Colors.black,
                            height: 1.45,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 10),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.nunitoSans(
                  fontSize: 10,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── AI bubble — sageGreen, left-aligned, markdown body ─────────────────────

class _AiBubble extends StatelessWidget {
  final ChatMessage message;
  const _AiBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final maxWidth =
        MediaQuery.of(context).size.width * _kBubbleMaxWidthFactor;
    const textColor = Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AiAvatar(),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: const BoxDecoration(
                  color: NeoBrutal.aiSurface,
                  borderRadius: BorderRadius.zero,
                  border: Border.fromBorderSide(_kBubbleBorderSide),
                  boxShadow: _kBubbleShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pati AI',
                      style: GoogleFonts.baloo2(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 4),
                    MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.nunitoSans(
                            fontSize: 14, color: textColor, height: 1.5),
                        h2: GoogleFonts.nunitoSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor),
                        h3: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: textColor),
                        strong: GoogleFonts.nunitoSans(
                            fontWeight: FontWeight.w700, color: textColor),
                        em: GoogleFonts.nunitoSans(
                            fontStyle: FontStyle.italic, color: textColor),
                        listBullet: GoogleFonts.nunitoSans(
                            fontSize: 14, color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.nunitoSans(
                  fontSize: 10,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.fromBorderSide(
          BorderSide(color: Colors.black, width: 2),
        ),
      ),
      child: const Icon(Icons.smart_toy_rounded,
          color: Colors.black, size: 16),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPING INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AiAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: NeoBrutal.aiSurface,
              borderRadius: BorderRadius.zero,
              border: Border.fromBorderSide(_kBubbleBorderSide),
              boxShadow: _kBubbleShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Pati AI düşünüyor...',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PENDING IMAGE PREVIEW STRIP — shown above the input bar once an image is
// picked but not yet sent.
// ─────────────────────────────────────────────────────────────────────────────

class _PendingImageStrip extends StatelessWidget {
  final Uint8List imageBytes;
  final VoidCallback onRemove;

  const _PendingImageStrip({required this.imageBytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NeoBrutal.scaffoldBg,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: Image.memory(imageBytes,
                    width: 56, height: 56, fit: BoxFit.cover),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Semantics(
                    button: true,
                    label: 'Fotoğrafı kaldır',
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: EspatiColors.red,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fotoğraf eklendi — soru sorup gönderebilirsin.',
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INPUT BAR — square camera button, sharp text field, mechanical-press send
// block ([_MechanicalPressButton], below).
// ─────────────────────────────────────────────────────────────────────────────

class _AIBottomInput extends StatelessWidget {
  final TextEditingController controller;
  final bool hasPendingImage;
  final bool isProcessing;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  const _AIBottomInput({
    required this.controller,
    required this.hasPendingImage,
    required this.isProcessing,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NeoBrutal.scaffoldBg,
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Camera button — mechanical press ──────────────────────────────
          _MechanicalPressButton(
            semanticLabel: 'Fotoğraf ekle',
            onPressed: isProcessing ? null : onPickImage,
            background: hasPendingImage ? EspatiColors.lightBlue : Colors.white,
            icon: Icon(
              Icons.camera_alt_rounded,
              color: isProcessing
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),

          // ── Sharp rectangular text field ─────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(),
                boxShadow: NeoBrutal.shadow(),
              ),
              child: TextField(
                controller: controller,
                enabled: !isProcessing,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.nunitoSans(
                    fontSize: 14, color: Colors.black),
                decoration: InputDecoration(
                  hintText: hasPendingImage
                      ? 'Fotoğraf hakkında soru sor...'
                      : 'Bir soru sor...',
                  hintStyle: GoogleFonts.nunitoSans(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // ── Send button — mechanical press ────────────────────────────────
          _MechanicalPressButton(
            semanticLabel: 'Gönder',
            onPressed: isProcessing ? null : onSend,
            background: isProcessing
                ? NeoBrutal.userBubble.withValues(alpha: 0.5)
                : NeoBrutal.userBubble,
            icon: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded,
                    color: Colors.black, size: 22),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MECHANICAL-PRESS BUTTON — used by the camera and send controls above. On
// tap down, the shadow collapses to Offset.zero and the button translates
// down by the resting shadow offset, so it visually "presses into" the
// page; springs back on release. Local to this screen — does not touch the
// shared NeoBrutalistButton widget used elsewhere in the app.
// ─────────────────────────────────────────────────────────────────────────────

class _MechanicalPressButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String semanticLabel;
  final Color background;
  final Widget icon;

  const _MechanicalPressButton({
    required this.onPressed,
    required this.semanticLabel,
    required this.background,
    required this.icon,
  });

  @override
  State<_MechanicalPressButton> createState() =>
      _MechanicalPressButtonState();
}

class _MechanicalPressButtonState extends State<_MechanicalPressButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onPressed == null;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: !disabled,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
            _isPressed ? 4 : 0,
            _isPressed ? 4 : 0,
            0,
          ),
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.zero,
            border: NeoBrutal.border(),
            boxShadow: _isPressed ? const [] : NeoBrutal.shadow(),
          ),
          child: widget.icon,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UTILITIES
// ─────────────────────────────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
