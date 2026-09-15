import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_colors.dart' show EspatiColors;
import '../core/neo_brutalist_tokens.dart';
import '../core/result.dart';
import '../data/models/comment_model.dart';
import '../data/models/listing_model.dart';
import '../data/models/post_model.dart';
import '../data/repositories/interfaces/i_chat_repository.dart';
import '../services/interaction_tracking_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/chat_thread_viewmodel.dart';
import '../viewmodels/social_viewmodel.dart';
import '../widgets/comment_brick.dart';
import '../widgets/common/ad_location_map.dart';
import '../widgets/common/neo_brutalist_button.dart';
import 'chat/chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEED DETAIL SCREEN (Design System Step 73) — the unified Neo-Brutalist
// detail view for both feed content types: a social [PostModel] and an
// adoption/lost [ListingModel]. Replaces `profile/post_detail_screen.dart`
// and `listing_detail_screen.dart` (both plain Material screens, never
// touched by this design pass) as the single tap target for feed items —
// "isAd" drives the few places their content genuinely differs (status
// badge, action row, bottom bar), everything else is one shared layout.
//
// Construct with [FeedDetailScreen.post] or [FeedDetailScreen.listing].
//
// Real functionality preserved from the two screens this replaces:
//   • Listing: multi-image gallery + dot indicator, the mini Google Map
//     with "Yol Tarifi Al" driving directions, and the real
//     get-or-create-chat-room "message the owner" flow (unchanged from
//     Step 69/71's proven [IChatRepository.getOrCreateChatRoom] →
//     [ChatThreadViewModel] → [ChatScreen] pipeline).
//   • Post: real Pati/bookmark toggle + share (same [SocialViewModel]
//     wiring [DiscoverPostCard]/`_DiscoverFeedPostCard` use in the Discover
//     feed, Step 66) — this screen never had working like/save buttons
//     before, only a static count display.
//
// The Follow button (real — [SocialViewModel.toggleFollow]/[isUserFollowed],
// same as search_screen.dart's Follow pill) is real for both content types.
//
// Comments (posts only — [_CommentsSection], real as of the Topluluk
// membership/comments pass): [SocialViewModel.addYorum]/[watchComments]
// wrap `posts/{postId}/comments`, a real Firestore write+read path that
// existed half-built (write-only, never called) before this pass. Ads
// (listings) don't get a comments section — [ListingModel] has no
// `commentsCount`/comments concept at all, out of scope here.
// ─────────────────────────────────────────────────────────────────────────────

class FeedDetailScreen extends StatefulWidget {
  final PostModel? post;
  final ListingModel? listing;

  const FeedDetailScreen.post(this.post, {super.key}) : listing = null;

  const FeedDetailScreen.listing(this.listing, {super.key}) : post = null;

