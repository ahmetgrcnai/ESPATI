import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../viewmodels/create_post_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CREATE TOPIC SCREEN — the Topluluk (group) forum-post composer.
//
// A deliberately narrower sibling of [CreatePostScreen]: opened only from
// inside one specific group ([GroupDetailScreen]'s "Konu Aç" FAB), so the
// two fields that only make sense for the general feed composer —
// "Hangi Topluluğa Gönderilecek?" and "Konum" — are dropped entirely. The
// target group is fixed to wherever the user already is (no picker needed,
// they're already inside it), and a forum topic/question isn't tied to an
// Eskişehir district. What's left is the forum-post essentials: a topic
// body (required) and an optional photo attachment — no pet-tag selector
// either, since this is a discussion/Q&A flow, not a pet-showcase post.
//
// Shares [CreatePostViewModel] with [CreatePostScreen] — same
// compress/upload/save pipeline, content-moderation gate, and [PostModel]
// shape; only the View (which fields it collects) differs.
// ─────────────────────────────────────────────────────────────────────────────

class CreateTopicScreen extends StatefulWidget {
  /// Whether the composing user is the group's owner or a moderator —
  /// only then is the "📌 Duyuru olarak gönder" toggle shown at all. Real
  /// enforcement is server-side (Firestore rules check the same
  /// owner/moderator condition on `isAnnouncement: true`), so a caller
  /// passing `true` incorrectly would only get a write rejected, not a
  /// security hole.
  final bool canAnnounce;

  const CreateTopicScreen({super.key, this.canAnnounce = false});

  @override
  State<CreateTopicScreen> createState() => _CreateTopicScreenState();
}

