import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../core/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POST CARD — reusable social feed card
//
// Brand language: "Pati" = like interaction, "Yorum" = comment interaction.
// [isLiked] and [onLike] are driven by the caller (ViewModel layer).
// This widget contains zero business logic — pure presentation + animation.
// ─────────────────────────────────────────────────────────────────────────────

class PostCard extends StatefulWidget {
  final String username;
  final String avatarUrl;
  final String imageUrl;
  final String caption;
  final int likes;
  final int comments;
  final String timeAgo;
  final String? postId;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const PostCard({
    super.key,
    required this.username,
    required this.avatarUrl,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    this.postId,
    this.isLiked = false,
    this.onLike,
    this.onComment,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  late int _likeCount;
  bool _isBookmarked = false;

  // Full-screen paw burst on double-tap
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likes;

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.likes != widget.likes) {
      _likeCount = widget.likes;
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _togglePati() {
    setState(() => _likeCount += widget.isLiked ? -1 : 1);
    widget.onLike?.call();
  }

  void _handleDoubleTap() {
    if (!widget.isLiked) _togglePati();
    setState(() => _showHeart = true);
    _heartController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.peachLight,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.avatarUrl,
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_horiz,
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          // ── Post image with double-tap paw burst ─────────────────────────
          GestureDetector(
            onDoubleTap: _handleDoubleTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 300,
                      color: AppColors.peachLight,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.peach,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 300,
                      color: AppColors.peachLight,
                      child: Icon(Icons.pets, size: 64, color: AppColors.peach),
                    ),
                  ),
                ),
                if (_showHeart)
                  AnimatedBuilder(
                    animation: _heartScale,
                    builder: (_, __) => Transform.scale(
                      scale: _heartScale.value,
                      child: Icon(
                        Icons.pets,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.9),
                        shadows: const [
                          Shadow(blurRadius: 20, color: Colors.black26),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Action row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Pati (Like) — Lottie-powered with haptics
                _PatiButton(
                  isPati: widget.isLiked,
                  count: _likeCount,
                  onTap: _togglePati,
                ),
                const SizedBox(width: 18),
                // Yorum (Comment) — elastic bounce micro-interaction
                _YorumButton(
                  count: widget.comments,
                  onTap: widget.onComment ?? () {},
                ),
                const SizedBox(width: 18),
                _ActionButton(
                  icon: Icons.send_rounded,
                  color: AppColors.textPrimary,
                  label: 'Paylaş',
                  onTap: () {},
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _isBookmarked = !_isBookmarked),
                  child: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // ── Caption ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                children: [
                  TextSpan(
                    text: '${widget.username}  ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: widget.caption),
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
// PATI BUTTON — Lottie-powered paw like button with haptics
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
  late final AnimationController _lottieCtrl;
  late final AnimationController _countScaleCtrl;
  late final Animation<double> _countScaleAnim;

  bool _peakHapticFired = false;

  @override
  void initState() {
    super.initState();
    _lottieCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
      value: widget.isPati ? 1.0 : 0.0,
    );
    _lottieCtrl.addListener(_onLottieProgress);

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
      _peakHapticFired = false;
      _lottieCtrl.forward(from: 0.0);
      _countScaleCtrl.forward(from: 0.0);
    } else if (!widget.isPati && old.isPati) {
      _lottieCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
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

  @override
  Widget build(BuildContext context) {
    final labelColor =
        widget.isPati ? AppColors.softTeal : Colors.grey.shade500;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PawLottieOrIcon(lottieCtrl: _lottieCtrl, isPati: widget.isPati),
          const SizedBox(width: 5),
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
// YORUM BUTTON — Comment button with elastic bounce micro-interaction
// ─────────────────────────────────────────────────────────────────────────────

class _YorumButton extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const _YorumButton({required this.count, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _bounceCtrl.forward(from: 0.0);
        widget.onTap();
      },
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
// PAW LOTTIE OR ICON — shared between PostCard and SocialScreen
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
            _FallbackPawIcon(controller: lottieCtrl, isPati: isPati),
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
                  // Tint every Lottie layer: softTeal (#4DB6AC) when pati'd
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
// ACTION BUTTON — generic icon + label tap target
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
