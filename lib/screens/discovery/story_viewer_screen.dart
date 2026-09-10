import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/common/story_tray.dart' show StoryTrayItem;

// ─────────────────────────────────────────────────────────────────────────────
// STORY VIEWER SCREEN (Design System Step 37)
//
// Full-screen Instagram-style story viewer, pushed by [StoryTray.onStoryTap]
// in [AlgorithmicFeedScreen]. Takes the exact same flat [StoryTrayItem] list
// the tray itself renders (not a re-fetch) — [StoryModel] has no
// denormalized author name/photo yet, so [StoryTrayItem.imageUrl] is
// reused for both the header avatar thumbnail and the full-bleed story
// content here, same convention the tray already established, not a new
// gap introduced by this screen.
//
// Each list entry is one flat story (today's data model has no multi-image
// "session per user" grouping), so left/right tap simply steps through
// [stories] in order — advancing past the last one, or tapping back past
// the first, both just close/hold rather than crossing into another user's
// stories, since there's no such grouping to cross into yet.
// ─────────────────────────────────────────────────────────────────────────────

class StoryViewerScreen extends StatefulWidget {
  final List<StoryTrayItem> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _storyDuration = Duration(seconds: 5);

  late int _currentIndex;
  late final AnimationController _progress;
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();

  /// Story ids the viewer has "Pati"-reacted to this session — local UI
  /// state only. No reaction pipeline exists yet (no `IStoryRepository`,
  /// no reaction field on [StoryModel]), same gap [_sendReply] already
  /// notes for replies; this is the frictionless front end for whichever
  /// backend lands first.
  final Set<String> _likedStoryIds = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.stories.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.stories.length - 1);
    _progress = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener(_onProgressStatus);
    if (widget.stories.isEmpty) {
      // Defensive only — [StoryTray.onStoryTap] can't fire this with an
      // empty list in practice (the tap always comes from an actually
      // rendered story bubble), but don't leave a blank black screen if it
      // ever does.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      _progress.forward();
    }
    _replyFocusNode.addListener(_onReplyFocusChanged);
  }

  @override
  void dispose() {
    _progress.dispose();
    _replyController.dispose();
    _replyFocusNode.removeListener(_onReplyFocusChanged);
    _replyFocusNode.dispose();
    super.dispose();
  }

  // Auto-advance must not keep racing underneath the user while they're
  // typing a reply — pause on focus, resume (from wherever it left off)
  // once they defocus.
  void _onReplyFocusChanged() {
    if (_replyFocusNode.hasFocus) {
      _progress.stop();
    } else {
      _progress.forward();
    }
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _goToNext();
  }

  void _goToNext() {
    if (_currentIndex >= widget.stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _currentIndex++);
    _progress
      ..reset()
      ..forward();
  }

  void _goToPrevious() {
    if (_currentIndex == 0) {
      // Nothing before the first story — restart it rather than no-op, so
      // the tap still reads as "did something".
      _progress
        ..reset()
        ..forward();
      return;
    }
    setState(() => _currentIndex--);
    _progress
      ..reset()
      ..forward();
  }

  void _handleTap(TapUpDetails details, double width) {
    // A tap while replying just dismisses the keyboard first — it
    // shouldn't also skip a story out from under the user.
    if (_replyFocusNode.hasFocus) {
      _replyFocusNode.unfocus();
      return;
    }
    if (details.localPosition.dx < width * 0.3) {
      _goToPrevious();
    } else {
      _goToNext();
    }
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    // TODO: wire to the real chat/DM pipeline (IChatRepository) once a
    // story carries its author's userId through to this screen — out of
    // scope for this step, which is just the viewer UI + tap navigation.
    debugPrint('[StoryViewerScreen] reply (not yet sent): "$text"');
    HapticFeedback.lightImpact();
    _replyController.clear();
    _replyFocusNode.unfocus();
  }

  void _reactToStory(String storyId) {
    // TODO: wire to a real reaction pipeline once one exists — see
    // [_likedStoryIds]'s doc comment.
    debugPrint('[StoryViewerScreen] reaction (not yet persisted): $storyId');
    HapticFeedback.mediumImpact();
    setState(() {
      if (!_likedStoryIds.remove(storyId)) _likedStoryIds.add(storyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Story content ──
              if (story.imageUrl.isNotEmpty)
                CachedNetworkImage(
                  key: ValueKey(story.id),
                  imageUrl: story.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: Colors.black),
                )
              else
                const ColoredBox(color: Colors.black),

              // ── Tap navigation — left 30% previous, right 70% next ──
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    _handleTap(details, constraints.maxWidth),
              ),

              // ── Progress bar + header ──
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                      child: _StoryProgressBar(
                        count: widget.stories.length,
                        currentIndex: _currentIndex,
                        progress: _progress,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Row(
                        children: [
                          _HeaderAvatar(imageUrl: story.imageUrl),
                          const SizedBox(width: 10),
                          Flexible(child: _UsernameBadge(label: story.label)),
                          const Spacer(),
                          _CloseButton(
                              onTap: () => Navigator.of(context).pop()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Reply bar ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: _ReplyBar(
                      controller: _replyController,
                      focusNode: _replyFocusNode,
                      onSend: _sendReply,
                      isLiked: _likedStoryIds.contains(story.id),
                      onReact: () => _reactToStory(story.id),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS BAR — sharp, blocky segments; mintGreen fill over a translucent
// white track, each segment outlined in a thin dark-brown border.
// ─────────────────────────────────────────────────────────────────────────────

class _StoryProgressBar extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Animation<double> progress;

  const _StoryProgressBar({
    required this.count,
    required this.currentIndex,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 5,
      child: Row(
        children: List.generate(count, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == count - 1 ? 0 : 4),
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) {
                  final fraction = i < currentIndex
                      ? 1.0
                      : i == currentIndex
                          ? progress.value
                          : 0.0;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.zero,
                      border:
                          Border.all(color: Colors.black, width: 1),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction,
                      child: Container(color: EspatiColors.mintGreen),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER — sharp square avatar + cream username badge
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderAvatar extends StatelessWidget {
  final String imageUrl;

  const _HeaderAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.black, width: 2.5),
      ),
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const Icon(Icons.pets_rounded,
                  color: Colors.black, size: 18),
            )
          : const Icon(Icons.pets_rounded,
              color: Colors.black, size: 18),
    );
  }
}

class _UsernameBadge extends StatelessWidget {
  final String label;

  const _UsernameBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.fromBorderSide(
          BorderSide(color: Colors.black, width: 1.5),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.baloo2(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: const Icon(Icons.close_rounded,
            size: 18, color: Colors.black),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPLY BAR — blocky cream input + blocky mintGreen send block
// ─────────────────────────────────────────────────────────────────────────────

class _ReplyBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isLiked;
  final VoidCallback onReact;

  const _ReplyBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isLiked,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              style:
                  GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Yanıtla...',
                hintStyle: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
                filled: false,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ── "Pati" reaction — frictionless like, no keyboard needed ──────
        NeoBrutalistButton(
          semanticLabel: isLiked ? 'Patiyi geri al' : 'Pati at',
          onPressed: onReact,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: EspatiColors.peach,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              isLiked ? Icons.pets_rounded : Icons.pets_outlined,
              color: Colors.black,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),

        NeoBrutalistButton(
          semanticLabel: 'Gönder',
          onPressed: onSend,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: EspatiColors.mintGreen,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.send_rounded,
                color: Colors.black, size: 22),
          ),
        ),
      ],
    );
  }
}
