import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/chat_group_model.dart';
import '../../data/repositories/interfaces/i_user_repository.dart';
import '../../viewmodels/form_viewmodel.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/upcoming_reminders_banner.dart';
import '../search/search_screen.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COMMUNITY HUB SCREEN — "Topluluk" tab (Phase 2 Step 4)
//
// Sub-Reddit-style entry point: a flat list of predefined community groups
// ("Kedi Sahipleri", "Acil İlanlar", ...). Tapping one opens
// [GroupDetailScreen], the mixed post+listing feed for that group.
//
// Data source: [FormViewModel.chatGroups] ([ChatGroupModel]) — the same
// group records the old Forum's "Gruplar" sub-tab used to list. That
// sub-tab never had a working chat thread behind it (tapping a group only
// marked it read), so repurposing the model as the backbone of Topluluk's
// community list doesn't remove any working feature — it gives these
// records their first real destination screen. No new Firestore writes or
// fabricated backend data were introduced for this screen.
//
// [UpcomingRemindersBanner] (Phase 2 Step 5) sits above the group list per
// the CTO's "Madde 6" retention mandate — placed here specifically since
// this screen is a pristine ListView where a conditional header is safe
// and highly visible whenever the user browses groups.
//
// DESIGN SYSTEM PASS — this screen now matches the sharp Neo-Brutalist
// system [ProfileScreen] and [AlgorithmicFeedScreen] (Keşfet) already run
// on: [NeoBrutal.scaffoldBg] canvas, zero-radius [EspatiColors]-accented
// blocks with a solid black border + hard offset shadow, [NeoBrutalistButton]
// press feedback, `GoogleFonts.baloo2` headers, hardcoded `Colors.black`
// text rather than theme-derived colors — replacing the older rounded
// `NeoBrutalism`/legacy `AppColors` look this screen used to carry.
// ─────────────────────────────────────────────────────────────────────────────

class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.groups_rounded, color: Colors.black, size: 24),
            const SizedBox(width: 8),
            Text(
              'Topluluk',
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          NeoBrutalistButton(
            semanticLabel: 'Grup Oluştur',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EspatiColors.mintGreen,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(2),
                boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.black, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          NeoBrutalistButton(
            semanticLabel: 'Kullanıcı Ara',
            onPressed: () {
              // SearchViewModel is created fresh per route (factory pattern)
              // and disposed automatically when the screen pops — same
              // pattern the old SocialScreen used for user search.
              final userRepo = context.read<IUserRepository>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => SearchViewModel(userRepository: userRepo),
                    child: const SearchScreen(),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EspatiColors.lightBlue,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(2),
                boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
              ),
              child: const Icon(Icons.search_rounded,
                  color: Colors.black, size: 20),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // ── FOMO countdown banner (Phase 2 Step 5 / "Madde 6") ──────────
          // Always mounted so it can render on first frame regardless of
          // the group list's own loading state; collapses to zero space
          // internally when there's nothing due within its window.
          const UpcomingRemindersBanner(),
          Expanded(
            child: Consumer<FormViewModel>(
              builder: (context, vm, _) {
                if (vm.isLoading && vm.chatGroups.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: EspatiColors.peach),
                  );
                }
                if (vm.chatGroups.isEmpty) {
                  return _EmptyGroups(onRetry: vm.loadAll);
                }
                return ListView.builder(
                  // Bottom: 100 — clears the floating nav bar (Design
                  // System Step 3), which now overlays the body instead of
                  // reserving its own Scaffold layout space.
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: vm.chatGroups.length,
                  itemBuilder: (context, index) {
                    final group = vm.chatGroups[index];
                    return _CommunityGroupCard(
                      group: group,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(group: group),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMUNITY GROUP CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityGroupCard extends StatelessWidget {
  final ChatGroupModel group;
  final VoidCallback onTap;

  const _CommunityGroupCard({
    required this.group,
    required this.onTap,
  });

  String _formatMemberCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k üye';
    return '$n üye';
  }

  @override
  Widget build(BuildContext context) {
    final cat = group.petCategory;

    return NeoBrutalistButton(
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
          boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cat.accentColor,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(2),
              ),
              child: group.coverImageUrl.isEmpty
                  ? Icon(cat.icon, color: Colors.black, size: 26)
                  : CachedNetworkImage(
                      imageUrl: group.coverImageUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(cat.icon, color: Colors.black, size: 26),
                      errorWidget: (_, __, ___) => Icon(cat.icon, color: Colors.black, size: 26),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (group.isPinned) ...[
                        const Icon(Icons.push_pin_rounded,
                            size: 13, color: Colors.black),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          group.name,
                          style: GoogleFonts.baloo2(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (group.customCategory != null &&
                      group.customCategory!.isNotEmpty) ...[
                    Text(
                      '#${group.customCategory}',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: EspatiColors.sageGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    group.description,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people_alt_rounded,
                          size: 13, color: Colors.black.withValues(alpha: 0.45)),
                      const SizedBox(width: 4),
                      Text(
                        _formatMemberCount(group.memberCount),
                        style: GoogleFonts.nunitoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.black, size: 22),
          ],
        ),
      ),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyGroups({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined,
              size: 64, color: Colors.black.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            'Henüz topluluk grubu yok',
            style: GoogleFonts.nunitoSans(
              fontSize: 15,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          NeoBrutalistButton(
            onPressed: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: EspatiColors.mintGreen,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(2),
                boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
              ),
              child: Text(
                'Tekrar Dene',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
