import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/interfaces/i_chat_repository.dart';
import '../../data/repositories/interfaces/i_mating_repository.dart';
import '../../data/repositories/interfaces/i_pet_repository.dart';
import '../../data/repositories/interfaces/i_user_repository.dart';
import '../../services/interaction_tracking_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/form_viewmodel.dart';
import '../../viewmodels/mating_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/social_viewmodel.dart';
import '../../widgets/action_hub_sheet.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/common/story_tray.dart';
import '../../widgets/discover_post_card.dart';
import '../inbox/inbox_screen.dart';
import '../feed_detail_screen.dart';
import '../mating/mating_swipe_screen.dart';
import '../notifications/notification_screen.dart';
import 'story_camera_screen.dart';
import 'story_viewer_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ALGORITHMIC FEED SCREEN — Tab 0 root (Phase 3 Step 6-8 / "Summit A")
//
// Ranks mixed content (Listings + Posts, future Short Videos) with a real,
// per-user weighted score — see [_score] — instead of the Step 6 skeleton's
// pure chronological sort. The weighting signal is
// [UserModel.interestScores] (Step 7), accumulated by
// [InteractionTrackingService.logInteraction] whenever the user taps into a
// listing/post from this feed or from [GroupDetailScreen] (Step 8 wiring,
// see `_categoryTag` and the card `onTap` handlers below).
//
// This is still not the server-side "Summit A" recommendation model the CTO
// described — there's no ML, no offline batch scoring, no A/B-tested
// weights. It's a client-side, transparent formula over real, live data
// (real listings/posts, the real signed-in user's real accumulated
// interest scores). No fake Firestore data or fabricated users were added.
//
// Instagram-style architecture (Design System Step 15): a fixed AppBar
// (Create / ESPATI wordmark / Notifications) sits above a horizontal
// PageView — index 0 is [StoryCameraScreen] (live camera preview for
// Stories capture, Design System Step 17), index 1 is this feed. The
// AppBar used to live as a floating/snap SliverAppBar *inside* the feed's
// own scroll view; it moved out to a plain Scaffold.appBar since it's now
// shared chrome above two swipeable pages, not scroll-coupled content
// belonging to just one of them.
//
// The map view ([PoiMapScreen]) is no longer reachable from here — it's
// its own bottom-nav tab now (Design System Step 12), so the "🗺️ Haritada
// Gör" button this AppBar used to carry would just be a redundant second
// entry point to the same destination.
//
// ── STEP 66 — "DiscoverScreen" Neo-Brutalist rebuild ────────────────────────
// This *is* the Discover/Home feed the brief describes (MainScreen's tab 0,
// "Keşfet") — rebuilt in place rather than forked into a parallel
// DiscoverScreen; a second, unwired copy of the app's actual home feed would
// just be dead code next to the real thing. `lib/screens/feed/feed_screen.dart`
// is a genuinely orphaned, unreachable predecessor from an earlier phase —
// not this screen, and not touched here.
//
// AppBar leading's Neo-Brutalist "+" (Oluştur) button is gone — the task's
// AppBar spec is exactly "ESPATİ" wordmark + Notification + Messages, no
// third leading icon. Its `showActionHubSheet` action moved to the new
// bottom-right FAB instead of living in two places at once.
// ─────────────────────────────────────────────────────────────────────────────

class AlgorithmicFeedScreen extends StatefulWidget {
  /// Fired whenever the internal PageView switches to/away from the Story
  /// camera page (index 0) — lets [MainScreen] hide its floating bottom
  /// nav bar while the camera preview is showing, Instagram-style, since
  /// that nav bar is an overlay drawn above this whole tab and would
  /// otherwise sit on top of the live camera feed permanently.
  final ValueChanged<bool>? onCameraPageActive;

  const AlgorithmicFeedScreen({super.key, this.onCameraPageActive});

  @override
  State<AlgorithmicFeedScreen> createState() => _AlgorithmicFeedScreenState();
}

