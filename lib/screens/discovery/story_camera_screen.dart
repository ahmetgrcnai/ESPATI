import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'camera_preview_screen.dart';
import 'story_preview_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STORY CAMERA SCREEN (Design System Step 17)
//
// Live camera preview for Stories capture — PageView index 0 of
// [AlgorithmicFeedScreen], replacing the earlier [StoryCameraPlaceholder].
//
// CRITICAL MEMORY MANAGEMENT: [isActive] is true only while this is the
// PageView's *current* page. A plain `PageView(children: [...])` (not
// `.builder`) builds every child eagerly, so without gating on [isActive]
// the device camera would activate the instant the Explore tab first
// builds — before the user ever swiped here. The [CameraController] is
// therefore created lazily on activation and disposed the moment the page
// becomes inactive (swiped away) or the app backgrounds
// ([WidgetsBindingObserver]), then re-acquired on return/resume — the same
// isActive-gated lifecycle already used for [_PatiVideoPlayerItem] in
// [PatiesViewerScreen].
// ─────────────────────────────────────────────────────────────────────────────

class StoryCameraScreen extends StatefulWidget {
  final bool isActive;
  final VoidCallback onClose;

  const StoryCameraScreen({
    super.key,
    required this.isActive,
    required this.onClose,
  });

  @override
  State<StoryCameraScreen> createState() => _StoryCameraScreenState();
}

/// Which capture mode the bottom mode selector has picked. [_capture]
/// branches on this (Design System Step 46): `story` routes straight to
/// [StoryPreviewScreen] — a caption-less, one-tap-to-share review —
/// bypassing [CameraPreviewScreen]'s generic "İLERİ" step and
/// [CreatePostScreen]'s caption/community form entirely; `post` still goes
/// through both, unchanged.
enum _CaptureMode { post, story }

class _StoryCameraScreenState extends State<StoryCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;
  bool _initializing = false;
  String? _error;
  _CaptureMode _mode = _CaptureMode.story;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) _initializeCamera();
  }

  @override
  void didUpdateWidget(covariant StoryCameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    if (widget.isActive) {
      _initializeCamera();
    } else {
      _disposeController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeController();
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_initializing || (_controller?.value.isInitialized ?? false)) return;
    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }
      if (_cameras.isEmpty) {
        throw CameraException(
            'no_camera', 'Kullanılabilir kamera bulunamadı.');
      }

      final controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() => _initializing = false);
    } catch (e) {
      debugPrint('[StoryCameraScreen] initialize failed: $e');
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Kameraya erişilemedi. Lütfen izinleri kontrol edin.';
      });
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _initializing) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _disposeController();
    await _initializeCamera();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }
    try {
      final file = await controller.takePicture();
      debugPrint('[StoryCameraScreen] captured: ${file.path}');
      if (!mounted) return;

      // Tear the live preview down before showing a static review screen on
      // top of it — leaving [CameraController] running underneath a pushed
      // route fights the pushed screen for the same GPU surface, which is
      // what produced the black-screen/frozen-frame bug on return
      // (Step 46 postmortem). `widget.onClose` (swiping the feed's
      // PageView away) is an async animation, not synchronous, so the
      // existing isActive-driven dispose in [didUpdateWidget] doesn't fire
      // until well after the push/pop below — this can't wait for it.
      await _disposeController();
      if (!mounted) return;

      if (_mode == _CaptureMode.story) {
        // Frictionless path — straight to the caption-less preview, no
        // detour through the Post-creation form (Design System Step 46).
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StoryPreviewScreen(
              imagePath: file.path,
              onDone: widget.onClose,
            ),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CameraPreviewScreen(
              imagePath: file.path,
              onDone: widget.onClose,
            ),
          ),
        );
      }

      // Back from the pushed route. Re-acquire the camera so a discarded
      // shot returns to a live preview rather than a dead one. If the flow
      // instead completed (İLERİ / Hikayene Ekle), `widget.onClose`'s page
      // swipe is still animating at this point, so this briefly re-inits
      // before the next `didUpdateWidget` tick disposes it again — a
      // harmless extra cycle, not a user-visible one (this page isn't on
      // screen during that swipe).
      if (mounted) {
        await _initializeCamera();
      }
    } catch (e) {
      debugPrint('[StoryCameraScreen] takePicture failed: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isReady)
            Center(child: CameraPreview(controller))
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: EspatiColors.mintGreen),
            ),

          // ── Close — back to Feed (PageView index 1) ────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: _CircleIconButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: widget.onClose,
                ),
              ),
            ),
          ),

          // ── Flip camera ─────────────────────────────────────────────────
          if (_cameras.length > 1)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 8),
                child: Align(
                  alignment: Alignment.topRight,
                  child: _CircleIconButton(
                    icon: Icons.flip_camera_ios_rounded,
                    onTap: _switchCamera,
                  ),
                ),
              ),
            ),

          // ── Bottom bar — GÖNDERİ/HİKAYE mode selector + shutter ─────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CaptureModeSelector(
                      mode: _mode,
                      onChanged: (mode) => setState(() => _mode = mode),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: isReady ? _capture : null,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: EspatiColors.mintGreen,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.black, width: 3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blocky Instagram-style GÖNDERİ/HİKAYE mode picker (Neo-Brutalist Design
/// System) sitting just above the shutter — square, thick dark-brown
/// bordered blocks; active one filled mint-green with a hard offset
/// shadow, inactive one flat cream.
class _CaptureModeSelector extends StatelessWidget {
  final _CaptureMode mode;
  final ValueChanged<_CaptureMode> onChanged;

  const _CaptureModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModeBlock(
          label: 'GÖNDERİ',
          isActive: mode == _CaptureMode.post,
          onTap: () => onChanged(_CaptureMode.post),
        ),
        const SizedBox(width: 10),
        _ModeBlock(
          label: 'HİKAYE',
          isActive: mode == _CaptureMode.story,
          onTap: () => onChanged(_CaptureMode.story),
        ),
      ],
    );
  }
}

class _ModeBlock extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeBlock({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? EspatiColors.mintGreen : Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

/// Small translucent circular icon button for the camera overlay controls
/// (close / flip) — deliberately not the cream/dark-brown Design System
/// card language, which would be hard to read over a live, unpredictable
/// camera feed; a simple dark scrim + white icon stays legible over any
/// scene.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
