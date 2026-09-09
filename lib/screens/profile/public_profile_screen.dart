import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/pet_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/interfaces/i_pet_repository.dart';
import '../../viewmodels/social_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/pet_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC PROFILE SCREEN (Neo-Brutalist pass — aligned to the app's current
// design system, same [NeoBrutal] tokens as [ProfileScreen] itself)
//
// Read-only view of another user's profile. Navigated to when a user taps a
// result card in [SearchScreen].
//
// • Avatar uses a Hero tag keyed on user.id so the image flies from the
//   search tile to this screen with a smooth shared-element transition —
//   must stay in sync with SearchScreen's own avatar Hero tag.
// • Follow/Unfollow is delegated to the globally-scoped [SocialViewModel] so
//   the button state stays in sync with the social feed.
// • No editing controls — this is purely a discovery/follow surface.
// ─────────────────────────────────────────────────────────────────────────────

class PublicProfileScreen extends StatefulWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  StreamSubscription<List<PetModel>>? _petsSubscription;
  List<PetModel> _pets = [];
  bool _petsLoading = true;

  @override
  void initState() {
    super.initState();
    _petsSubscription = context
        .read<IPetRepository>()
        .watchUserPets(widget.user.id)
        .listen(
      (pets) {
        if (mounted) setState(() { _pets = pets; _petsLoading = false; });
      },
      onError: (_) {
        if (mounted) setState(() => _petsLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _petsSubscription?.cancel();
    super.dispose();
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: _PublicProfileAppBar(
        title: user.name.isNotEmpty ? user.name : user.email,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Banner + avatar ────────────────────────────────────────────
          _ProfileBanner(user: user),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.bio.isNotEmpty) ...[
                  Text(user.bio,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.7))),
                  const SizedBox(height: 8),
                ],
                if (user.locationDistrict.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: EspatiColors.lightBlue),
                      const SizedBox(width: 4),
                      Text(user.locationDistrict,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: EspatiColors.lightBlue)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Stats row ─────────────────────────────────────────────
                _BlockyRow(
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatChip(
                            value: _fmt(user.followersCount),
                            label: 'Takipçi'),
                      ),
                      Container(width: 2, height: 36, color: Colors.black),
                      Expanded(
                        child: _StatChip(
                            value: _fmt(user.followingCount), label: 'Takip'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Follow / Unfollow button ───────────────────────────────
                _FollowActionButton(userId: user.id),

                const SizedBox(height: 28),

                // ── Pati Gallery ──────────────────────────────────────────
                if (_petsLoading || _pets.isNotEmpty) ...[
                  const _SectionHeader(
                      icon: Icons.pets_rounded, label: 'Patileri'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: _petsLoading
                        ? const _PublicPetsShimmer()
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pets.length,
                            itemBuilder: (context, i) {
                              final pet = _pets[i];
                              return PetCard(
                                name: pet.name,
                                breed: pet.breed.isNotEmpty
                                    ? pet.breed
                                    : pet.petType.name,
                                imageUrl: pet.photoUrl,
                                age: pet.age > 0 ? '${pet.age} yaş' : '',
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Posts placeholder ─────────────────────────────────────
                const _SectionHeader(
                    icon: Icons.grid_on_rounded, label: 'Gönderiler'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.grid_on_rounded,
                          size: 32, color: Colors.black.withValues(alpha: 0.25)),
                      const SizedBox(height: 8),
                      Text(
                        'Gönderiler yakında burada görünecek',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR — sharp back block + Fredoka title, thick black bottom border on
// the [NeoBrutal.scaffoldBg] canvas. Same convention as every other current-
// generation screen ([ReminderManagerScreen], [ListingFormScreen], ...).
// ─────────────────────────────────────────────────────────────────────────────

class _PublicProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const _PublicProfileAppBar({required this.title});

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
                onPressed: () => Navigator.of(context).maybePop(),
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
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.black,
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
// PATI GALLERY SHIMMER (read-only, used in public profile)
// ─────────────────────────────────────────────────────────────────────────────

class _PublicPetsShimmer extends StatelessWidget {
  const _PublicPetsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: NeoBrutal.inactiveFill,
      highlightColor: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: NeoBrutal.border(2),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE BANNER — solid accent block behind a square Neo-Brutalist avatar,
// matching [ProfileScreen]'s own avatar language (was a soft circular
// gradient ring with no border/shadow).
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBanner extends StatelessWidget {
  final UserModel user;

  const _ProfileBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: EspatiColors.terracotta,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: NeoBrutal.borderWidth),
        ),
      ),
      child: Center(
        child: Hero(
          tag: 'avatar_${user.id}',
          child: Container(
            width: 100,
            height: 100,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.zero,
              border: NeoBrutal.border(3),
              boxShadow: NeoBrutal.shadow(const Offset(4, 4)),
            ),
            child: user.profilePicture.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: user.profilePicture,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 44,
                        color: Colors.black),
                  )
                : const Icon(Icons.person_rounded,
                    size: 44, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOLLOW ACTION BUTTON — full-width Neo-Brutalist block, backed by
// [SocialViewModel]. Filled terracotta when not followed (call to action);
// flat white/black-border when already followed (secondary/undo state).
// ─────────────────────────────────────────────────────────────────────────────

class _FollowActionButton extends StatelessWidget {
  final String userId;
  const _FollowActionButton({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Selector<SocialViewModel, bool>(
      selector: (_, vm) => vm.isUserFollowed(userId),
      builder: (ctx, isFollowed, _) {
        return NeoBrutalistButton(
          semanticLabel: isFollowed ? 'Takibi Bırak' : 'Takip Et',
          onPressed: () {
            HapticFeedback.selectionClick();
            ctx.read<SocialViewModel>().toggleFollow(userId);
          },
          child: Container(
            width: double.infinity,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFollowed ? Colors.white : EspatiColors.terracotta,
              borderRadius: BorderRadius.zero,
              border: NeoBrutal.border(2.5),
              boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
            ),
            child: Text(
              isFollowed ? 'Takibi Bırak' : 'Takip Et',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SUPPORTING WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// White/black-bordered/hard-shadow frame — same convention as every other
/// `_BlockyField`-style container across the app's current screens.
class _BlockyRow extends StatelessWidget {
  final Widget child;

  const _BlockyRow({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2),
        boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: EspatiColors.terracotta),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
