import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/chat_group_model.dart';
import '../../data/models/group_member_model.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/interfaces/i_pet_repository.dart';
import '../../data/repositories/interfaces/i_post_repository.dart';
import '../../data/repositories/interfaces/i_social_repository.dart';
import '../../services/interaction_tracking_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/create_post_viewmodel.dart';
import '../../viewmodels/form_viewmodel.dart';
import '../../viewmodels/social_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../feed_detail_screen.dart';
import 'create_topic_screen.dart';
import 'group_members_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GROUP DETAIL SCREEN — Sub-Reddit-style mixed feed for one community group
// (Phase 2 Step 4).
//
// Merges the app's existing live [FormViewModel] listings and
// [SocialViewModel] posts into one heterogeneous, chronologically sorted
// feed, filtered to items whose [ListingModel.groupId] / [PostModel.groupId]
// matches [group.id] (set via the group selector on the listing/post
// creation forms). Items created with no group selected (groupId == null)
// are intentionally general-feed-only and never appear here.
//
// DESIGN SYSTEM PASS — matches the sharp Neo-Brutalist system [ProfileScreen]
// / [AlgorithmicFeedScreen] (Keşfet) run on: zero-radius white/[EspatiColors]
// blocks with a solid black border + hard offset shadow, [NeoBrutalistButton]
// press feedback, hardcoded `Colors.black` text — replacing the older
// rounded `NeoBrutalism`/legacy `AppColors` look this screen used to carry.
// ─────────────────────────────────────────────────────────────────────────────

