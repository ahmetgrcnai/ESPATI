import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_colors.dart';

/// A social media post card with user header, image, action buttons, caption,
/// and a double-tap heart animation.
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
  bool _localLiked = false;
  late int _likeCount;
  bool _isBookmarked = false;

  // Heart animation
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _localLiked = widget.isLiked;
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
    if (oldWidget.isLiked != widget.isLiked) {
      _localLiked = widget.isLiked;
    }
    if (oldWidget.likes != widget.likes) {
      _likeCount = widget.likes;
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _localLiked = !_localLiked;
      _likeCount += _localLiked ? 1 : -1;
    });
    widget.onLike?.call();
  }

  void _handleDoubleTap() {
    if (!_localLiked) {
      _toggleLike();
    }
    // Show heart animation
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
          // ── User header ──
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
                      placeholder: (context, url) =>
                          Icon(Icons.person, size: 20, color: AppColors.peach),
                      errorWidget: (context, url, error) =>
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

          // ── Post image with double-tap heart ──
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
                    placeholder: (context, url) => Container(
                      height: 300,
                      color: AppColors.peachLight,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.peach,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 300,
                      color: AppColors.peachLight,
                      child: Icon(Icons.pets, size: 64, color: AppColors.peach),
                    ),
                  ),
                ),
                // Heart overlay animation
                if (_showHeart)
                  AnimatedBuilder(
                    animation: _heartScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _heartScale.value,
                        child: Icon(
                          Icons.favorite,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.9),
                          shadows: const [
                            Shadow(
                              blurRadius: 20,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // ── Action row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Like button with animated icon
                _LikeButton(
                  isLiked: _localLiked,
                  count: _likeCount,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 18),
                // Comment
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: AppColors.textPrimary,
                  label: '${widget.comments}',
                  onTap: widget.onComment ?? () {},
                ),
                const SizedBox(width: 18),
                // Share
                _ActionButton(
                  icon: Icons.send_rounded,
                  color: AppColors.textPrimary,
                  label: 'Share',
                  onTap: () {},
                ),
                const Spacer(),
                // Bookmark
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

          // ── Caption ──
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

/// Animated like button with scale bounce.
class _LikeButton extends StatefulWidget {
  final bool isLiked;
  final int count;
  final VoidCallback onTap;

  const _LikeButton({
    required this.isLiked,
    required this.count,
    required this.onTap,
  });

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        if (!widget.isLiked) _controller.forward(from: 0);
      },
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _scale,
            builder: (context, child) {
              return Transform.scale(
                scale: _scale.value,
                child: Icon(
                  widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 22,
                  color:
                      widget.isLiked ? AppColors.error : AppColors.textPrimary,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.count}',
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

/// Small action button (comment, share) with icon and label.
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
