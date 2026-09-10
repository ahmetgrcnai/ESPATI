import 'package:flutter/material.dart';

// Root-level rich screens
import 'community/community_hub_screen.dart';

// Subdir rich screens (full implementations)
import 'discovery/algorithmic_feed_screen.dart';
import 'discovery/paties_viewer_screen.dart';
import 'discovery/poi_map_screen.dart';
import 'profile/profile_screen.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/draggable_ai_fab.dart';

/// Root scaffold — 5-tab floating neo-brutalist bottom navigation
/// ([EspatiBottomNavBar], Design System Step 3), and a global draggable
/// Pati-AI bubble overlaying every tab. IndexedStack preserves tab state.
///
/// The "Create" action lived as its own embedded slot in this bar for one
/// step (Design System Step 14, replacing an even earlier floating FAB)
/// before Step 15 moved it into the Explore tab's AppBar (Instagram-style,
/// via [AlgorithmicFeedScreen]'s leading blocky "+" button, Step 35's
/// Neo-Brutalist replacement for the original [CrossedBonesIcon]), which
/// made the bottom-nav copy redundant — Step 16 removed it again, back to
/// exactly the 5 real destinations below with perfectly even spacing.
///
/// Tab order:
///   0 → Keşfet      → AlgorithmicFeedScreen (scrolling mixed-content feed)
///   1 → Harita      → PoiMapScreen          (Design System Step 12 — promoted
///                                            from a pushed route to a tab;
///                                            still also reachable via Keşfet's
///                                            "🗺️ Haritada Gör" button)
///   2 → Topluluk    → CommunityHubScreen    (Sub-Reddit-style community groups)
///   3 → Paties      → PatiesViewerScreen    (Shorts/Reels UI skeleton)
///   4 → Profil      → ProfileScreen         (User stats, pets grid, settings)
///
/// ── PHASE 3 STEP 10 — Pati-AI goes global, Paties becomes a tab ────────────
/// The Pati-AI tab ([AiVetScreen]) is no longer a fixed bottom-nav
/// destination. It's now reachable from anywhere via [DraggableAIFab], a
/// Messenger-chat-head-style bubble that floats over every tab (see the
/// [Stack] in [build] below) and pushes [AiVetScreen] on tap. That freed the
/// tab slot for [PatiesViewerScreen], which used to be reached only via a
/// horizontal carousel on [AlgorithmicFeedScreen] (now removed — Paties has
/// its own tab, the carousel was redundant).
///
/// ── PHASE 3 STEP 6 — "Summit A": Keşfet becomes a feed, map moves off-tab ──
/// Tab 0 used to be [PoiMapScreen] (né `UnifiedDiscoveryScreen`), a
/// full-screen POI map. Per the Summit A pivot toward an algorithmic
/// recommendation feed, that map is no longer a root tab — it's a normal
/// pushed route reached via the "🗺️ Haritada Gör" button in
/// [AlgorithmicFeedScreen]'s app bar (Airbnb-style list⇄map).
///
/// ── PHASE 2 STEP 4 — Sosyal/Forum retirement ────────────────────────────────
/// The old "Sosyal" tab (Instagram-style post feed) and "Forum" (İlanlar +
/// Mesajlar) screens are both deleted. Posts + listings are now browsable
/// inside [CommunityHubScreen] group feeds and [AlgorithmicFeedScreen];
/// Mesajlar (the sole PII-safe comms channel, Step 1) is a standalone
/// [InboxScreen] reachable from [ProfileScreen]'s app bar; user search moved
/// to [CommunityHubScreen]'s app bar.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  /// True while [AlgorithmicFeedScreen]'s internal PageView is showing the
  /// Story camera page — the floating nav bar overlay hides itself then,
  /// mirroring Instagram (see [_screens] and the [onCameraPageActive] wiring
  /// below).
  bool _hideNavBar = false;

  void _setCameraActive(bool active) {
    if (_hideNavBar == active) return;
    setState(() => _hideNavBar = active);
  }

  // Built per-build (not `static const`) since AlgorithmicFeedScreen now
  // needs an instance-bound callback — Flutter still preserves each screen's
  // State across rebuilds via IndexedStack's same-position element reuse, so
  // this costs nothing over the old const list.
  List<Widget> get _screens => [
        AlgorithmicFeedScreen(onCameraPageActive: _setCameraActive),
        const PoiMapScreen(),
        const CommunityHubScreen(),
        PatiesViewerScreen(isTabActive: _currentIndex == 3),
        const ProfileScreen(),
      ];

  // ── Floating nav geometry (Design System Step 3) ──────────────────────────
  // The nav bar no longer reserves layout space via Scaffold.bottomNavigationBar
  // — it's a Positioned overlay inside the body Stack.
  static const double _navBarBottomMargin = 24;
  static const double _navBarHorizontalMargin = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No floatingActionButton / floatingActionButtonLocation — "Create"
      // now lives in AlgorithmicFeedScreen's own AppBar (Design System
      // Step 15), not here. Stack: the active tab underneath, the
      // draggable Pati-AI bubble and floating nav bar layered on top, in
      // that order, so the nav bar stays reachable above the bubble.
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          const DraggableAIFab(),

          // ── Floating neo-brutalist nav bar — 5 real destinations only ──
          // Slides/fades out while the Story camera page is active so it
          // never sits on top of the live camera preview (index 0 of
          // AlgorithmicFeedScreen's PageView).
          Positioned(
            left: _navBarHorizontalMargin,
            right: _navBarHorizontalMargin,
            bottom: _navBarBottomMargin,
            child: IgnorePointer(
              ignoring: _hideNavBar,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                offset: _hideNavBar ? const Offset(0, 2) : Offset.zero,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _hideNavBar ? 0 : 1,
                  child: EspatiBottomNavBar(
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