  bool get isAd => listing != null;

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  final _commentController = TextEditingController();
  bool _startingChat = false;
  bool _patiCountSeeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final post = widget.post;
    if (post != null && !_patiCountSeeded) {
      context.read<SocialViewModel>().seedPatiCount(post.id, post.patiCount);
      _patiCountSeeded = true;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _authorId => widget.isAd ? widget.listing!.authorId : widget.post!.authorId;
  String get _authorName {
    final name = widget.isAd ? widget.listing!.authorName : widget.post!.authorName;
    return name.isNotEmpty ? name : 'Pati Dostu';
  }
  String get _authorPhoto => widget.isAd ? widget.listing!.authorPhoto : widget.post!.authorImage;

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.nunitoSans(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? EspatiColors.red : Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.white, width: 1.5),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  Future<void> _messageOwner() async {
    final listing = widget.listing!;
    final currentUser = context.read<AuthViewModel>().currentUser;

    if (currentUser == null) {
      _showToast('Mesaj göndermek için giriş yapmalısınız.', isError: true);
      return;
    }
    if (listing.authorId == currentUser.id) {
      _showToast('Kendi ilanınıza mesaj gönderemezsiniz.', isError: true);
      return;
    }
    if (listing.authorId.isEmpty) {
      _showToast('Bu ilan için ilan sahibi bilgisi bulunamadı.', isError: true);
      return;
    }

    setState(() => _startingChat = true);
    final chatRepo = context.read<IChatRepository>();
    final result = await chatRepo.getOrCreateChatRoom(
      currentUserId: currentUser.id,
      currentUserName:
          currentUser.name.isNotEmpty ? currentUser.name : currentUser.email,
      currentUserPhoto: currentUser.profilePicture,
      otherUserId: listing.authorId,
      otherUserName: listing.authorName.isNotEmpty ? listing.authorName : 'Pati Dostu',
      otherUserPhoto: listing.authorPhoto,
      // Listing inquiry — contextually known, skips the request queue.
      autoAccept: true,
    );

    if (!mounted) return;
    setState(() => _startingChat = false);

    switch (result) {
      case Success(:final data):
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<ChatThreadViewModel>(
              create: (_) => ChatThreadViewModel(
                chatRepository: chatRepo,
                roomId: data.roomId,
                currentUserId: currentUser.id,
              ),
              child: ChatScreen(
                chatTitle: data.otherParticipantName(currentUser.id),
                otherUserPhoto: data.otherParticipantPhoto(currentUser.id),
                adContext: '${listing.name} - ${listing.status.label}',
                adContextImageUrl: listing.imageUrl,
              ),
            ),
          ),
        );
      case Failure(:final message):
        _showToast(message, isError: true);
    }
  }

  Future<void> _share() async {
    HapticFeedback.selectionClick();
    final text = widget.isAd
        ? '${widget.listing!.name} — ESPATI\'de gör! 🐾'
        : '${widget.post!.description.isEmpty ? _authorName : widget.post!.description}\n\n— ESPATI 🐾';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      // Share sheet unavailable on host platform — no-op.
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    final post = widget.post;
    if (text.isEmpty || post == null) return;

    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) {
      _showToast('Yorum yapmak için giriş yapmanız gerekiyor.', isError: true);
      return;
    }

    _commentController.clear();
    final success = await context.read<SocialViewModel>().addYorum(
          post.id,
          text,
          authorName: user.name.isNotEmpty ? user.name : user.email,
          authorPhoto: user.profilePicture,
        );
    if (!success && mounted) {
      _showToast('Yorum eklenemedi. Lütfen tekrar deneyin.', isError: true);
    }
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
          widget.isAd ? 'İlan Detayı' : 'Gönderi Detayı',
          style: GoogleFonts.baloo2(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text-only posts (empty imageUrl, non-ad) render no hero
                    // block at all — a Reddit/Facebook-style text post,
                    // rather than a large placeholder icon with nothing to
                    // show.
                    if (widget.isAd || widget.post!.imageUrl.isNotEmpty)
                      _HeroImage(
                        isAd: widget.isAd,
                        imageUrl: widget.isAd ? null : widget.post!.imageUrl,
                        imageUrls: widget.isAd ? widget.listing!.imageUrls : null,
                        statusLabel: widget.isAd ? widget.listing!.status.label.toUpperCase() : null,
                        statusColor:
                            widget.isAd ? widget.listing!.status.accentColor : null,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AuthorRow(
                            authorId: _authorId,
                            authorName: _authorName,
                            authorPhoto: _authorPhoto,
                          ),
                          const SizedBox(height: 16),

                          if (widget.isAd)
                            _ListingInfo(listing: widget.listing!)
                          else ...[
                            _PostInteractionBar(post: widget.post!, onShare: _share),
                            const SizedBox(height: 14),
                            if (widget.post!.description.isNotEmpty)
                              Text(
                                widget.post!.description,
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.black,
                                ),
                              ),
                          ],

                          if (!widget.isAd) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Yorumlar',
                              style: GoogleFonts.baloo2(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _CommentsSection(postId: widget.post!.id),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Pinned bottom bar ────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.black, width: 2.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: widget.isAd
                    ? _MessageOwnerBar(
                        isLoading: _startingChat,
                        onPressed: _startingChat ? null : _messageOwner,
                      )
                    : _CommentInputBar(
                        controller: _commentController,
                        onSend: _sendComment,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMENTS SECTION — real, live [CommentModel] list via
// [SocialViewModel.watchComments]. Posts only (see file header).
// ─────────────────────────────────────────────────────────────────────────────

class _CommentsSection extends StatefulWidget {
  final String postId;
  const _CommentsSection({required this.postId});

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  // Requested once in initState, not on every build — a fresh call to
  // watchComments() re-attaches a brand-new Firestore listener each time
  // (it's a thin passthrough, not a cached stream), so grabbing it inline
  // inside build() would tear down and restart the subscription — and
  // briefly flash back to the loading state — on every unrelated rebuild
  // of this screen.
  late final Stream<List<CommentModel>> _comments =
      context.read<SocialViewModel>().watchComments(widget.postId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommentModel>>(
      stream: _comments,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: EspatiColors.sageGreen),
              ),
            ),
          );
        }

        final comments = snapshot.data!;
        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Henüz yorum yok — ilk yorumu sen yap!',
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < comments.length; i++)
              CommentBrick(
                authorName: comments[i].authorName.isNotEmpty
                    ? comments[i].authorName
                    : 'Pati Dostu',
                text: comments[i].text,
                timeAgo: _formatTimeAgo(comments[i].timestamp),
                accent: i.isEven
                    ? EspatiColors.terracotta
                    : EspatiColors.sageGreen,
              ),
          ],
        );
      },
    );
  }

  static String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}sa önce';
    if (diff.inDays < 7) return '${diff.inDays}g önce';
    return '${(diff.inDays / 7).floor()}h önce';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO IMAGE — single image (post) or swipeable gallery (listing), thick
