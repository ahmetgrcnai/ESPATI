import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/pati_video_model.dart';
import '../../services/paties_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common/neo_brutalist_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PATIES VIEWER SCREEN — TikTok-style vertical video feed (Phase 6 Step 15,
// "Summit B"; Neo-Brutalist action column + info banner added Step 47;
// lookahead preloading + self-healing cleanup added Step 49)
//
// Real Firebase backend: subscribes to [PatiesService.watchPatiesFeed] and
// renders a vertical [PageView.builder]. Unlike the original per-page
// ownership model, [VideoPlayerController]s are now owned centrally by this
// screen's State, keyed by [PatiVideoModel.id] — see "PRELOADING" below for
// why.
//
// Step 47 note: this *is* the screen the "PatiesFeedScreen" brief asked
// for — [MainScreen] already wires it to the Paties tab against the real
// [PatiesService] feed, not dummy data.
//
// No like/comment/share backend exists yet — no field on [PatiVideoModel],
// no method on [PatiesService]. "Pati" (like) is therefore local UI state
// only (same honest pattern as the Story viewer's reaction button, Design
// System Step 46); Comment/Share are stubbed with a "yakında" (coming soon)
// snack.
//
// ── PRELOADING (Step 49) ─────────────────────────────────────────────────────
// Previously each page created and started initializing its own
// [VideoPlayerController] only once [PageView.builder] built that page —
// i.e. only as the user was already swiping to it, so the network fetch +
// decoder start-up happened cold, right when the user wanted to watch. This
// screen now keeps a controller warm for the current video *and* the next
// one at all times (see [_syncPreloadWindow]), so by the time a swipe
// lands, the next video's controller has usually already had a moment to
// buffer. Only [current, current+1] are kept — not the previous page — so a
// video being removed mid-viewing (see self-healing below) can never shift
// which video is showing on the page the user is currently looking at (see
// the file-level note in [_syncPreloadWindow]).
//
// ── SELF-HEALING CLEANUP (Step 49) ──────────────────────────────────────────
// A video whose controller fails [VideoPlayerController.initialize] (bad
// codec, HDR/HEVC the device can't decode, a partially-failed upload) used
// to just sit in the feed forever showing "Video oynatılamadı" to every
// future viewer. One retry (guarding against a transient network blip)
// still failing is treated as confirmed-broken: [PatiesService.deleteVideo]
// removes it, and the live Firestore listener drops it from [_videos] for
// every viewer, not just this device.
//
// ── TAB VISIBILITY ──────────────────────────────────────────────────────────
// [MainScreen] keeps this tab alive in an [IndexedStack] — Flutter's
// IndexedStack does NOT pause offstage children automatically, so without
// help the active video would keep playing (audio included) after the user
// switches to another bottom-nav tab. [MainScreen] passes [isTabActive] —
// true only while Paties is the selected tab.
// ─────────────────────────────────────────────────────────────────────────────

class PatiesViewerScreen extends StatefulWidget {
  final bool isTabActive;

  const PatiesViewerScreen({super.key, this.isTabActive = true});

  @override
  State<PatiesViewerScreen> createState() => _PatiesViewerScreenState();
}

class _PatiesViewerScreenState extends State<PatiesViewerScreen> {
  final PageController _pageController = PageController();
  StreamSubscription<List<PatiVideoModel>>? _feedSub;

  List<PatiVideoModel> _videos = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;

  /// Video ids "Pati"-liked this session — local UI state only, see file
  /// header (no like field on [PatiVideoModel] / method on [PatiesService]
  /// yet).
  final Set<String> _likedVideoIds = {};

  /// Controllers kept warm for [current, current+1], keyed by video id —
  /// see "PRELOADING" in the file header.
  final Map<String, VideoPlayerController> _controllers = {};
  final Set<String> _initializedIds = {};
  final Set<String> _failedIds = {};

  /// Ids already handed to [PatiesService.deleteVideo] — guards against
  /// re-triggering a delete for the same id if it's still in [_videos] (the
  /// stream hasn't caught up yet) when the preload window re-scans it.
  final Set<String> _deletingIds = {};

  /// The id whose controller is currently the "should be playing" one, per
  /// [_currentIndex] + [widget.isTabActive]. Tracked so play/pause is only
  /// ever driven by an actual transition — see [_recomputeActiveId] — never
  /// by an unrelated rebuild, which would otherwise fight a user's manual
  /// pause tap.
  String? _activeId;

