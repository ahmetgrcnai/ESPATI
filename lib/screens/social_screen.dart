import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/sample_data.dart';
import '../viewmodels/social_viewmodel.dart';
import '../widgets/story_circle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SOCIAL SCREEN — Petzbe-inspired feed with Pati (Like) & Yorum (Comment)
//
// Brand language:
//   "Pati"  — the like/reaction button (paw stamp animation)
//   "Yorum" — the comment button (elastic bounce animation)
// ─────────────────────────────────────────────────────────────────────────────

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor =
        isDark ? theme.scaffoldBackgroundColor : const Color(0xFFFFF5F0);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Icon(Icons.pets, color: AppColors.peach, size: 26),
            const SizedBox(width: 8),
            Text(
              'Espati',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: cs.onSurface,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _navIcon(Icons.search_rounded, isDark, cs),
            onPressed: () {},
            tooltip: 'Ara',
          ),
          IconButton(
            icon: _navIcon(Icons.notifications_none_rounded, isDark, cs),
            onPressed: () {},
            tooltip: 'Bildirimler',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Stories row ──────────────────────────────────────────────────
          SizedBox(
            height: 108,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: SampleData.stories.length,
              itemBuilder: (context, index) {
                final story = SampleData.stories[index];
                return StoryCircle(
                  imageUrl: story['avatar']!,
                  name: story['name']!,
                  isOwn: story['isOwn'] == 'true',
                  hasBorder: story['isOwn'] != 'true',
                );
              },
            ),
          ),

          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 4),

          // ── Feed posts ───────────────────────────────────────────────────
          ...SampleData.posts.map(
            (post) => _SocialPostCard(post: post, isDark: isDark),
          ),
          const SizedBox(height: 12),
        ],
      ),

      // ── New post FAB ─────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Yeni gönderi oluştur',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: AppColors.softTeal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        backgroundColor: AppColors.peach,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_a_photo_rounded),
      ),
    );
  }

  Widget _navIcon(IconData icon, bool isDark, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: isDark ? cs.surface : AppColors.peachLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: cs.onSurface),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SocialPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isDark;

  const _SocialPostCard({required this.post, required this.isDark});

  @override
  State<_SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<_SocialPostCard>
    with SingleTickerProviderStateMixin {
  /// Stable post identifier used to key into [SocialViewModel].
  late final String _postId;

  /// Optimistic pati count — updates immediately on tap.
  late int _patiCount;

  bool _isBookmarked = false;
  bool _showHeart = false;

  /// Animates the full-screen paw overlay on double-tap.
  late AnimationController _heartCtrl;
  late Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();
    _postId = widget.post['id'] as String? ??
        'post_${widget.post['username']}';
    _patiCount = widget.post['pati'] as int;

    _heartCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _heartAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  /// Double-tap: give pati if not already pati'd, then show paw burst.
  void _handleDoubleTap(BuildContext context) {
    final vm = context.read<SocialViewModel>();
    if (!vm.isPostPati(_postId)) {
      setState(() => _patiCount += 1);
      vm.togglePati(_postId);
    }
    setState(() => _showHeart = true);
    _heartCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDark
        ? Theme.of(context).colorScheme.surface
        : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                _Avatar(url: widget.post['avatar'] as String),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post['username'] as String,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: widget.isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.post['timeAgo'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: (widget.isDark
                                  ? Colors.white
                                  : AppColors.textPrimary)
                              .withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.softTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Takip Et',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.softTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.more_horiz,
                  color: (widget.isDark ? Colors.white : AppColors.textPrimary)
                      .withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),

          // ── Pet photo with double-tap paw burst ─────────────────────────
          GestureDetector(
            onDoubleTap: () => _handleDoubleTap(context),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  child: CachedNetworkImage(
                    imageUrl: widget.post['image'] as String,
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 280,
                      color: AppColors.peachLight,
                      child: Center(
                        child: Icon(Icons.pets,
                            size: 56,
                            color: AppColors.peach.withOpacity(0.5)),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 280,
                      color: AppColors.peachLight,
                      child:
                          Icon(Icons.pets, size: 56, color: AppColors.peach),
                    ),
                  ),
                ),
                if (_showHeart)
                  AnimatedBuilder(
                    animation: _heartAnim,
                    builder: (_, __) => Transform.scale(
                      scale: _heartAnim.value,
                      child: Icon(
                        Icons.pets,
                        size: 90,
                        color: Colors.white.withOpacity(0.9),
                        shadows: const [
                          Shadow(blurRadius: 24, color: Colors.black38),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Action row: Pati | Yorum | Paylaş | Kaydet ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                // ── Pati (Like) ──────────────────────────────────────────
                // Selector rebuilds only when THIS post's pati state changes.
                Selector<SocialViewModel, bool>(
                  selector: (_, vm) => vm.isPostPati(_postId),
                  builder: (ctx, isPati, _) => _PatiButton(
                    isPati: isPati,
                    count: _patiCount,
                    onTap: () {
                      // Optimistic UI: update count immediately
                      setState(() => _patiCount += isPati ? -1 : 1);
                      // Business logic stays in the ViewModel — zero in View
                      ctx.read<SocialViewModel>().togglePati(_postId);
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // ── Yorum (Comment) ──────────────────────────────────────
                _YorumButton(count: widget.post['yorum'] as int),
                const SizedBox(width: 16),

                // ── Paylaş (Share) ───────────────────────────────────────
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      Icon(
                        Icons.send_rounded,
                        size: 22,
                        color: (widget.isDark
                                ? Colors.white
                                : AppColors.textPrimary)
                            .withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Paylaş',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: (widget.isDark
                                  ? Colors.white
                                  : AppColors.textPrimary)
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // ── Kaydet (Bookmark) ────────────────────────────────────
                GestureDetector(
                  onTap: () => setState(() => _isBookmarked = !_isBookmarked),
                  child: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 23,
                    color: _isBookmarked
                        ? AppColors.softTeal
                        : (widget.isDark ? Colors.white : AppColors.textPrimary)
                            .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // ── Caption ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color:
                      widget.isDark ? Colors.white70 : AppColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: '${widget.post['username']}  ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: widget.post['caption'] as String),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PATI BUTTON — High-fidelity paw like button with Lottie + haptics
//
// Architecture:
//   • [_lottieCtrl]     drives the Lottie stamp animation (or icon fallback)
//   • [_countScaleCtrl] drives the count label pop on increment
//   • Liked state comes from [SocialViewModel.isPostPati()] via props (MVVM)
//   • HapticFeedback.lightImpact()  → fires on tap
//   • HapticFeedback.mediumImpact() → fires at animation peak (~45%)
//   • [RepaintBoundary] in [_PawLottieOrIcon] isolates frame repaints
// ─────────────────────────────────────────────────────────────────────────────

class _PatiButton extends StatefulWidget {
  final bool isPati;
  final int count;
  final VoidCallback onTap;

  const _PatiButton({
    required this.isPati,
    required this.count,
    required this.onTap,
  });

  @override
  State<_PatiButton> createState() => _PatiButtonState();
}

class _PatiButtonState extends State<_PatiButton>
    with TickerProviderStateMixin {
  // ── Lottie animation controller ───────────────────────────────────────────
  late final AnimationController _lottieCtrl;
  static const _lottieDefaultDuration = Duration(milliseconds: 800);
  static const _reverseDuration = Duration(milliseconds: 200);

  // ── Count label pop animation ─────────────────────────────────────────────
  late final AnimationController _countScaleCtrl;
  late final Animation<double> _countScaleAnim;

  // ── Peak haptic guard ─────────────────────────────────────────────────────
  // Ensures HapticFeedback.mediumImpact() fires exactly once per cycle.
  bool _peakHapticFired = false;

  @override
  void initState() {
    super.initState();

    // Seed to end-frame if post is already pati'd on mount, so the paw
    // renders in its "stamped" state without replaying the animation.
    _lottieCtrl = AnimationController(
      duration: _lottieDefaultDuration,
      vsync: this,
      value: widget.isPati ? 1.0 : 0.0,
    );
    _lottieCtrl.addListener(_onLottieProgress);

    // Count pop: 1.0 → 1.4 (easeOut) → 1.0 (elasticOut spring)
    _countScaleCtrl = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _countScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_countScaleCtrl);
  }

  /// Fires [HapticFeedback.mediumImpact] once at the animation's
  /// "stamp impact" moment (~45%), simulating physical paw contact.
  void _onLottieProgress() {
    if (!_peakHapticFired && _lottieCtrl.value >= 0.45) {
      HapticFeedback.mediumImpact();
      _peakHapticFired = true;
    }
  }

  @override
  void didUpdateWidget(_PatiButton old) {
    super.didUpdateWidget(old);

    if (widget.isPati && !old.isPati) {
      // Pati given: stamp the paw forward
      _peakHapticFired = false;
      _lottieCtrl.forward(from: 0.0);
      _countScaleCtrl.forward(from: 0.0);
    } else if (!widget.isPati && old.isPati) {
      // Pati removed: retract quickly
      _lottieCtrl.animateTo(
        0.0,
        duration: _reverseDuration,
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void dispose() {
    _lottieCtrl.removeListener(_onLottieProgress);
    _lottieCtrl.dispose();
    _countScaleCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact(); // ① Immediate tactile response
    widget.onTap();               // ② Delegate to ViewModel via callback
  }

  @override
  Widget build(BuildContext context) {
    final labelColor =
        widget.isPati ? AppColors.softTeal : Colors.grey.shade500;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Paw icon: Lottie when asset present, icon fallback otherwise ─
          _PawLottieOrIcon(
            lottieCtrl: _lottieCtrl,
            isPati: widget.isPati,
          ),
          const SizedBox(width: 5),

          // ── Count label with Poppins typography + scale pop ─────────────
          AnimatedBuilder(
            animation: _countScaleAnim,
            builder: (_, __) => Transform.scale(
              scale: _countScaleAnim.value,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
                child: Text('${widget.count} Pati'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAW LOTTIE OR ICON
//
// Stack strategy:
//   L1 (bottom): [_FallbackPawIcon] — always present, [AnimatedWidget]-driven.
//                Visible through the transparent placeholder Lottie.
//   L2 (top):    [LottieBuilder.asset] — covers L1 once a real paw animation
//                JSON replaces the stub at assets/animations/lottie_paw_like.json.
//
// [RepaintBoundary] isolates per-frame repaints from the feed list.
// [LottieDelegates] automatically tints the asset to AppColors.softTeal/#grey
// so any flat/single-fill paw icon from LottieFiles.com works without edits.
// ─────────────────────────────────────────────────────────────────────────────

class _PawLottieOrIcon extends StatelessWidget {
  final AnimationController lottieCtrl;
  final bool isPati;

  const _PawLottieOrIcon({
    required this.lottieCtrl,
    required this.isPati,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = isPati ? AppColors.softTeal : Colors.grey.shade500;

    return RepaintBoundary(
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── L1: Icon fallback (always rendered) ──────────────────────
            _FallbackPawIcon(controller: lottieCtrl, isPati: isPati),

            // ── L2: Lottie (active once real JSON is provided) ────────────
            // Replace assets/animations/lottie_paw_like.json with a real
            // paw stamp animation from LottieFiles.com (search "paw" or
            // "pet like"). The LottieDelegates below handle all coloring.
            LottieBuilder.asset(
              'assets/animations/lottie_paw_like.json',
              controller: lottieCtrl,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              onLoaded: (composition) =>
                  lottieCtrl.duration = composition.duration,
              delegates: LottieDelegates(
                values: [
                  // Tint every layer: softTeal (#4DB6AC) when pati'd, grey otherwise
                  ValueDelegate.colorFilter(
                    const ['**'],
                    value: ColorFilter.mode(brandColor, BlendMode.srcIn),
                  ),
                ],
              ),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FALLBACK PAW ICON
//
// [AnimatedWidget] subclass — zero parent setState, driven directly by
// [AnimationController] notifications for maximum performance.
//
// Stamp scale curve:
//   0.00–0.45  approach : 1.00 → 1.35  (paw descends toward screen)
//   0.45–0.65  impact   : 1.35 → 0.82  (contact → triggers mediumImpact)
//   0.65–1.00  spring   : 0.82 → 1.00  (elastic rebound)
// ─────────────────────────────────────────────────────────────────────────────

class _FallbackPawIcon extends AnimatedWidget {
  final bool isPati;

  const _FallbackPawIcon({
    required AnimationController controller,
    required this.isPati,
  }) : super(listenable: controller);

  double get _stampScale {
    final t = (listenable as AnimationController).value;
    if (t <= 0.45) return 1.0 + 0.35 * (t / 0.45);
    if (t <= 0.65) return 1.35 - 0.53 * ((t - 0.45) / 0.20);
    return 0.82 + 0.18 * ((t - 0.65) / 0.35);
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _stampScale,
      child: Icon(
        Icons.pets,
        size: 22,
        color: isPati ? AppColors.softTeal : Colors.grey.shade500,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YORUM BUTTON — Comment button with elastic bounce micro-interaction
//
// Micro-interaction spec:
//   ① [HapticFeedback.selectionClick()] fires immediately on tap
//   ② Icon scale: 1.0 → 1.12 (easeOut) → 0.90 (easeInOut) → 1.0 (elasticOut)
//   ③ [RepaintBoundary] isolates the icon repaint layer
// ─────────────────────────────────────────────────────────────────────────────

class _YorumButton extends StatefulWidget {
  final int count;
  const _YorumButton({required this.count});

  @override
  State<_YorumButton> createState() => _YorumButtonState();
}

class _YorumButtonState extends State<_YorumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      duration: const Duration(milliseconds: 440),
      vsync: this,
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 0.90)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.90, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 48,
      ),
    ]).animate(_bounceCtrl);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext context) {
    HapticFeedback.selectionClick();
    _bounceCtrl.forward(from: 0.0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Yorumlar yakında açılacak!',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: AppColors.softTeal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _bounceAnim,
              builder: (_, __) => Transform.scale(
                scale: _bounceAnim.value,
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 22,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.count} Yorum',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR — gradient-ringed cached circular image
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String url;
  const _Avatar({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.peach, AppColors.softTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.peachLight,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Icon(Icons.person, size: 20, color: AppColors.peach),
            errorWidget: (_, __, ___) =>
                Icon(Icons.person, size: 20, color: AppColors.peach),
          ),
        ),
      ),
    );
  }
}
