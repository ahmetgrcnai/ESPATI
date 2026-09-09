import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart' show EspatiColors;

/// Neo-Brutalist ad-context strip (Design System Step 71) — sits directly
/// under ChatScreen's AppBar, reminding both sides which listing this
/// thread is about. Full-width, flush against the AppBar with only a
/// bottom border (not a floating bordered/shadowed card like the version
/// this replaces) so it reads as a continuation of the chrome, not a
/// message in the thread.
class AdContextBanner extends StatelessWidget {
  final String imageUrl;
  final String text;

  const AdContextBanner({
    super.key,
    required this.imageUrl,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 2.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: EspatiColors.sageGreen,
              borderRadius: BorderRadius.zero,
              border: Border.fromBorderSide(
                BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Icon(Icons.pets_rounded,
                        color: Colors.black, size: 18),
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.pets_rounded,
                        color: Colors.black,
                        size: 18),
                  )
                : const Icon(Icons.pets_rounded,
                    color: Colors.black, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