  void _toggleLike(String videoId) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (!_likedVideoIds.remove(videoId)) _likedVideoIds.add(videoId);
    });
  }

  /// Own-video delete (Step 50): a "Sil" action block only the uploader
  /// sees, guarded by a Neo-Brutalist confirm dialog (same shape as
  /// [ReminderManagerScreen]'s `_confirmDelete`) since this is a
  /// destructive, unrecoverable action. Reuses [PatiesService.deleteVideo]
  /// — the same Storage-then-Firestore cleanup the self-healing path uses.
  Future<void> _confirmAndDeleteOwnVideo(PatiVideoModel video) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(3),
                boxShadow: NeoBrutal.shadow(const Offset(4, 4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Videoyu sil',
                    style: GoogleFonts.baloo2(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bu Pati videosu kalıcı olarak silinecek. Bu işlem geri alınamaz.',
                    style: GoogleFonts.nunitoSans(
                        fontSize: 13, color: Colors.black.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: NeoBrutalistButton(
                          semanticLabel: 'İptal',
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.zero,
                              border: NeoBrutal.border(2),
                            ),
                            child: Text('İptal',
                                style: GoogleFonts.baloo2(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: NeoBrutalistButton(
                          semanticLabel: 'Sil',
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: EspatiColors.red,
                              borderRadius: BorderRadius.zero,
                              border: NeoBrutal.border(2),
                              boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
                            ),
                            child: Text('Sil',
                                style: GoogleFonts.baloo2(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await PatiesService.instance.deleteVideo(video);
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Video silindi.')));
  }

  void _showComingSoon(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action — yakında geliyor!',
            style: GoogleFonts.nunitoSans(fontSize: 13)),
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
  void initState() {
    super.initState();
    _feedSub = PatiesService.instance.watchPatiesFeed().listen(
      (videos) {
        if (!mounted) return;
        setState(() {
          _videos = videos;
          _isLoading = false;
          _error = null;
          // Clamp — a live deletion (including our own self-healing one)
          // could shrink the list below the current page index.
          if (_currentIndex >= _videos.length && _videos.isNotEmpty) {
            _currentIndex = _videos.length - 1;
          }
        });
        _syncPreloadWindow();
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Videolar yüklenemedi.';
        });
        debugPrint('[PatiesViewerScreen] watchPatiesFeed error: $e');
      },
    );
  }

  @override
  void didUpdateWidget(covariant PatiesViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTabActive != oldWidget.isTabActive) {
      _recomputeActiveId();
    }
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ── Preload window ──────────────────────────────────────────────────────

  /// Keeps exactly [current, current+1]'s controllers warm, disposing any
  /// that fell outside that window.
  ///
  /// Deliberately does *not* also preload `current - 1`: this screen relies
  /// on the live feed listener to drop a self-healed video from [_videos]
  /// (see the clamp in [initState]'s listener) rather than mutating the
  /// list itself, and a document removed from *before* the current index
  /// would shift every later index down by one — including the one the
  /// user is actively looking at — causing the visible video to jump with
  /// no swipe. A video after the current index can never do that: removing
  /// it only shifts indices that are still ahead of the user, so preloading
  /// (and thus potentially self-healing) forward only keeps the feed
  /// glitch-free.
  void _syncPreloadWindow() {
    final wanted = <String>{};
    if (_videos.isNotEmpty) {
      for (final i in [_currentIndex, _currentIndex + 1]) {
        if (i >= 0 && i < _videos.length) wanted.add(_videos[i].id);
      }
    }

    final stale = _controllers.keys.where((id) => !wanted.contains(id)).toList();
    for (final id in stale) {
      _controllers.remove(id)?.dispose();
      _initializedIds.remove(id);
      _failedIds.remove(id);
    }

    for (final id in wanted) {
      if (_controllers.containsKey(id)) continue;
      final video = _videos.firstWhere((v) => v.id == id);
      _warmUp(video);
    }

    _recomputeActiveId();
  }

  Future<void> _warmUp(PatiVideoModel video, {int attempt = 0}) async {
    if (video.videoUrl.isEmpty) {
      // A metadata document with no file to play — same as a confirmed
      // decode failure, just without needing to try first.
      if (mounted) setState(() => _failedIds.add(video.id));
      _deleteBrokenVideo(video);
      return;
    }

    final controller =
        VideoPlayerController.networkUrl(Uri.parse(video.videoUrl));
    _controllers[video.id] = controller;
    controller.setLooping(true);

    try {
      await controller.initialize();
    } catch (e) {
      debugPrint(
          '[PatiesViewerScreen] initialize failed (attempt $attempt) for ${video.id}: $e');
      if (_controllers[video.id] != controller) {
        // Preload window moved on while this attempt was in flight.
        controller.dispose();
        return;
      }
      _controllers.remove(video.id);
      await controller.dispose();

      if (attempt == 0) {
        // One retry — a transient network blip can look identical to a
        // genuinely corrupt file from here, and a video is only deleted
        // once, permanently, for every future viewer.
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted || !_videos.any((v) => v.id == video.id)) return;
        await _warmUp(video, attempt: 1);
        return;
      }

      if (mounted) setState(() => _failedIds.add(video.id));
      _deleteBrokenVideo(video);
      return;
    }

    if (!mounted || _controllers[video.id] != controller) {
      controller.dispose();
      return;
    }

    setState(() => _initializedIds.add(video.id));
    if (_activeId == video.id) controller.play();
  }

  /// Removes an id from the local warm set (self-healing delete already in
  /// flight) — [PatiesService.deleteVideo] is fire-and-forget from the
  /// UI's perspective; the feed listener picks up the removal for real.
  void _deleteBrokenVideo(PatiVideoModel video) {
    if (!_deletingIds.add(video.id)) return;
    debugPrint(
        '[PatiesViewerScreen] confirmed unplayable, removing: ${video.id}');
    PatiesService.instance.deleteVideo(video);
  }

  /// Plays the newly-current controller and pauses the previously-current
  /// one, but only on an actual transition — see [_activeId]'s doc comment
  /// for why this must never fire unconditionally.
  void _recomputeActiveId() {
    final newActiveId =
        (widget.isTabActive && _videos.isNotEmpty && _currentIndex < _videos.length)
            ? _videos[_currentIndex].id
            : null;
    if (newActiveId == _activeId) return;

    final oldId = _activeId;
    _activeId = newActiveId;
    if (oldId != null) _controllers[oldId]?.pause();
    if (newActiveId != null && _initializedIds.contains(newActiveId)) {
      _controllers[newActiveId]?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: EspatiColors.peach),
      );
    }

    if (_error != null) {
      return _StatusMessage(icon: Icons.error_outline_rounded, text: _error!);
    }

    if (_videos.isEmpty) {
      return const _StatusMessage(
        icon: Icons.play_circle_fill_rounded,
        text: 'Henüz paylaşılan bir Pati videosu yok.\nİlk videoyu sen paylaş!',
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _videos.length,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        _syncPreloadWindow();
      },
      itemBuilder: (context, index) {
        final video = _videos[index];
        final currentUserId = context.read<AuthViewModel>().currentUser?.id;
        final isOwner =
            currentUserId != null && currentUserId.isNotEmpty && currentUserId == video.authorId;
        return _PatiVideoPlayerItem(
          key: ValueKey(video.id),
          video: video,
          controller: _controllers[video.id],
          isInitialized: _initializedIds.contains(video.id),
          isFailed: _failedIds.contains(video.id),
          isLiked: _likedVideoIds.contains(video.id),
          isOwner: isOwner,
          onLike: () => _toggleLike(video.id),
          onComment: () => _showComingSoon('Yorumlar'),
          onShare: () => _showComingSoon('Paylaşım'),
          onDelete: () => _confirmAndDeleteOwnVideo(video),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS MESSAGE — loading/error/empty placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatusMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PATI VIDEO PLAYER ITEM — one full-screen page. Purely presentational as of
// Step 49: the [VideoPlayerController] is owned and kept alive by
// [_PatiesViewerScreenState] (see "PRELOADING" in the file header), so this
// widget only renders whatever state it's handed and forwards a tap to
// play/pause directly on that controller.
// ─────────────────────────────────────────────────────────────────────────────

class _PatiVideoPlayerItem extends StatelessWidget {
  final PatiVideoModel video;
  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool isFailed;
  final bool isLiked;
  final bool isOwner;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _PatiVideoPlayerItem({
    super.key,
    required this.video,
    required this.controller,
    required this.isInitialized,
    required this.isFailed,
    required this.isLiked,
    required this.isOwner,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onDelete,
  });

  void _togglePlayback() {
    final controller = this.controller;
    if (controller == null || !isInitialized) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  // Step 48 — Z-axis fix: [MainScreen] floats [EspatiBottomNavBar] as a
  // Positioned overlay (not Scaffold.bottomNavigationBar), so the bar's real
  // screen footprint is its own height *plus* the 24px margin MainScreen
  // floats it above the bottom edge — kBottomNavigationBarHeight (Flutter's
  // generic 56px constant) doesn't reflect that and was overlapping these
  // overlays. [PatiesViewerScreen]'s Scaffold also opts out of bottom
  // SafeArea (`SafeArea(bottom: false)`), so the device safe-area inset below
  // still has to be added back in here manually.
  static const double _navBarFloatMargin = 24; // MainScreen._navBarBottomMargin
  static const double _breathingRoom = 20;

  double _overlaysBottomInset(BuildContext context) =>
      EspatiBottomNavBar.height +
      _navBarFloatMargin +
      MediaQuery.of(context).padding.bottom +
      _breathingRoom;

  @override
  Widget build(BuildContext context) {
    final overlaysBottomInset = _overlaysBottomInset(context);
    final controller = this.controller;

    return GestureDetector(
      onTap: _togglePlayback,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isFailed)
              const _StatusMessage(
                icon: Icons.videocam_off_rounded,
                text: 'Video oynatılamadı.',
              )
            else if (isInitialized && controller != null)
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: EspatiColors.peach),
              ),

            // Play icon flash when paused — listens directly to the
            // controller so a manual pause/resume repaints just this icon,
            // not the whole page.
            if (isInitialized && controller != null)
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  if (value.isPlaying) return const SizedBox.shrink();
                  return const Center(
                    child: Icon(Icons.play_arrow_rounded,
                        size: 72, color: Colors.white70),
                  );
                },
              ),

            // Right action column — Pati (like) / Comment / Share. Anchored
            // 76px above the info banner (its own stacked-icon height) so
            // both overlays clear the floating bottom nav bar together.
            Positioned(
              right: 12,
              bottom: overlaysBottomInset + 76,
              child: _ActionColumn(
                isLiked: isLiked,
                isOwner: isOwner,
                onLike: onLike,
                onComment: onComment,
                onShare: onShare,
                onDelete: onDelete,
              ),
            ),

            // Author + description banner, bottom-left.
            Positioned(
              left: 16,
              right: 88,
              bottom: overlaysBottomInset,
              child: _VideoInfoBanner(video: video),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT ACTION COLUMN — Neo-Brutalist Pati/Comment/Share stack (Design
// System Step 47). Sharp square blocks, never transparent icon buttons —
// each wrapped in [NeoBrutalistButton] for the snappy scale/spring press
// feedback (Design System Step 44).
// ─────────────────────────────────────────────────────────────────────────────

class _ActionColumn extends StatelessWidget {
  final bool isLiked;
  final bool isOwner;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _ActionColumn({
    required this.isLiked,
    required this.isOwner,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionBlock(
          icon: isLiked ? Icons.pets_rounded : Icons.pets_outlined,
          label: 'Pati',
          background: isLiked ? NeoBrutal.userBubble : Colors.white,
          semanticLabel: isLiked ? 'Patiyi geri al' : 'Pati at',
          onTap: onLike,
        ),
        const SizedBox(height: 16),
        _ActionBlock(
          icon: Icons.mode_comment_rounded,
          label: 'Yorum',
          background: Colors.white,
          semanticLabel: 'Yorumlar',
          onTap: onComment,
        ),
        const SizedBox(height: 16),
        _ActionBlock(
          icon: Icons.share_rounded,
          label: 'Paylaş',
          background: Colors.white,
          semanticLabel: 'Paylaş',
          onTap: onShare,
        ),
        // Uploader-only — deleting someone else's Pati video isn't exposed
        // here at all (no moderation/report flow exists yet), only ever
        // the person who posted it.
        if (isOwner) ...[
          const SizedBox(height: 16),
          _ActionBlock(
            icon: Icons.delete_rounded,
            label: 'Sil',
            background: EspatiColors.red,
            semanticLabel: 'Videoyu sil',
            onTap: onDelete,
          ),
        ],
      ],
    );
  }
}

class _ActionBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final String semanticLabel;
  final VoidCallback onTap;

  const _ActionBlock({
    required this.icon,
    required this.label,
    required this.background,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeoBrutalistButton(
          semanticLabel: semanticLabel,
          onPressed: onTap,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.zero,
              border: NeoBrutal.border(2),
              boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
            ),
            child: Icon(icon, color: Colors.black, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunitoSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO INFO BANNER — blocky Neo-Brutalist card, bottom-anchored: peach
// background, thick dark-brown border, hard offset shadow (Design System
// Step 47) — replaces the old plain white-text-on-shadow overlay.
// ─────────────────────────────────────────────────────────────────────────────

class _VideoInfoBanner extends StatelessWidget {
  final PatiVideoModel video;

  const _VideoInfoBanner({required this.video});

  @override
  Widget build(BuildContext context) {
    final hasAuthor = video.authorName.isNotEmpty;
    if (!hasAuthor && video.description.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EspatiColors.peach,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2.5),
        boxShadow: NeoBrutal.shadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasAuthor)
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(2),
                  ),
                  child: video.authorPhoto.isNotEmpty
                      ? Image.network(video.authorPhoto, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.pets_rounded,
                              color: Colors.black, size: 16))
                      : const Icon(Icons.pets_rounded,
                          color: Colors.black, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    video.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.baloo2(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          if (video.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              video.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
