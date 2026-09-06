import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/constants/app_colors.dart' show EspatiColors;
import '../core/result.dart';
import '../data/models/listing_model.dart';
import '../data/repositories/interfaces/i_pet_repository.dart';
import '../data/repositories/interfaces/i_post_repository.dart';
import '../screens/listing_form_screen.dart';
import '../screens/social/create_post_screen.dart';
import '../services/paties_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/create_post_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CENTRAL ACTION HUB (Neo-Brutalist redesign — Design System Step 33)
//
// Opened from the center-docked FAB in [MainScreen]'s bottom nav (via
// [AlgorithmicFeedScreen]'s "Oluştur" AppBar button). Presents the four
// content-creation entry points — İlan Oluştur / Gönderi Paylaş / Pati Video
// / Hikaye — without navigating any bottom-nav tab — the active tab index in
// [MainScreen] is untouched by any path through this sheet.
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the Creation Hub bottom sheet. [context] must be a long-lived
/// ancestor context (e.g. [AlgorithmicFeedScreen]'s own build context) since
/// it's reused after this sheet pops itself to push the next screen/sheet.
///
/// [onCreateStory] is the caller's responsibility because there's no single
/// "Story creation" *route* to push — [StoryCameraScreen] is a live,
/// resource-managed page embedded in [AlgorithmicFeedScreen]'s own
/// PageView (Design System Step 17), not something safe to instantiate a
/// second, independent copy of. The real caller wires this to swiping that
/// PageView to page 0, same as [StoryTray.onAddStory] already does.
Future<void> showActionHubSheet(
  BuildContext context, {
  required VoidCallback onCreateStory,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ActionHubSheet(
      onCreateListing: () => _openListingTypeSheet(context),
      onCreatePost: () => _openCreatePost(context),
      onUploadPatiVideo: () => _uploadPatiVideo(context),
      onCreateStory: () {
        Navigator.pop(context); // close the hub first
        onCreateStory();
      },
    ),
  );
}

void _openListingTypeSheet(BuildContext context) {
  Navigator.pop(context); // close the hub first
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ListingTypeSheet(
      onSahiplendirme: () {
        Navigator.pop(context);
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ListingFormScreen(type: ListingStatus.sahiplendirme),
          ),
        );
      },
      onKayip: () {
        Navigator.pop(context);
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ListingFormScreen(type: ListingStatus.kayip),
          ),
        );
      },
      onBakici: () {
        Navigator.pop(context);
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ListingFormScreen(type: ListingStatus.bakici),
          ),
        );
      },
    ),
  );
}

void _openCreatePost(BuildContext context) {
  Navigator.pop(context); // close the hub first
  // CreatePostViewModel is screen-scoped — created fresh here and disposed
  // when the route pops.
  final postRepo = context.read<IPostRepository>();
  final petRepo = context.read<IPetRepository>();
  final user = context.read<AuthViewModel>().currentUser;
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<CreatePostViewModel>(
        create: (_) => CreatePostViewModel(
          postRepository: postRepo,
          petRepository: petRepo,
          currentUser: user,
        ),
        child: const CreatePostScreen(),
      ),
    ),
  );
}

/// Picks a video from the device gallery and uploads it via [PatiesService].
///
/// [context] is [MainScreen]'s long-lived context, same as [_openCreatePost]
/// — reused after the hub sheet pops itself, both for the picker (no UI
/// dependency, but keeps the pattern consistent) and for the loading dialog
/// / result SnackBar shown once the upload settles.
Future<void> _uploadPatiVideo(BuildContext context) async {
  Navigator.pop(context); // close the hub first

  final user = context.read<AuthViewModel>().currentUser;
  if (user == null || user.id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video paylaşmak için giriş yapmanız gerekiyor.')),
    );
    return;
  }

  final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
  if (picked == null || !context.mounted) return; // user cancelled the picker

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _UploadingDialog(),
  );

  final result = await PatiesService.instance.uploadVideo(
    videoFile: File(picked.path),
    authorId: user.id,
    authorName: user.name.isNotEmpty ? user.name : user.email,
    authorPhoto: user.profilePicture,
  );

  if (!context.mounted) return;
  Navigator.pop(context); // close the uploading dialog

  switch (result) {
    case Success():
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pati videon paylaşıldı! 🐾')),
      );
    case Failure(:final message):
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
  }
}

/// Blocking "uploading" dialog shown while [PatiesService.uploadVideo] runs.
class _UploadingDialog extends StatelessWidget {
  const _UploadingDialog();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.softTeal, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Video yükleniyor...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastel accents for the 2×2 action grid that aren't (yet) part of the core
/// [EspatiColors] palette — Video and Story each need their own hue so all
/// four blocks stay visually distinct at a glance (Ad already owns peach,
/// Post already owns mint).
const Color _lightBlue = Color(0xFFA8DDEE);
const Color _lightYellow = Color(0xFFFCE38A);

class _ActionHubSheet extends StatelessWidget {
  final VoidCallback onCreateListing;
  final VoidCallback onCreatePost;
  final VoidCallback onUploadPatiVideo;
  final VoidCallback onCreateStory;