class _AlgorithmicFeedScreenState extends State<AlgorithmicFeedScreen> {
  // Owned by State (not created inline in build) so it survives Consumer3
  // rebuilds — creating a fresh PageController on every feed update would
  // snap the user back to initialPage every time new data streams in.
  late final PageController _pageController;

  /// Tracks which PageView page is current — [StoryCameraScreen] uses this
  /// (via `isActive`) to lazily acquire/release the device camera only
  /// while the user is actually looking at it.
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Clears MainScreen's floating [EspatiBottomNavBar] overlay (same
  /// formula used across the app, e.g. ProfileScreen) — the bar sits on
  /// top of every tab's content in a Stack, not reserved Scaffold layout
  /// space, so the FAB needs its own clearance to avoid sitting behind it.
  static const double _bottomNavClearance = EspatiBottomNavBar.height + 24 + 16;

  // Screen-scoped MatingViewModel — same "create fresh per visit" wiring
  // every other feature-entry-point flow in this app uses (see
  // GroupDetailScreen._openCreateTopic, CameraPreviewScreen._next).
  void _openMatingModule(BuildContext context) {
    final matingRepo = context.read<IMatingRepository>();
    final chatRepo = context.read<IChatRepository>();
    final userRepo = context.read<IUserRepository>();
    final petRepo = context.read<IPetRepository>();
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<MatingViewModel>(
          create: (_) => MatingViewModel(
            matingRepository: matingRepo,
            chatRepository: chatRepo,
            userRepository: userRepo,
            petRepository: petRepo,
            currentUser: user,
          ),
          child: const MatingSwipeScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Step 66 — light cream canvas, matching every other rebuilt screen
      // this design system pass has touched (was the dark-brown scaffold).
      backgroundColor: NeoBrutal.scaffoldBg,
      // Minimal header on the camera page (Design System Step 31): the
      // notification/messages actions are Explore-feed actions with
      // nothing to do while a live camera preview fills the page — hiding
      // them keeps that page distraction-free, Instagram-style. The
      // "ESPATİ" title stays put either way.
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'ESPATİ',
          style: GoogleFonts.baloo2(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        actions: _currentPage == 0
            ? const []
            : [
                // Ruh Eşi (mating) module entry point — a heart, left of
                // the notification bell. Unambiguous: "Pati" (a paw stamp),
                // not a heart, is this app's like/beğeni icon everywhere
                // else, so this is the only heart button in the app.
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _AppBarIconButton(
                    icon: Icons.favorite_rounded,
                    background: EspatiColors.peach,
                    semanticLabel: 'Ruh Eşi',
                    showBadge: false,
                    onPressed: () => _openMatingModule(context),
                  ),
                ),
                // Step 66 — pop-out Neo-Brutalist bricks (BorderRadius.zero,
                // thick darkBrown border, hard offset shadow) via
                // NeoBrutalistButton, replacing the bare transparent
                // IconButton bell. Messages carries a tiny overflowing
                // terracotta badge.
                Consumer<NotificationViewModel>(
                  builder: (context, notifVm, _) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _AppBarIconButton(
                      icon: Icons.notifications_rounded,
                      background: EspatiColors.sageGreen,
                      semanticLabel: 'Bildirimler',
                      showBadge: notifVm.hasUnread,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const NotificationScreen()),
                      ),
                    ),
                  ),
                ),
                Consumer<ChatViewModel>(
                  builder: (context, chatVm, _) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _AppBarIconButton(
                      icon: Icons.mail_rounded,
                      background: EspatiColors.peach,
                      semanticLabel: 'Mesajlar',
                      // ChatRoomModel has no per-room unread flag yet — this
                      // is a "you have active conversations" proxy, not a
                      // true unread count. Real unread tracking needs that
                      // field added to the model/repository first.
                      showBadge: chatVm.chatRooms.isNotEmpty,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InboxScreen()),
                      ),
                    ),
                  ),
                ),
              ],
      ),
      floatingActionButton: _currentPage == 0
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: _bottomNavClearance - 16),
              child: _CreateFab(
                onPressed: () => showActionHubSheet(
                  context,
                  onCreateStory: () => _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
            ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() => _currentPage = page);
          widget.onCameraPageActive?.call(page == 0);
        },
        children: [
          StoryCameraScreen(
            isActive: _currentPage == 0,
            onClose: () => _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            ),
          ),
          Consumer3<FormViewModel, SocialViewModel, ProfileViewModel>(
            builder: (context, formVm, socialVm, profileVm, _) {
              final items = _mergedFeed(
                formVm.allListings,
                socialVm.feedPosts,
                profileVm.user.interestScores,
              );

              // Story tray is pinned above the vertical feed (its own
              // horizontal scroll, not part of the feed's ListView) —
              // matches real Instagram behavior, and stays visible whether
              // the feed below it is populated or empty. Sourced from
              // SocialViewModel.stories — a real, live getStories() call
              // (already auto-loaded in that ViewModel's constructor); it
              // just always returns an empty list today since Stories
              // aren't a built-out backend feature yet. No fake entries
              // were added to make the tray look populated.
              final storyItems = socialVm.stories
                  .map((s) => StoryTrayItem(
                        id: s.id,
                        imageUrl: s.imageUrl,
                        // StoryModel has no denormalized author name
                        // yet (unlike PostModel/ListingModel) — this
                        // list is always empty in practice today, so
                        // rather than parade a raw Firestore userId
                        // as a "username" on the off chance this ever
                        // renders, fall back to a generic label until
                        // that denormalization is added.
                        label: 'Kullanıcı',
                        isUnseen: !s.isViewed,
                      ))
                  .toList();

              return Column(
                children: [
                  StoryTray(
                    stories: storyItems,
                    currentUserName: profileVm.user.name,
                    currentUserPhotoUrl: profileVm.user.profilePicture,
                    onAddStory: () => _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    ),
                    onStoryTap: (tapped) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          stories: storyItems,
                          initialIndex: storyItems.indexOf(tapped).clamp(
                              0, storyItems.isEmpty ? 0 : storyItems.length - 1),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? const _EmptyFeed()
                        : ListView.separated(
                            // Bottom: 100 — clears the floating nav bar
                            // (Design System Step 3), which overlays the
                            // body instead of reserving its own Scaffold
                            // layout space.
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              if (item is ListingModel) {
                                return FeedListingCard(listing: item);
                              }
                              return DiscoverFeedPostCard(
                                  post: item as PostModel);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Merges live listings + posts and ranks them by [_score], descending.
  ///
  /// Null-safety fallback (per spec): a brand-new user has an empty
  /// [interestScores] map, so every item's interest term below is 0 and the
  /// formula degenerates to pure recency ordering anyway — but an empty map
  /// is handled as an explicit fast path here too, both to match the spec
  /// literally and to skip the score computation entirely when it can't
  /// change the ordering.
  List<Object> _mergedFeed(
    List<ListingModel> listings,
    List<PostModel> posts,
    Map<String, double> interestScores,
  ) {
    // Madde 8 — safety mandate: never render content a moderation pass has
    // flagged. isApproved defaults to true for legacy records, so this only
    // excludes items an explicit moderation decision rejected.
    final items = <Object>[
      ...listings.where((l) => l.isApproved),
      ...posts.where((p) => p.isApproved),
    ];

    if (interestScores.isEmpty) {
      items.sort((a, b) => _itemDate(b).compareTo(_itemDate(a)));
      return items;
    }

    items.sort((a, b) =>
        _score(b, interestScores).compareTo(_score(a, interestScores)));
    return items;
  }

  DateTime _itemDate(Object item) =>
      item is ListingModel ? item.createdAt : (item as PostModel).timestamp;

  /// How much one point of accumulated interest is worth against recency.
  /// Tunable — chosen so a handful of interactions on a tag (interest score
  /// of a few points) can meaningfully outrank recency, matching the spec's
  /// example: 5 points in "Kedi" should visibly push a "Kedi" listing up.
  static const double _interestMultiplier = 0.5;

  /// `Item Score = Base Timestamp Weight + (User Interest Score for the
  /// item's category × _interestMultiplier)`.
  ///
  /// Base Timestamp Weight is a bounded recency decay in `(0, 1]` — `1.0`
  /// for "right now", `~0.5` at 24h old, `~0.13` at a week old — rather
  /// than the raw [DateTime], so the interest term operates on a
  /// comparable, predictable scale instead of fighting an unbounded date
  /// difference.
  double _score(Object item, Map<String, double> interestScores) {
    final hoursAgo =
        DateTime.now().difference(_itemDate(item)).inMinutes / 60.0;
    final baseTimestampWeight = 1 / (1 + hoursAgo / 24.0);
    final interest = interestScores[_categoryTag(item)] ?? 0.0;
    return baseTimestampWeight + interest * _interestMultiplier;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR ICON BUTTON — pop-out Neo-Brutalist brick (Step 66), with an
// optional tiny overflowing terracotta badge (used for the Messages icon's
// unread indicator).
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final String semanticLabel;
  final bool showBadge;
  final VoidCallback onPressed;

  const _AppBarIconButton({
    required this.icon,
    required this.background,
    required this.semanticLabel,
    required this.onPressed,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.zero,
              border:
                  Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
          if (showBadge)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: EspatiColors.terracotta,
                  borderRadius: BorderRadius.zero,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE FAB — massive blocky "+" (Step 66). Replaces the old AppBar-leading
// "Oluştur" trigger as the single entry point into the same real
// showActionHubSheet flow.
// ─────────────────────────────────────────────────────────────────────────────

class _CreateFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Oluştur',
      child: NeoBrutalistButton(
        semanticLabel: 'Oluştur',
        onPressed: onPressed,
        child: Container(
          width: 64,
          height: 64,
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
          child: const Icon(Icons.add, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}

/// The interest tag an item is tracked/scored under — a [ListingModel]'s
/// structured species facet ("Kedi", "Köpek", ...) or a [PostModel]'s breed
/// (falling back to its denormalized species type), matching the spec's own
/// examples ("Kedi", "Golden"). Falls back to 'Diğer' when the item has
/// neither (legacy records predating these fields).
///
/// Shared by [InteractionTrackingService.logInteraction] call sites (the
/// card `onTap` handlers below) and [AlgorithmicFeedScreen]'s own scoring —
/// deliberately the same function for both, since a signal logged under one
/// tag must be read back under that exact same tag to ever affect ranking.
String _categoryTag(Object item) {
  if (item is ListingModel) {
    return item.species.isNotEmpty ? item.species : 'Diğer';
  }
  final post = item as PostModel;
  if (post.petBreed.isNotEmpty) return post.petBreed;
  if (post.petType.isNotEmpty) return post.petType;
  return 'Diğer';
}

// ─────────────────────────────────────────────────────────────────────────────
// FEED LISTING CARD — ListingModel item in the mixed feed, restyled Step 66
// to the same thick-border/hard-shadow language as DiscoverPostCard so the
// mixed feed doesn't alternate between two different card languages.
//
// Public (Step 69, "Kaydedilenler"): reused as-is by SavedItemsScreen so a
// saved listing renders identically here and there — one card, not two
// diverging copies. The bookmark badge (Step 69) is the first save
// affordance a listing has ever had in this app — see
// [SocialViewModel.toggleListingBookmark]'s doc comment for why listings
// didn't have one before.
// ─────────────────────────────────────────────────────────────────────────────

class FeedListingCard extends StatelessWidget {
  final ListingModel listing;

  const FeedListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final statusColor = listing.status.accentColor;
    final statusIcon = listing.status.icon;

    return GestureDetector(
      onTap: () {
        // Step 8: log a view interaction on this listing's category before
        // navigating, so future feed loads can weight it into the ranking.
        InteractionTrackingService.instance
            .logInteraction(_categoryTag(listing), 1.0);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FeedDetailScreen.listing(listing)),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.fromBorderSide(
            BorderSide(color: Colors.black, width: 2.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.black, width: 2.5),
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: listing.imageUrl,
                    width: 90,
                    height: 110,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 90,
                      height: 110,
                      color: EspatiColors.sageGreen.withValues(alpha: 0.25),
                      child: const Icon(Icons.pets_rounded,
                          size: 30, color: Colors.black),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 90,
                      height: 110,
                      color: EspatiColors.sageGreen.withValues(alpha: 0.25),
                      child: const Icon(Icons.pets_rounded,
                          size: 30, color: Colors.black),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Selector<SocialViewModel, bool>(
                    selector: (_, vm) => vm.isListingBookmarked(listing.id),
                    builder: (context, isSaved, _) => NeoBrutalistButton(
                      semanticLabel: isSaved ? 'Kaydedildi' : 'Kaydet',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context
                            .read<SocialViewModel>()
                            .toggleListingBookmark(listing.id);
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          listing.status.label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.name,
                      style: GoogleFonts.baloo2(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: Colors.black),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.black
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
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
// DISCOVER FEED POST CARD — wires the standalone, decoupled DiscoverPostCard
// (lib/widgets/discover_post_card.dart) to real SocialViewModel state: pati
// (like) toggle, bookmark toggle, share, and the same view-interaction
// logging + FeedDetailScreen navigation the other feed cards use.
//
// Public (Step 69): reused as-is by SavedItemsScreen, same reasoning as
// [FeedListingCard].
// ─────────────────────────────────────────────────────────────────────────────

class DiscoverFeedPostCard extends StatefulWidget {
  final PostModel post;

  const DiscoverFeedPostCard({super.key, required this.post});

  @override
  State<DiscoverFeedPostCard> createState() => _DiscoverFeedPostCardState();
}

class _DiscoverFeedPostCardState extends State<DiscoverFeedPostCard> {
  bool _patiCountSeeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed the initial pati count so the Selector below has a value before
    // SocialViewModel's Firestore stream sets one — a no-op (putIfAbsent)
    // once the stream has already emitted a count for this post.
    if (!_patiCountSeeded) {
      context
          .read<SocialViewModel>()
          .seedPatiCount(widget.post.id, widget.post.patiCount);
      _patiCountSeeded = true;
    }
  }

  void _openDetail(BuildContext context) {
    // Step 8: log a view interaction on this post's category before
    // navigating, so future feed loads can weight it into the ranking.
    InteractionTrackingService.instance
        .logInteraction(_categoryTag(widget.post), 1.0);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FeedDetailScreen.post(widget.post)),
    );
  }

  void _showCommentsComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Yorumlar — yakında geliyor!',
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
  }

  Future<void> _share(PostModel post) async {
    HapticFeedback.selectionClick();
    final who = post.petName.isNotEmpty ? post.petName : post.authorName;
    final text = post.description.isEmpty
        ? '$who ile ESPATI\'de tanış! 🐾'
        : '$who: ${post.description}\n\n— ESPATI, Eskişehir\'in pati ağı 🐾';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      // Share sheet unavailable on host platform — no-op.
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Selector<SocialViewModel, (bool, int, bool)>(
      selector: (_, vm) => (
        vm.isPostPati(post.id),
        vm.getPatiCount(post.id),
        vm.isPostBookmarked(post.id),
      ),
      builder: (context, state, _) {
        final (isLiked, likeCount, isBookmarked) = state;
        return DiscoverPostCard(
          post: post,
          isLiked: isLiked,
          likeCount: likeCount,
          isBookmarked: isBookmarked,
          onTap: () => _openDetail(context),
          onLikeTap: () {
            HapticFeedback.lightImpact();
            context.read<SocialViewModel>().togglePati(post.id);
          },
          onCommentTap: () => _showCommentsComingSoon(context),
          onShareTap: () => _share(post),
          onBookmarkTap: () {
            HapticFeedback.selectionClick();
            context.read<SocialViewModel>().toggleBookmark(post.id);
          },
        );
      },
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dynamic_feed_rounded,
              size: 56, color: Colors.black),
          const SizedBox(height: 12),
          Text(
            'Henüz gösterilecek içerik yok',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
