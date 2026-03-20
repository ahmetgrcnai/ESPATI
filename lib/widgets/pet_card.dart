import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_colors.dart';

/// Small card for displaying a user's pet — photo, name, breed.
class PetCard extends StatelessWidget {
  final String name;
  final String breed;
  final String imageUrl;
  final String age;
  final VoidCallback? onTap;

  const PetCard({
    super.key,
    required this.name,
    required this.breed,
    required this.imageUrl,
    required this.age,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pet image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 120,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 120,
                  height: 90,
                  color: AppColors.peachLight,
                  child: Icon(Icons.pets, color: AppColors.peach),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 120,
                  height: 90,
                  color: AppColors.peachLight,
                  child: Icon(Icons.pets, color: AppColors.peach),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$breed • $age',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textPrimary.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