class _CreateTopicScreenState extends State<CreateTopicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bodyCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _isAnnouncement = false;

  // Direct ViewModel reference — avoids calling context.read() inside
  // dispose() or async gaps where the element may already be deactivated
  // (same guard [CreatePostScreen] uses).
  CreatePostViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm == null) {
      final vm = context.read<CreatePostViewModel>();
      _vm = vm;
      vm.addListener(_maybePopOnSuccess);
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_maybePopOnSuccess);
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _maybePopOnSuccess() {
    final vm = _vm;
    if (vm == null || !mounted) return;
    if (vm.status == CreatePostStatus.success) {
      Navigator.of(context).pop();
    } else if (vm.status == CreatePostStatus.error &&
        vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(vm.errorMessage!, style: GoogleFonts.nunitoSans(fontSize: 13)),
          backgroundColor: EspatiColors.red,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.white, width: 1.5),
          ),
        ),
      );
      vm.clearError();
    }
  }

  // ── Image picker ───────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: 2400,
    );
    if (picked == null || !mounted) return;
    _vm?.setImage(File(picked.path));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
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
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Fotoğraf Seç',
                  style: GoogleFonts.baloo2(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                _SheetOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeriden Seç',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                _SheetOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamerayla Çek',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final vm = _vm;
    if (vm == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    await vm.submit(
      description: _bodyCtrl.text,
      isAnnouncement: _isAnnouncement,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<CreatePostViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: NeoBrutal.scaffoldBg,
          appBar: AppBar(
            backgroundColor: NeoBrutal.scaffoldBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.black),
              onPressed:
                  vm.isUploading ? null : () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Yeni Konu',
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w600,
                fontSize: 19,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: AbsorbPointer(
            absorbing: vm.isUploading,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  const _SectionLabel(text: 'Sorunu sor ya da konunu paylaş'),
                  const SizedBox(height: 8),
                  _TopicBodyField(controller: _bodyCtrl),
                  const SizedBox(height: 16),
                  _AttachmentPicker(
                    image: vm.selectedImage,
                    onTap: _showImageSourceSheet,
                    onClear: () => vm.clearImage(),
                  ),
                  if (widget.canAnnounce) ...[
                    const SizedBox(height: 16),
                    _AnnouncementToggle(
                      value: _isAnnouncement,
                      onChanged: (v) => setState(() => _isAnnouncement = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          bottomSheet: _SubmitBar(
            status: vm.status,
            progress: vm.uploadProgress,
            enabled: vm.canSubmit,
            onSubmit: _submit,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET OPTION — blocky row in [_showImageSourceSheet]'s sheet.
// ─────────────────────────────────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: EspatiColors.mintGreen,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL — sits directly on the light NeoBrutal.scaffoldBg canvas.
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunitoSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black.withValues(alpha: 0.85),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPIC BODY FIELD — the one required field on this screen. 500 chars (vs.
// the general post composer's 280) since a forum question/topic usually
// carries more context than a photo caption.
// ─────────────────────────────────────────────────────────────────────────────

class _TopicBodyField extends StatelessWidget {
  final TextEditingController controller;

  const _TopicBodyField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: TextFormField(
        controller: controller,
        minLines: 4,
        maxLines: 8,
        maxLength: 500,
        style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
        decoration: InputDecoration(
          hintText:
              'Ör. "Kedim son 2 gündür iştahsız, bu normal mi?" 🐾',
          hintStyle: GoogleFonts.nunitoSans(
              fontSize: 14, color: Colors.black.withValues(alpha: 0.4)),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
          counterStyle: GoogleFonts.nunitoSans(
            fontSize: 11,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Konu boş olamaz.' : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ATTACHMENT PICKER — compact optional-photo control. Collapses to a single
// tappable row when empty; swaps to a small thumbnail + remove button once
// an image is picked. Deliberately smaller than [CreatePostScreen]'s
// full-width hero picker — here the photo is a supporting attachment to the
// topic text, not the point of the post.
// ─────────────────────────────────────────────────────────────────────────────

class _AttachmentPicker extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _AttachmentPicker({
    required this.image,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final img = image;
    if (img == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.add_photo_alternate_rounded,
                  color: Colors.black, size: 22),
              const SizedBox(width: 10),
              Text(
                'Fotoğraf ekle (isteğe bağlı)',
                style: GoogleFonts.baloo2(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              image: DecorationImage(image: FileImage(img), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fotoğraf eklendi',
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.close_rounded, size: 18, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANNOUNCEMENT TOGGLE — owner/moderator-only "📌 Duyuru olarak gönder".
// Only ever rendered when [CreateTopicScreen.canAnnounce] is true.
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AnnouncementToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? EspatiColors.peach : Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin_rounded, color: Colors.black, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Duyuru olarak gönder',
                style: GoogleFonts.baloo2(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBMIT BAR — blocky mintGreen "KONUYU AÇ" CTA + upload progress.
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final CreatePostStatus status;
  final double progress;
  final bool enabled;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.status,
    required this.progress,
    required this.enabled,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isUploading = status == CreatePostStatus.compressing ||
        status == CreatePostStatus.uploading ||
        status == CreatePostStatus.saving;

    return Container(
      color: NeoBrutal.scaffoldBg,
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: isUploading
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: LinearProgressIndicator(
                        value: status == CreatePostStatus.compressing
                            ? null
                            : progress,
                        minHeight: 6,
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          EspatiColors.mintGreen,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          GestureDetector(
            onTap: enabled ? onSubmit : null,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: enabled
                    ? EspatiColors.mintGreen
                    : EspatiColors.mintGreen.withValues(alpha: 0.4),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: enabled
                    ? const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: isUploading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _labelFor(status, progress),
                          style: GoogleFonts.baloo2(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'KONUYU AÇ',
                      style: GoogleFonts.baloo2(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _labelFor(CreatePostStatus status, double progress) {
    switch (status) {
      case CreatePostStatus.compressing:
        return 'Fotoğraf hazırlanıyor…';
      case CreatePostStatus.uploading:
        return 'Yükleniyor %${(progress * 100).round()}';
      case CreatePostStatus.saving:
        return 'Kaydediliyor…';
      case CreatePostStatus.success:
        return 'Açıldı ✓';
      case CreatePostStatus.error:
      case CreatePostStatus.idle:
        return 'KONUYU AÇ';
    }
  }
}