  const _ActionHubSheet({
    required this.onCreateListing,
    required this.onCreatePost,
    required this.onUploadPatiVideo,
    required this.onCreateStory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Floats as a card with margin on every side (Design System Step 33)
      // rather than the old flush-to-edge sheet — a blocky Neo-Brutalist
      // card always has visible margin for its hard shadow to land in.
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: EspatiColors.cream,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: EspatiColors.darkBrown, width: 3),
          boxShadow: const [
            BoxShadow(
              color: EspatiColors.darkBrown,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EspatiColors.darkBrown.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Oluştur',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: EspatiColors.darkBrown,
                ),
              ),
              Text(
                'Ne paylaşmak istersin?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: EspatiColors.darkBrown.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 18),

              // ── 2×2 blocky action grid ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionBlock(
                      icon: Icons.campaign,
                      label: 'İlan Oluştur',
                      background: EspatiColors.peach,
                      onTap: onCreateListing,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionBlock(
                      icon: Icons.image,
                      label: 'Gönderi Paylaş',
                      background: EspatiColors.mintGreen,
                      onTap: onCreatePost,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionBlock(
                      icon: Icons.play_arrow,
                      label: 'Pati Video',
                      background: _lightBlue,
                      onTap: onUploadPatiVideo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionBlock(
                      icon: Icons.camera_alt,
                      label: 'Hikaye',
                      background: _lightYellow,
                      onTap: onCreateStory,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One chunky, sharp-edged block in the 2×2 Create grid — a distinct pastel
/// background per action, thick dark-brown border, hard offset shadow.
class _ActionBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final VoidCallback onTap;

  const _ActionBlock({
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: EspatiColors.darkBrown, width: 2),
          boxShadow: const [
            BoxShadow(
              color: EspatiColors.darkBrown,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: EspatiColors.darkBrown),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: EspatiColors.darkBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LISTING TYPE SUB-SHEET — Sahiplendirme vs. Kayıp/Buluntu
// (Neo-Brutalist redesign — Design System Step 34)
// ─────────────────────────────────────────────────────────────────────────────

class _ListingTypeSheet extends StatelessWidget {
  final VoidCallback onSahiplendirme;
  final VoidCallback onKayip;
  final VoidCallback onBakici;

  const _ListingTypeSheet({
    required this.onSahiplendirme,
    required this.onKayip,
    required this.onBakici,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Floats as a card with margin on every side, same convention as
      // _ActionHubSheet — a flush edge-to-edge sheet has nowhere for a hard
      // offset shadow to actually land.
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: EspatiColors.cream,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: EspatiColors.darkBrown, width: 3),
          boxShadow: const [
            BoxShadow(
              color: EspatiColors.darkBrown,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EspatiColors.darkBrown.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'İlan Türü Seç',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: EspatiColors.darkBrown,
                ),
              ),
              Text(
                'Oluşturmak istediğiniz ilan türünü seçin',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: EspatiColors.darkBrown.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 18),
              _ListingTypeBlock(
                icon: Icons.favorite_rounded,
                background: EspatiColors.peach,
                title: 'Sahiplendirme İlanı',
                subtitle: 'Bir hayvanı sevgi dolu bir yuvaya kavuşturun',
                onTap: onSahiplendirme,
              ),
              const SizedBox(height: 12),
              _ListingTypeBlock(
                icon: Icons.search_rounded,
                background: EspatiColors.mintGreen,
                title: 'Kayıp / Buluntu İlanı',
                subtitle: 'Kayıp hayvanınızı bulun veya bulduğunuzu bildirin',
                onTap: onKayip,
              ),
              const SizedBox(height: 12),
              _ListingTypeBlock(
                icon: Icons.volunteer_activism_rounded,
                background: EspatiColors.lightBlue,
                title: 'Bakıcı İlanı',
                subtitle: 'Evcil hayvan sahiplerine bakıcılık hizmeti sunun',
                onTap: onBakici,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: EspatiColors.darkBrown.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Vazgeç',
                    style: GoogleFonts.fredoka(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One chunky, sharp-edged listing-type option — a distinct pastel
/// background, thick dark-brown border, hard offset shadow. Wider than
/// [_ActionBlock] (full-width, icon + title/subtitle in a row) since each
/// option here needs to carry an explanatory subtitle the 2×2 grid blocks
/// don't.
class _ListingTypeBlock extends StatelessWidget {
  final IconData icon;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ListingTypeBlock({
    required this.icon,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: EspatiColors.darkBrown, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: EspatiColors.darkBrown,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EspatiColors.cream,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: EspatiColors.darkBrown, width: 2),
              ),
              child: Icon(icon, color: EspatiColors.darkBrown, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: EspatiColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: EspatiColors.darkBrown.withValues(alpha: 0.75),
                    ),
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
