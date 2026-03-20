import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Card for pet-friendly places with icon, name, category chip, rating, and distance.
class PlaceCard extends StatelessWidget {
  final String name;
  final String category;
  final String iconType;
  final double rating;
  final String distance;
  final String address;
  final VoidCallback? onTap;

  const PlaceCard({
    super.key,
    required this.name,
    required this.category,
    required this.iconType,
    required this.rating,
    required this.distance,
    required this.address,
    this.onTap,
  });

  IconData get _categoryIcon {
    switch (iconType) {
      case 'coffee':
        return Icons.coffee_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'vet':
        return Icons.local_hospital_rounded;
      case 'shop':
        return Icons.store_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color get _categoryColor {
    switch (iconType) {
      case 'coffee':
        return const Color(0xFF8D6E63);
      case 'park':
        return AppColors.success;
      case 'vet':
        return AppColors.primary;
      case 'shop':
        return const Color(0xFF9C27B0);
      default:
        return AppColors.peach;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_categoryIcon, color: _categoryColor, size: 26),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            // Rating + distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    distance,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