// top/bottom darkBrown borders, status badge overlay for ads.
// ─────────────────────────────────────────────────────────────────────────────

class _HeroImage extends StatefulWidget {
  final bool isAd;
  final String? imageUrl;
  final List<String>? imageUrls;
  final String? statusLabel;
  final Color? statusColor;

  const _HeroImage({
    required this.isAd,
    this.imageUrl,
    this.imageUrls,
    this.statusLabel,
    this.statusColor,
  });

  @override
  State<_HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<_HeroImage> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _placeholder() => Container(
        color: EspatiColors.sageGreen.withValues(alpha: 0.25),
        child: const Icon(Icons.pets_rounded,
            size: 48, color: Colors.black),
      );

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls ?? const [];
    final singleUrl = widget.imageUrl ?? '';

    return Container(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.black, width: 3),
        ),
      ),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.isAd)
              urls.isEmpty
                  ? _placeholder()
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: urls.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: urls[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      ),
                    )
            else
              CachedNetworkImage(
                imageUrl: singleUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              ),

            if (widget.isAd && urls.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    urls.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                            color: Colors.black, width: 1),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Status badge — bottom-right, ads only ────────────────────
            if (widget.isAd && widget.statusLabel != null)
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.statusColor,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                        color: Colors.black, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.statusLabel!,
                    style: GoogleFonts.baloo2(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTHOR ROW — square avatar, bold username, real Follow button
// ─────────────────────────────────────────────────────────────────────────────

class _AuthorRow extends StatelessWidget {
  final String authorId;
  final String authorName;
  final String authorPhoto;

  const _AuthorRow({
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthViewModel>().currentUser?.id;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: EspatiColors.sageGreen,
            borderRadius: BorderRadius.zero,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.black, width: 2),
            ),
          ),
          child: authorPhoto.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: authorPhoto,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(Icons.pets_rounded,
                      color: Colors.black, size: 20),
                )
              : const Icon(Icons.pets_rounded,
                  color: Colors.black, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.baloo2(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        if (authorId.isNotEmpty && authorId != currentUid)
          Selector<SocialViewModel, bool>(
            selector: (_, vm) => vm.isUserFollowed(authorId),
            builder: (context, isFollowed, _) => NeoBrutalistButton(
              semanticLabel: isFollowed ? 'Takibi bırak' : 'Takip et',
              onPressed: () {
                HapticFeedback.selectionClick();
                context.read<SocialViewModel>().toggleFollow(authorId);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isFollowed ? Colors.white : EspatiColors.sageGreen,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: isFollowed
                      ? null
                      : const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                ),
                child: Text(
                  isFollowed ? 'Takip Ediliyor' : 'Takip Et',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST INTERACTION BAR — Paw / Comment / Share (left), Save (right). Real
// SocialViewModel wiring — same source of truth DiscoverPostCard uses.
// Listings have no like/save semantics in this app's real data model, so
// this bar is post-only (see file header).
// ─────────────────────────────────────────────────────────────────────────────

class _PostInteractionBar extends StatelessWidget {
  final PostModel post;
  final VoidCallback onShare;

  const _PostInteractionBar({required this.post, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Selector<SocialViewModel, (bool, int, bool)>(
      selector: (_, vm) => (
        vm.isPostPati(post.id),
        vm.getPatiCount(post.id),
        vm.isPostBookmarked(post.id),
      ),
      builder: (context, state, _) {
        final (isLiked, likeCount, isBookmarked) = state;
        return Row(
          children: [
            _InteractionIcon(
              icon: isLiked ? Icons.pets_rounded : Icons.pets_outlined,
              active: isLiked,
              label: '$likeCount',
              semanticLabel: isLiked ? 'Patiyi geri al' : 'Pati at',
              onTap: () {
                HapticFeedback.lightImpact();
                InteractionTrackingService.instance.logInteraction(
                    post.petBreed.isNotEmpty ? post.petBreed : post.petType, 1.0);
                context.read<SocialViewModel>().togglePati(post.id);
              },
            ),
            const SizedBox(width: 18),
            _InteractionIcon(
              icon: Icons.chat_bubble_outline_rounded,
              label: '${post.commentsCount}',
              semanticLabel: 'Yorumlar',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Yorumlar — yakında geliyor!',
                      style: GoogleFonts.nunitoSans(fontSize: 13)),
                  backgroundColor: Colors.black,
                  behavior: SnackBarBehavior.floating,
                ),
              ),
            ),
            const SizedBox(width: 18),
            _InteractionIcon(
              icon: Icons.send_rounded,
              semanticLabel: 'Paylaş',
              onTap: onShare,
            ),
            const Spacer(),
            _InteractionIcon(
              icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              active: isBookmarked,
              semanticLabel: isBookmarked ? 'Kaydedildi' : 'Kaydet',
              onTap: () {
                HapticFeedback.selectionClick();
                context.read<SocialViewModel>().toggleBookmark(post.id);
              },
            ),
          ],
        );
      },
    );
  }
}

class _InteractionIcon extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool active;
  final String semanticLabel;
  final VoidCallback onTap;

  const _InteractionIcon({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? EspatiColors.terracotta : Colors.black;
    return NeoBrutalistButton(
      semanticLabel: semanticLabel,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!,
                  style: GoogleFonts.nunitoSans(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LISTING INFO — status/name/type/location/date/description/mini-map. Real
// data, unchanged from the old ListingDetailScreen, restyled.
// ─────────────────────────────────────────────────────────────────────────────

class _ListingInfo extends StatelessWidget {
  final ListingModel listing;
  const _ListingInfo({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.name,
          style: GoogleFonts.baloo2(
              fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
        ),
        Text(
          listing.type,
          style: GoogleFonts.nunitoSans(
              fontSize: 14, color: Colors.black.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 15, color: Colors.black),
            const SizedBox(width: 4),
            Expanded(
              child: Text(listing.location,
                  style: GoogleFonts.nunitoSans(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.schedule_rounded,
                size: 13, color: Colors.black.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(listing.date,
                style: GoogleFonts.nunitoSans(
                    fontSize: 12, color: Colors.black.withValues(alpha: 0.5))),
            if (listing.isUrgent) ...[
              const SizedBox(width: 8),
              Text('· ACİL',
                  style: GoogleFonts.nunitoSans(
                      fontSize: 12, fontWeight: FontWeight.w700, color: EspatiColors.terracotta)),
            ],
          ],
        ),
        if (listing.description.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('Açıklama',
              style: GoogleFonts.baloo2(
                  fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
          const SizedBox(height: 6),
          Text(listing.description,
              style: GoogleFonts.nunitoSans(
                  fontSize: 14, height: 1.5, color: Colors.black.withValues(alpha: 0.85))),
        ],
        if (listing.hasLocation) ...[
          const SizedBox(height: 18),
          Text('Son Görülen Konum',
              style: GoogleFonts.baloo2(
                  fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
          const SizedBox(height: 8),
          AdLocationMapWidget(
            latitude: listing.latitude,
            longitude: listing.longitude,
            label: listing.name,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PINNED BOTTOM BAR — ad: massive "İlan Sahibine Mesaj At" CTA.
// non-ad: comment input + blocky send button.
// ─────────────────────────────────────────────────────────────────────────────

class _MessageOwnerBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _MessageOwnerBar({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: NeoBrutalistButton(
        onPressed: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: EspatiColors.terracotta,
            borderRadius: BorderRadius.zero,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.black, width: 3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: Offset(5, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pets_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'İlan Sahibine Mesaj At',
                      style: GoogleFonts.baloo2(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _CommentInputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Yorum ekle...',
                  hintStyle: GoogleFonts.nunitoSans(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          NeoBrutalistButton(
            semanticLabel: 'Gönder',
            onPressed: onSend,
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: EspatiColors.sageGreen,
                borderRadius: BorderRadius.zero,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 2.5),
                ),
              ),
              child: const Icon(Icons.pets_rounded,
                  color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
