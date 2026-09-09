import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/common/neo_brutalist_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STORY PREVIEW SCREEN (Design System Step 46)
//
// Dedicated, caption-less review step for Stories — pushed directly by
// [StoryCameraScreen] when `_mode == _CaptureMode.story`, bypassing
// [CameraPreviewScreen]'s generic "İLERİ" step and [CreatePostScreen]'s
// caption/community form entirely. Stories are meant to be frictionless
// (Instagram-style): capture → one glance → share, not a detour through the
// same form a permanent feed post needs.
//
// No story-upload repository exists yet in this codebase (no
// `IStoryRepository`, no `addStory`/`uploadStory` anywhere — [StoryModel]
// is currently read-only, [SocialViewModel.getStories] always returns an
// empty list). "Hikayene Ekle" therefore doesn't fake an upload call; it
// does exactly what the spec asks — plays the button's press/spring
// feedback, then closes the flow. Wiring a real upload is a follow-up once
// that repository exists; this is the frictionless *shell* around it.
// ─────────────────────────────────────────────────────────────────────────────

class StoryPreviewScreen extends StatelessWidget {
  final String imagePath;
  final VoidCallback onDone;

  const StoryPreviewScreen({
    super.key,
    required this.imagePath,
    required this.onDone,
  });

  void _addToStory(BuildContext context) {
    // TODO: call IStoryRepository.addStory(imagePath) here once that
    // repository exists — see file header. Until then this is the honest
    // behavior: no fake "uploading..." delay, just close the flow.
    Navigator.of(context).popUntil((route) => route.isFirst);
    onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (_, error, __) {
              debugPrint('[StoryPreviewScreen] decode failed: $error');
              return const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: Colors.white38, size: 48),
                ),
              );
            },
          ),

          // ── Close ("X") — discard, back to the live camera ─────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: Semantics(
                  button: true,
                  label: 'Kapat',
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.black, width: 2.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.black, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── "Hikayene Ekle 🚀" — massive, full-width, animated CTA ──────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: NeoBrutalistButton(
                  onPressed: () => _addToStory(context),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: const BoxDecoration(
                      color: EspatiColors.mintGreen,
                      borderRadius: BorderRadius.zero,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.black, width: 3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'Hikayene Ekle 🚀',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
