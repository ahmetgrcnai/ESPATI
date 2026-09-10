import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/neo_brutalist_tokens.dart';

/// Small card for displaying a user's pet — photo, name, breed.
class PetCard extends StatelessWidget {
  final String name;
  final String breed;
  final String imageUrl;
  final String age;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PetCard({
    super.key,
    required this.name,
    required this.breed,
    required this.imageUrl,
    required this.age,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
          boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pet image
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 120,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 120,
                  height: 90,
                  color: NeoBrutal.inactiveFill,
                  child: const Icon(Icons.pets_rounded, color: Colors.black),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 120,
                  height: 90,
                  color: NeoBrutal.inactiveFill,
                  child: const Icon(Icons.pets_rounded, color: Colors.black),
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
                    style: GoogleFonts.baloo2(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$breed • $age',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 10,
                      color: Colors.black.withValues(alpha: 0.6),
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
