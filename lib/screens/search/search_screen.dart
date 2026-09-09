import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../../viewmodels/social_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../profile/public_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH SCREEN (Neo-Brutalist pass — aligned to the app's current design
// system, same [NeoBrutal] tokens as Keşfet/[ProfileScreen]/
// [PublicProfileScreen])
//
// State machine (driven by SearchViewModel.state):
//   initial → _IdleSplash       (paw illustration + hint copy)
//   loading → _ShimmerList      (8 animated skeleton rows)
//   success → _ResultsList      (UserModel tiles with Hero avatar + follow block)
//   empty   → _NoResultsView    (search_off icon + query echo)
//   error   → snackbar + idle   (non-blocking, surfaces once)
//
// Architecture:
//   • SearchViewModel is injected by the CALLER via a scoped
//     ChangeNotifierProvider (factory pattern — fresh instance per push,
//     auto-disposed on pop).
//   • Follow state is read from the globally-scoped SocialViewModel so results
//     stay in sync with the social feed.
//   • Avatar uses a Hero tag 'avatar_{uid}' shared with PublicProfileScreen
//     for a smooth shared-element transition.
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focus = FocusNode();

    // Auto-focus the search field so the keyboard appears immediately.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());

    // Surface error messages as one-shot SnackBars.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchViewModel>().addListener(_onVMChanged);
    });
  }

  @override
  void dispose() {
    context.read<SearchViewModel>().removeListener(_onVMChanged);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onVMChanged() {
    final vm = context.read<SearchViewModel>();
    if (vm.state == SearchState.error && vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(vm.errorMessage!, style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.black, width: 2),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      vm.clearError();
    }
  }

  void _clear() {
    _ctrl.clear();
    context.read<SearchViewModel>().clearSearch();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: _SearchAppBar(
        controller: _ctrl,
        focusNode: _focus,
        onChanged: (q) => context.read<SearchViewModel>().onQueryChanged(q),
        onClear: _clear,
        onBack: () {
          _focus.unfocus();
          Navigator.of(context).pop();
        },
      ),
      body: Consumer<SearchViewModel>(
        builder: (ctx, vm, _) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _body(ctx, vm),
        ),
      ),
    );
  }

  Widget _body(BuildContext ctx, SearchViewModel vm) {
    switch (vm.state) {
      case SearchState.initial:
        return const _IdleSplash(key: ValueKey('idle'));
      case SearchState.loading:
        return const _ShimmerList(key: ValueKey('shimmer'));
      case SearchState.success:
        return _ResultsList(
          key: const ValueKey('results'),
          results: vm.searchResults,
        );
      case SearchState.empty:
        return _NoResultsView(
            key: const ValueKey('empty'), query: vm.lastQuery);
      case SearchState.error:
        // Error was already surfaced as a snackbar; fall back to idle.
        return const _IdleSplash(key: ValueKey('idle-err'));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR — sharp back block + inline blocky search field, thick black
// bottom border on the [NeoBrutal.scaffoldBg] canvas. Same convention as
// every other current-generation screen.
// ─────────────────────────────────────────────────────────────────────────────

class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onBack;

  const _SearchAppBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: NeoBrutal.scaffoldBg,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: NeoBrutal.borderWidth),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              NeoBrutalistButton(
                semanticLabel: 'Geri',
                onPressed: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(2.5),
                    boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.black, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(2),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      const Icon(Icons.search_rounded,
                          size: 20, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: onChanged,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            hintText: 'Kullanıcı ara...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textInputAction: TextInputAction.search,
                          cursorColor: Colors.black,
                          cursorWidth: 1.5,
                        ),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller,
                        builder: (_, value, __) {
                          if (value.text.isEmpty) return const SizedBox(width: 8);
                          return GestureDetector(
                            onTap: onClear,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.cancel_rounded,
                                size: 18,
                                color: Colors.black45,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER LIST — 8 skeleton rows, one shared AnimationController
//
// All rows share a single AnimationController tick so they sweep in unison.
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerList extends StatefulWidget {
  const _ShimmerList({super.key});

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // The shimmer highlight sweeps from x = -1.5 to x = 1.5 in normalised coords.
  late Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _sweep = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweep,
      builder: (_, __) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: 8,
        itemBuilder: (_, __) => _SkeletonRow(sweepX: _sweep.value),
      ),
    );
  }
}

/// One skeleton row — avatar square + two text bars + block button.
class _SkeletonRow extends StatelessWidget {
  final double sweepX;

  const _SkeletonRow({required this.sweepX});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2),
      ),
      child: Row(
        children: [
          _shimmerBox(52, 52, sweepX),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(120, 13, sweepX),
                const SizedBox(height: 7),
                _shimmerBox(180, 11, sweepX),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _shimmerBox(84, 30, sweepX),
        ],
      ),
    );
  }

  static Widget _shimmerBox(double w, double h, double sweepX) {
    const base = Color(0xFFE8E8E8);
    const highlight = Color(0xFFF4F4F4);

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
        gradient: LinearGradient(
          begin: Alignment(sweepX - 1, 0),
          end: Alignment(sweepX + 1, 0),
          colors: const [base, highlight, base],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULTS LIST
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final List<UserModel> results;
  const _ResultsList({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length,
      itemBuilder: (ctx, i) => _UserTile(user: results[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER TILE — single result row, white block card with hard shadow
//
// Layout:
//   [52px Hero avatar] [name / bio stack] [follow block]
//
// • Hero tag 'avatar_{uid}' animates into PublicProfileScreen.
// • Follow button is a Selector on SocialViewModel.isUserFollowed — rebuilds
//   only when THIS user's follow state changes.
// • Current user's own tile is hidden (guard via AuthViewModel).
// ─────────────────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    // Guard: never show the signed-in user in their own search results.
    final currentUid = context.read<AuthViewModel>().currentUser?.id;
    if (user.id == currentUid) return const SizedBox.shrink();

    return NeoBrutalistButton(
      semanticLabel: user.name.isNotEmpty ? user.name : user.email,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(user: user),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
          boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
        ),
        child: Row(
          children: [
            // ── Avatar with Hero animation ────────────────────────────────
            Hero(
              tag: 'avatar_${user.id}',
              child: Container(
                width: 52,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: EspatiColors.terracotta,
                  borderRadius: BorderRadius.zero,
                  border: NeoBrutal.border(2),
                ),
                child: user.profilePicture.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: user.profilePicture,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 26,
                            color: Colors.black),
                      )
                    : const Icon(Icons.person_rounded,
                        size: 26, color: Colors.black),
              ),
            ),
            const SizedBox(width: 14),

            // ── Name + bio ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : user.email,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.bio,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (user.locationDistrict.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.locationDistrict,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EspatiColors.lightBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),

            // ── Follow block — rebuilds only when this user's state changes ──
            Selector<SocialViewModel, bool>(
              selector: (_, vm) => vm.isUserFollowed(user.id),
              builder: (ctx, isFollowed, _) => _FollowBlock(
                isFollowed: isFollowed,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ctx.read<SocialViewModel>().toggleFollow(user.id);
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
// FOLLOW BLOCK — Takip Et ↔ Takibi Bırak, matching PublicProfileScreen's
// follow button styling in miniature.
// ─────────────────────────────────────────────────────────────────────────────

class _FollowBlock extends StatelessWidget {
  final bool isFollowed;
  final VoidCallback onTap;
  const _FollowBlock({required this.isFollowed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowed ? Colors.white : EspatiColors.terracotta,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(1.5),
        ),
        child: Text(
          isFollowed ? 'Takibi Bırak' : 'Takip Et',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IDLE SPLASH — shown before the user types anything
// ─────────────────────────────────────────────────────────────────────────────

class _IdleSplash extends StatelessWidget {
  const _IdleSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EspatiColors.terracotta,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(3),
                boxShadow: NeoBrutal.shadow(const Offset(4, 4)),
              ),
              child: const Icon(
                Icons.manage_search_rounded,
                size: 48,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pati dostu ara',
              style: GoogleFonts.fredoka(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İsim yazarak Espati\'deki\npet sahiplerini bul ve takip et 🐾',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.5),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NO RESULTS VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _NoResultsView extends StatelessWidget {
  final String query;
  const _NoResultsView({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(2.5),
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 44, color: Colors.black.withValues(alpha: 0.35)),
            ),
            const SizedBox(height: 20),
            Text(
              '"$query" için sonuç bulunamadı',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı bir isim deneyebilirsin.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
