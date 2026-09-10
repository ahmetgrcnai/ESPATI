import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/post_model.dart';
import '../../viewmodels/form_viewmodel.dart';
import '../../viewmodels/social_viewmodel.dart';
import '../discovery/algorithmic_feed_screen.dart'
    show FeedListingCard, DiscoverFeedPostCard;

// ─────────────────────────────────────────────────────────────────────────────
// SAVED ITEMS SCREEN — "Kaydedilenler" (Design System Step 69)
//
// Reachable from SettingsScreen. Shows every bookmarked post
// ([SocialViewModel.isPostBookmarked]) and every saved listing
// ([SocialViewModel.isListingBookmarked]) in one place, newest-saved-content
// first.
//
// Deliberately renders with the exact same [FeedListingCard]/
// [DiscoverFeedPostCard] widgets the Keşfet feed uses (made public for this
// reason) instead of a second, parallel set of "saved" card widgets — one
// card language, not two that could quietly drift apart. Un-bookmarking an
// item here works exactly like it does in the feed (tap the same bookmark
// icon) and the item disappears from this screen on the next rebuild since
// it's filtered live from [SocialViewModel]'s state, not a separate fetch.
//
// No dedicated "saved-at" timestamp is read back from Firestore for
// ordering — [SocialViewModel] only exposes bookmarked *ids*, not the
// bookmark documents' own `savedAt` field. Sorting instead falls back to
// each item's own content date (post/listing creation time), which is what
// [AlgorithmicFeedScreen]'s recency fallback already does — consistent with
// the rest of the app rather than a new ordering concept for this one screen.
// ─────────────────────────────────────────────────────────────────────────────

class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  DateTime _itemDate(Object item) =>
      item is ListingModel ? item.createdAt : (item as PostModel).timestamp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Kaydedilenler',
          style: GoogleFonts.baloo2(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: Consumer2<SocialViewModel, FormViewModel>(
        builder: (context, socialVm, formVm, _) {
          final items = <Object>[
            ...formVm.allListings
                .where((l) => socialVm.isListingBookmarked(l.id)),
            ...socialVm.feedPosts.where((p) => socialVm.isPostBookmarked(p.id)),
          ]..sort((a, b) => _itemDate(b).compareTo(_itemDate(a)));

          if (items.isEmpty) {
            return const _EmptySaved();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              if (item is ListingModel) {
                return FeedListingCard(listing: item);
              }
              return DiscoverFeedPostCard(post: item as PostModel);
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE — same blocky icon-over-caption shape as [_EmptyFeed] in
// AlgorithmicFeedScreen, not re-exported from there since it's file-private
// and this screen's copy needs its own bookmark-flavored icon/caption.
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border_rounded,
                size: 56, color: Colors.black),
            const SizedBox(height: 12),
            Text(
              'Henüz bir şey kaydetmedin',
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Beğendiğin gönderi ve ilanları kaydet, hepsini burada bul.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
