import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_colors.dart';

/// A circular avatar with a gradient ring, used for stories.
class StoryCircle extends StatelessWidget {
  final String imageUrl;
  final String name;
  final bool isOwn;
  final bool hasBorder;
  final VoidCallback? onTap;

  const StoryCircle({
    super.key,
    required this.imageUrl,
    required this.name,
    this.isOwn = false,
    this.hasBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with gradient ring
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasBorder
                    ? LinearGradient(
                        colors: [
                          AppColors.peach,
                          AppColors.primary,
                          AppColors.peach,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.peachLight,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Icon(
                        Icons.pets,
                        color: AppColors.peach,
                        size: 28,
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.pets,
                        color: AppColors.peach,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Name label
            SizedBox(
              width: 72,
              child: Text(
                isOwn ? 'Your Story' : name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
