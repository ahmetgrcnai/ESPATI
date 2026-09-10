import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/neo_brutalist_tokens.dart';

/// A single entry the [StoryTray] renders as a [StoryBubble] — deliberately
/// not [StoryModel] itself: that model has no denormalized author
/// name/photo yet (Stories aren't a built-out feature — [SocialViewModel]
/// already wires `getStories()` live, it just always returns an empty list
/// today), so this is the shape the tray actually needs, ready for
/// whichever screen maps real [StoryModel]s onto it once that denormalization
/// exists.
class StoryTrayItem {
  final String id;
  final String imageUrl;
  final String label;
  final bool isUnseen;

  const StoryTrayItem({
    required this.id,
    required this.imageUrl,
    required this.label,
    required this.isUnseen,
  });
}

/// Instagram-style horizontal Story tray (Design System Step 18).
///
/// Index 0 is always the current user's "Sen" / Add-Story bubble; [stories]
/// follow after it.
class StoryTray extends StatelessWidget {
  final List<StoryTrayItem> stories;
  final String currentUserName;
  final String currentUserPhotoUrl;
  final VoidCallback onAddStory;
  final ValueChanged<StoryTrayItem>? onStoryTap;

  const StoryTray({
    super.key,
    required this.stories,
    required this.currentUserName,
    required this.currentUserPhotoUrl,
    required this.onAddStory,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    // Step 49 — compact footprint (was 116 + 8px vertical ListView padding
    // = ~132 total): 96 + 4px padding keeps the blocky avatar, its unseen
    // ring, and label on one comfortable line while giving the feed below
    // more of the fold, Instagram-density-style.
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _AddStoryBubble(
              label: currentUserName.isNotEmpty ? currentUserName : 'Sen',
              imageUrl: currentUserPhotoUrl,
              onTap: onAddStory,
            );
          }
          final story = stories[index - 1];
          return StoryBubble(
            imageUrl: story.imageUrl,
            label: story.label,
            isUnseen: story.isUnseen,
            onTap:
                onStoryTap == null ? null : () => onStoryTap!(story),
          );
        },
      ),
    );
  }
}

/// One story bubble — blocky/pixelated Minecraft-style square avatar with a
/// thick dark-brown border and hard offset shadow, wrapped in a squared
/// mint-green ring when [isUnseen].
class StoryBubble extends StatelessWidget {
  final String imageUrl;
  final String label;
  final bool isUnseen;
  final VoidCallback? onTap;

  static const double _avatarSize = 56; // Step 49 — was 64, scaled to fit the leaner 96px tray

  const StoryBubble({
    super.key,
    required this.imageUrl,
    required this.label,
    required this.isUnseen,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$label hikayesi${isUnseen ? ', izlenmedi' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 78,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              // Outer "unseen" ring — mint green, absent once viewed.
              // Squared (not circular) to match the blocky avatar it wraps.
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.zero,
                  border: isUnseen
                      ? const Border.fromBorderSide(
                          BorderSide(color: NeoBrutal.userBubble, width: 3))
                      : null,
                ),
                child: _Avatar(imageUrl: imageUrl, size: _avatarSize),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.baloo2(
                  fontSize: 11,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Current user's "Sen" bubble — no unseen ring, plus a small "+" badge
/// overlapping the bottom-right corner.
class _AddStoryBubble extends StatelessWidget {
  final String label;
  final String imageUrl;
  final VoidCallback onTap;

  const _AddStoryBubble({
    required this.label,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Hikaye ekle',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 78,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _Avatar(imageUrl: imageUrl, size: StoryBubble._avatarSize),
                  // "+" badge — strictly Icons.add (Design System Step 34).
                  // Step 49: scaled to 24x24 (was 28x28) to stay in
                  // proportion with the leaner 56px avatar, still with
                  // clear breathing room around the icon.
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        // Peach — same accent as the Pati-AI bubble (Design
                        // System Step 36), not mintGreen. The "+" icon
                        // itself stays darkBrown either way.
                        color: EspatiColors.peach,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.black, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.baloo2(
                  fontSize: 11,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared avatar block — square (not circular), 2.5px dark-brown border +
/// hard offset shadow, near-zero corner radius for the blocky/pixelated
/// "Minecraft" look. Used by both [StoryBubble] and [_AddStoryBubble].
class _Avatar extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _Avatar({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.pets_rounded,
                    color: Colors.black, size: 28),
              )
            : const Icon(Icons.pets_rounded,
                color: Colors.black, size: 28),
      ),
    );
  }
}
