import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/repositories/interfaces/i_pet_repository.dart';
import '../../data/repositories/interfaces/i_post_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/create_post_viewmodel.dart';
import '../social/create_post_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CAMERA PREVIEW SCREEN (Design System Step 20, routing unified Step 32,
// split back apart from the Story path in Step 46)
//
// Pushed by [StoryCameraScreen] right after a successful `takePicture()`,
// **only when capture mode is "post"** — a review step between capture and
// actually posting. Discard pops back to the live camera; "İLERİ" pushes
// the app's one real [CreatePostScreen] (Community selection, caption, pet
// tag, location — the same screen the Explore AppBar's "Oluştur" hub uses)
// instead of a duplicate camera-only screen, passing the captured photo via
// `initialImagePath` so it doesn't need re-picking. [onDone] is threaded
// through to `onPosted` so a successful share pops every pushed camera
// route and swipes the Explore feed's PageView back to its feed page in one
// shot — [StoryCameraScreen.onClose] already does exactly that swipe.
//
// Story-mode captures no longer come through here at all — they route
// straight from [StoryCameraScreen] to [StoryPreviewScreen], a dedicated
// caption-less review, so a Story never detours through the Post form.
// ─────────────────────────────────────────────────────────────────────────────

class CameraPreviewScreen extends StatelessWidget {
  final String imagePath;
  final VoidCallback onDone;

  const CameraPreviewScreen({
    super.key,
    required this.imagePath,
    required this.onDone,
  });

  void _next(BuildContext context) {
    // CreatePostViewModel is screen-scoped — created fresh here and disposed
    // when the route pops, same wiring as `action_hub_sheet.dart`'s
    // `_openCreatePost`.
    final postRepo = context.read<IPostRepository>();
    final petRepo = context.read<IPetRepository>();
    final user = context.read<AuthViewModel>().currentUser;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<CreatePostViewModel>(
          create: (_) => CreatePostViewModel(
            postRepository: postRepo,
            petRepository: petRepo,
            currentUser: user,
          ),
          child: CreatePostScreen(
            initialImagePath: imagePath,
            onPosted: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              onDone();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(imagePath), fit: BoxFit.cover),

          // ── Discard — back to the live camera ───────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: _BlockIconButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),

          // ── Next — blocky mint CTA, bottom-right ────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 24),
              child: Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onTap: () => _next(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
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
                      'İLERİ',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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

/// Sharp, blocky cream icon button — the discard control in
/// [CameraPreviewScreen]'s top-left corner. Deliberately the cream/dark-brown
/// Design System card language (unlike [StoryCameraScreen]'s translucent
/// circular overlay controls): the captured still photo is a fixed,
/// predictable background, not a live unpredictable feed, so it can afford
/// a higher-contrast, on-brand control instead of a generic dark scrim.
class _BlockIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BlockIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
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
        child: Icon(icon, color: Colors.black, size: 22),
      ),
    );
  }
}
