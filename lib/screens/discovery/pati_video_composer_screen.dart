import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_compress/flutter_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../core/result.dart';
import '../../services/paties_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PATI VIDEO COMPOSER SCREEN
//
// Pushed by [action_hub_sheet.dart]'s "Pati Video" action right after a
// video is picked from the gallery — the review/caption step that used to
// be missing between the picker returning and [PatiesService.uploadVideo]
// firing directly. Mirrors [CreatePostScreen]'s composer shape (blocky
// media preview + description field + sticky "PAYLAŞ" bar) rather than
// [StoryPreviewScreen]'s caption-less one-tap flow, since
// [PatiVideoModel.description] is a real, persisted field the Paties viewer
// already renders — unlike Stories, which have none. The caption is
// optional: [PatiesService.uploadVideo]'s `description` parameter already
// defaults to `''`, so an empty field just shares the video without one.
//
// Submitting first transcodes [videoFile] via [FlutterCompress] using the
// `forSocialMedia()` preset (1080p cap, H.264 — deliberately not H.265/HEVC)
// before upload. Phone cameras commonly record 4K/60fps HDR (Dolby Vision/
// HEVC10) video that the *same* device's own hardware decoder can't play
// back — encode and real-time decode capability aren't symmetric on a lot of
// mid-range chips — so an un-transcoded upload can be unplayable for every
// viewer, including its own uploader. Re-encoding to a widely-supported
// baseline profile fixes that regardless of what the source camera recorded.
// ─────────────────────────────────────────────────────────────────────────────

enum _UploadStatus { idle, compressing, uploading, error }

class PatiVideoComposerScreen extends StatefulWidget {
  final File videoFile;
  final String authorId;
  final String authorName;
  final String authorPhoto;

  const PatiVideoComposerScreen({
    super.key,
    required this.videoFile,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
  });

  @override
  State<PatiVideoComposerScreen> createState() =>
      _PatiVideoComposerScreenState();
}

class _PatiVideoComposerScreenState extends State<PatiVideoComposerScreen> {
  final _descriptionCtrl = TextEditingController();

  VideoPlayerController? _controller;
  bool _videoInitialized = false;
  bool _videoFailed = false;

  _UploadStatus _status = _UploadStatus.idle;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.file(widget.videoFile);
    _controller = controller;
    controller.setLooping(true);

    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('[PatiVideoComposerScreen] initialize failed: $e');
      if (mounted) setState(() => _videoFailed = true);
      return;
    }

    if (!mounted) {
      // Screen was popped while initialize() was in flight.
      controller.dispose();
      return;
    }

    setState(() => _videoInitialized = true);
    controller.play();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !_videoInitialized) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_status == _UploadStatus.compressing ||
        _status == _UploadStatus.uploading) {
      return;
    }

    setState(() => _status = _UploadStatus.compressing);

    final VideoCompressResult compressed;
    try {
      compressed = await FlutterCompress.instance.compress(
        widget.videoFile.path,
        const VideoCompressConfig.forSocialMedia(),
      );
    } on CompressException catch (e) {
      debugPrint('[PatiVideoComposerScreen] compress failed: ${e.code}');
      if (!mounted) return;
      setState(() => _status = _UploadStatus.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video işlenemedi. Lütfen farklı bir video deneyin.'),
          backgroundColor: EspatiColors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _status = _UploadStatus.uploading);

    final result = await PatiesService.instance.uploadVideo(
      videoFile: File(compressed.outputPath),
      authorId: widget.authorId,
      authorName: widget.authorName,
      authorPhoto: widget.authorPhoto,
      description: _descriptionCtrl.text.trim(),
    );

    // Only ever a plugin-owned cache file — never the picker's source file,
    // which `compressed.skipped` would point outputPath back at.
    if (!compressed.skipped) {
      await FlutterCompress.instance.releaseOutput(compressed.outputPath);
    }

    if (!mounted) return;

    switch (result) {
      case Success():
        // Captured before popping — ScaffoldMessenger.of(context) would
        // resolve against a deactivated element once this route is gone.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Pati videon paylaşıldı! 🐾')),
        );
      case Failure(:final message):
        setState(() => _status = _UploadStatus.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: EspatiColors.red),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _status == _UploadStatus.compressing ||
        _status == _UploadStatus.uploading;

    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: Colors.black),
        ),
        title: Text(
          'Pati Video Paylaş',
          style: GoogleFonts.baloo2(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _VideoPreview(
            controller: _controller,
            initialized: _videoInitialized,
            failed: _videoFailed,
            onTap: _togglePlayback,
          ),
          const SizedBox(height: 18),
          const _SectionLabel(text: 'Açıklama'),
          const SizedBox(height: 8),
          _DescriptionField(controller: _descriptionCtrl),
        ],
      ),
      bottomNavigationBar: _SubmitBar(
        status: _status,
        enabled: !busy,
        onSubmit: _submit,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO PREVIEW — blocky, sharp-edged playback surface, same border/shadow
// weight as [CreatePostScreen]'s `_ImagePicker`. Tap toggles play/pause,
// same interaction as [PatiesViewerScreen]'s full-feed player.
// ─────────────────────────────────────────────────────────────────────────────

class _VideoPreview extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool initialized;
  final bool failed;
  final VoidCallback onTap;

  const _VideoPreview({
    required this.controller,
    required this.initialized,
    required this.failed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 360,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (failed)
              const Icon(Icons.videocam_off_rounded,
                  color: Colors.white38, size: 48)
            else if (initialized && controller != null)
              AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
              )
            else
              const CircularProgressIndicator(color: EspatiColors.lightBlue),

            if (initialized && controller != null && !controller!.value.isPlaying)
              const Icon(Icons.play_arrow_rounded,
                  size: 64, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL / BLOCKY FIELD / DESCRIPTION FIELD — same visual pattern as
// [CreatePostScreen]'s private widgets of the same name, re-declared here
// rather than shared since those are file-private (`_`-prefixed).
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

class _BlockyField extends StatelessWidget {
  final Widget child;

  const _BlockyField({required this.child});

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
      child: child,
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const _DescriptionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _BlockyField(
      child: TextField(
        controller: controller,
        maxLines: 4,
        maxLength: 280,
        style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
        decoration: InputDecoration(
          hintText: 'Pati videon hakkında bir şeyler yazın... 🐾',
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBMIT BAR — blocky mintGreen "PAYLAŞ" CTA, same convention as
// [CreatePostScreen]'s `_SubmitBar`. Distinguishes the compress and upload
// phases with their own label (no combined progress fraction — neither
// [FlutterCompress.compress] nor [PatiesService.uploadVideo] is wired to a
// fractional progress callback here — just a spinner + phase label).
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final _UploadStatus status;
  final bool enabled;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.status,
    required this.enabled,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final busyLabel = switch (status) {
      _UploadStatus.compressing => 'Video hazırlanıyor…',
      _UploadStatus.uploading => 'Yükleniyor…',
      _UploadStatus.idle || _UploadStatus.error => null,
    };

    return Container(
      color: NeoBrutal.scaffoldBg,
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: GestureDetector(
        onTap: enabled ? onSubmit : null,
        child: Container(
          width: double.infinity,
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
                        color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
                  ]
                : null,
          ),
          child: busyLabel != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      busyLabel,
                      style: GoogleFonts.baloo2(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PAYLAŞ',
                      style: GoogleFonts.baloo2(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