class GroupDetailScreen extends StatelessWidget {
  final ChatGroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final cat = group.petCategory;

    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBrutalistButton(
              semanticLabel: 'Geri',
              onPressed: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                  border: NeoBrutal.border(2),
                  boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.black, size: 20),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cat.accentColor,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(2),
              ),
              child: group.coverImageUrl.isEmpty
                  ? Icon(cat.icon, color: Colors.black, size: 18)
                  : CachedNetworkImage(
                      imageUrl: group.coverImageUrl,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(cat.icon, color: Colors.black, size: 18),
                      errorWidget: (_, __, ___) => Icon(cat.icon, color: Colors.black, size: 18),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                group.name,
                style: GoogleFonts.baloo2(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Consumer2<FormViewModel, SocialViewModel>(
        builder: (context, formVm, socialVm, _) {
          final items = _mergedFeed(formVm.allListings, socialVm.feedPosts);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _GroupInfoBanner(group: group),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const _EmptyFeed()
              else
                for (final item in items) ...[
                  if (item is ListingModel)
                    _CommunityListingCard(listing: item)
                  else if (item is PostModel)
                    _CommunityPostCard(post: item),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
      floatingActionButton: NeoBrutalistButton(
        semanticLabel: 'Konu Aç',
        onPressed: () => _openCreateTopic(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: EspatiColors.mintGreen,
            borderRadius: BorderRadius.zero,
            border: NeoBrutal.border(2),
            boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_rounded, size: 18, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                'Konu Aç',
                style: GoogleFonts.baloo2(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Screen-scoped CreatePostViewModel, pre-seeded with this group's id — the
  // group is fixed (the user is already inside it, so there's nothing to
  // pick) and passed straight to the ViewModel; [CreateTopicScreen] never
  // shows a group selector.
  //
  // [CreateTopicScreen.canAnnounce] needs the *current* user's role in
  // *this* group, which isn't cached anywhere on this screen — a one-shot
  // read of [ISocialRepository.watchGroupMembers]' first snapshot answers
  // that without standing up a whole extra stream subscription just for
  // this one button press.
  Future<void> _openCreateTopic(BuildContext context) async {
    final postRepo = context.read<IPostRepository>();
    final petRepo = context.read<IPetRepository>();
    final socialRepo = context.read<ISocialRepository>();
    final user = context.read<AuthViewModel>().currentUser;

    final members = await socialRepo.watchGroupMembers(group.id).first;
    final myRole = members
        .where((m) => m.uid == user?.id)
        .map((m) => m.role)
        .firstOrNull;
    final canAnnounce = myRole == GroupMemberRole.owner ||
        myRole == GroupMemberRole.moderator;

    if (!context.mounted) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<CreatePostViewModel>(
          create: (_) => CreatePostViewModel(
            postRepository: postRepo,
            petRepository: petRepo,
            currentUser: user,
            initialGroupId: group.id,
            groupBannedWords: group.bannedWords,
          ),
          child: CreateTopicScreen(canAnnounce: canAnnounce),
        ),
      ),
    );
  }

  /// Interleaves this group's listings + posts by recency, excluding
  /// anything a moderation pass has flagged (Madde 8 safety mandate —
  /// isApproved defaults to true, so legacy records are unaffected).
  /// Announcement posts ([PostModel.isAnnouncement]) always float above
  /// everything else, most recent first among themselves.
  List<Object> _mergedFeed(List<ListingModel> listings, List<PostModel> posts) {
    final items = <Object>[
      ...listings.where((l) => l.isApproved && l.groupId == group.id),
      ...posts.where((p) => p.isApproved && p.groupId == group.id),
    ];
    items.sort((a, b) {
      final aPinned = a is PostModel && a.isAnnouncement;
      final bPinned = b is PostModel && b.isAnnouncement;
      if (aPinned != bPinned) return aPinned ? -1 : 1;
      final aDate = a is ListingModel ? a.createdAt : (a as PostModel).timestamp;
      final bDate = b is ListingModel ? b.createdAt : (b as PostModel).timestamp;
      return bDate.compareTo(aDate);
    });
    return items;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GROUP INFO BANNER — description + real member count + real "Katıl" button.
//
// [ChatGroupModel.memberCount] is a denormalized counter kept in sync by
// [FirestoreSocialRepository.toggleGroupMembership]'s transaction, but
// [FormViewModel.loadAll]/`getChatGroups()` is a one-time fetch, not a live
// listener (see that method's own doc comment) — so without
// [FormViewModel.adjustGroupMemberCount] the count shown here would stay
// stale immediately after the user's own join/leave until the next full
// reload, even though the real Firestore value already changed.
// ─────────────────────────────────────────────────────────────────────────────

class _GroupInfoBanner extends StatelessWidget {
  final ChatGroupModel group;
  const _GroupInfoBanner({required this.group});

  void _toggleMembership(BuildContext context, bool wasMember) {
    HapticFeedback.selectionClick();
    final me = context.read<AuthViewModel>().currentUser;
    context.read<SocialViewModel>().toggleGroupMembership(
          group.id,
          memberName: me == null || me.name.isEmpty ? (me?.email ?? '') : me.name,
          memberPhoto: me?.profilePicture ?? '',
        );
    context
        .read<FormViewModel>()
        .adjustGroupMemberCount(group.id, wasMember ? -1 : 1);
  }

  void _openMembers(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupMembersScreen(group: group)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2),
        boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.customCategory != null &&
              group.customCategory!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: EspatiColors.sageGreen.withValues(alpha: 0.3),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Text(
                '#${group.customCategory}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            group.description,
            style: GoogleFonts.nunitoSans(fontSize: 13, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => _openMembers(context),
                child: Row(
                  children: [
                    Icon(Icons.people_alt_rounded,
                        size: 13, color: Colors.black.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      '${group.memberCount} üye',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.7),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Selector<SocialViewModel, bool>(
                selector: (_, vm) => vm.isGroupMember(group.id),
                builder: (context, isMember, _) => NeoBrutalistButton(
                  semanticLabel: isMember ? 'Gruptan ayrıl' : 'Gruba katıl',
                  onPressed: () => _toggleMembership(context, isMember),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: isMember ? Colors.white : EspatiColors.sageGreen,
                      borderRadius: BorderRadius.zero,
                      border: NeoBrutal.border(2),
                      boxShadow:
                          isMember ? null : NeoBrutal.shadow(const Offset(2, 2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isMember
                              ? Icons.check_circle_rounded
                              : Icons.add_rounded,
                          size: 16,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isMember ? 'Üyesin' : 'Katıl',
                          style: GoogleFonts.baloo2(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMUNITY LISTING CARD — compact ListingModel item in the mixed feed
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityListingCard extends StatelessWidget {
  final ListingModel listing;

  const _CommunityListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final statusColor = listing.status.accentColor;
    final statusIcon = listing.status.icon;

    return NeoBrutalistButton(
      onPressed: () {
        // Step 8: log a view interaction on this listing's category before
        // navigating — feeds Summit A's interest_scores weighting.
        InteractionTrackingService.instance
            .logInteraction(_categoryTag(listing), 1.0);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FeedDetailScreen.listing(listing)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
          boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRect(
              child: CachedNetworkImage(
                imageUrl: listing.imageUrl,
                width: 90,
                height: 110,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 90,
                  height: 110,
                  color: NeoBrutal.inactiveFill,
                  child: const Icon(Icons.pets, size: 30, color: Colors.black),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 90,
                  height: 110,
                  color: NeoBrutal.inactiveFill,
                  child: const Icon(Icons.pets, size: 30, color: Colors.black),
                ),
              ),
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
                        fontWeight: FontWeight.w600,
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
                            size: 12, color: EspatiColors.sageGreen),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: const TextStyle(
                                fontSize: 11,
                                color: EspatiColors.sageGreen,
                                fontWeight: FontWeight.w600),
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
// COMMUNITY POST CARD — compact PostModel item in the mixed feed
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityPostCard extends StatelessWidget {
  final PostModel post;

  const _CommunityPostCard({required this.post});

  static String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}sa önce';
    if (diff.inDays < 7) return '${diff.inDays}g önce';
    return '${(diff.inDays / 7).floor()}h önce';
  }

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      onPressed: () {
        // Step 8: log a view interaction on this post's category before
        // navigating — feeds Summit A's interest_scores weighting.
        InteractionTrackingService.instance
            .logInteraction(_categoryTag(post), 1.0);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FeedDetailScreen.post(post)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: post.isAnnouncement ? EspatiColors.peach.withValues(alpha: 0.25) : Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(post.isAnnouncement ? 2.5 : 2),
          boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text-only posts (empty imageUrl) skip the thumbnail entirely
            // rather than showing a generic paw-icon placeholder for
            // content that never had an image.
            if (post.imageUrl.isNotEmpty) ...[
              ClipRect(
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl,
                  width: 66,
                  height: 66,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 66,
                    height: 66,
                    color: NeoBrutal.inactiveFill,
                    child: const Icon(Icons.pets, size: 24, color: Colors.black),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 66,
                    height: 66,
                    color: NeoBrutal.inactiveFill,
                    child: const Icon(Icons.pets, size: 24, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.isAnnouncement) ...[
                    Row(
                      children: [
                        const Icon(Icons.push_pin_rounded,
                            size: 13, color: Colors.black),
                        const SizedBox(width: 3),
                        Text(
                          'DUYURU',
                          style: GoogleFonts.baloo2(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.authorName,
                          style: GoogleFonts.baloo2(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(post.timestamp),
                        style: GoogleFonts.nunitoSans(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.pets, size: 13, color: EspatiColors.sageGreen),
                      const SizedBox(width: 3),
                      Text('${post.patiCount}',
                          style: GoogleFonts.nunitoSans(
                              fontSize: 11, color: Colors.black.withValues(alpha: 0.55))),
                      const SizedBox(width: 10),
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 13, color: Colors.black.withValues(alpha: 0.4)),
                      const SizedBox(width: 3),
                      Text('${post.commentsCount}',
                          style: GoogleFonts.nunitoSans(
                              fontSize: 11, color: Colors.black.withValues(alpha: 0.55))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.dynamic_feed_rounded,
                size: 56, color: Colors.black.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              'Bu toplulukta henüz içerik yok',
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The interest tag an item is tracked under for Summit A's
/// interest_scores weighting (Step 7/8) — a [ListingModel]'s structured
/// species facet ("Kedi", "Köpek", ...) or a [PostModel]'s breed (falling
/// back to its denormalized species type), matching
/// [AlgorithmicFeedScreen]'s own tagging so a signal logged here also
/// affects that feed's ranking. Falls back to 'Diğer' for legacy records
/// missing both fields.
String _categoryTag(Object item) {
  if (item is ListingModel) {
    return item.species.isNotEmpty ? item.species : 'Diğer';
  }
  final post = item as PostModel;
  if (post.petBreed.isNotEmpty) return post.petBreed;
  if (post.petType.isNotEmpty) return post.petType;
  return 'Diğer';
}
