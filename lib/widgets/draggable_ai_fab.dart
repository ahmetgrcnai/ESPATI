import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../screens/ai_vet/ai_vet_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DRAGGABLE AI FAB — "Magnetic Snap-to-Edge" chat-head bubble (Design
// System Step 10)
//
// Global, draggable "Pati-AI" entry point, positioned inside [MainScreen]'s
// body Stack so it overlays every tab. Free-drag anywhere on screen via
// GestureDetector; on release, animates ("snaps") to whichever screen edge
// (left/right) is nearer, then shrinks/dims slightly to read as a docked
// side-tab rather than a floating obstruction — same idea as a Messenger
// chat head.
//
// This upgrades the pre-existing DraggableAIFab in place rather than adding
// a second, separate "DraggableAIBubble" widget: the free-drag mechanic,
// neo-brutalist border/shadow styling, and MainScreen wiring described for
// a from-scratch widget were already built and already integrated (see the
// floating-nav-bar Design System step) — only the snap-to-edge physics and
// docked-state styling were actually new work here.
// ─────────────────────────────────────────────────────────────────────────────

class DraggableAIFab extends StatefulWidget {
  const DraggableAIFab({super.key});

  @override
  State<DraggableAIFab> createState() => _DraggableAIFabState();
}

class _DraggableAIFabState extends State<DraggableAIFab> {
  static const double _diameter = 56;
  static const double _dockedDiameter = 46;
  static const double _edgeMargin = 8;
  static const Duration _snapDuration = Duration(milliseconds: 260);

  /// Null until the first [build] — that's when [MediaQuery] is available
  /// to compute a sensible default position (bottom-right, clear of the
  /// center-docked "+" Action Hub FAB, which sits at bottom-center).
  double? _top;
  double? _left;

  /// True for the duration of an active drag — suppresses the tap gesture
  /// so a drag-release never also triggers a navigation, and undocks the
  /// bubble back to full size/opacity immediately.
  bool _dragging = false;

  /// True once a snap animation has settled and the bubble is idle against
  /// an edge — triggers the minimized (smaller + slightly transparent)
  /// docked look. Cleared the instant a new drag starts.
  bool _docked = false;

  /// True for the span between tap-down and tap-up/cancel — drives the
  /// "snappy spring" press reaction. Kept separate from [_dragging] (which
  /// only ever becomes true once the pointer actually moves) so a plain tap
  /// still gets the scale-down/spring-back feedback; can't reuse
  /// [NeoBrutalistButton] here since this widget already owns the pan
  /// gesture on the same node.
  bool _pressed = false;

  void _setInitialPosition(Size screenSize, EdgeInsets safePadding) {
    // Bottom-right, clear of the center-docked "+" FAB (bottom-center) and
    // nudged up above the safe-area/bottom-nav zone.
    _left = screenSize.width - _diameter - 16;
    _top = screenSize.height - _diameter - 220 - safePadding.bottom;
  }

  void _onPanStart(Size screenSize) {
    setState(() {
      _dragging = true;
      _docked = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size screenSize) {
    setState(() {
      _dragging = true;
      _left = (_left! + details.delta.dx)
          .clamp(0.0, screenSize.width - _diameter);
      _top = (_top! + details.delta.dy)
          .clamp(0.0, screenSize.height - _diameter);
    });
  }

  /// Snaps to whichever edge is nearer the bubble's current center, then —
  /// once the snap animation has had time to settle — marks it docked so
  /// the minimized styling kicks in.
  void _onPanEnd(Size screenSize) {
    final center = _left! + _diameter / 2;
    final snapToLeft = center < screenSize.width / 2;

    setState(() {
      _dragging = false;
      _left = snapToLeft
          ? _edgeMargin
          : screenSize.width - _diameter - _edgeMargin;
    });

    Future.delayed(_snapDuration, () {
      if (!mounted || _dragging) return;
      setState(() => _docked = true);
    });
  }

  void _openAssistant(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiVetScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;
    if (_top == null || _left == null) {
      _setInitialPosition(screenSize, safePadding);
    }

    final isMinimized = _docked && !_dragging;
    final size = isMinimized ? _dockedDiameter : _diameter;

    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : _snapDuration,
      curve: Curves.easeOut,
      top: _top,
      // Center the (possibly smaller, docked) bubble on the same point the
      // full-size drag position tracks, so shrinking doesn't visibly shift it.
      left: _left! + (_diameter - size) / 2,
      child: Semantics(
        button: true,
        label: 'Pati-AI Asistanı',
        excludeSemantics: true,
        child: GestureDetector(
          onPanStart: (_) => _onPanStart(screenSize),
          onPanUpdate: (details) => _onPanUpdate(details, screenSize),
          onPanEnd: (_) => _onPanEnd(screenSize),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            if (_dragging) return;
            _openAssistant(context);
          },
          child: AnimatedOpacity(
            duration: _snapDuration,
            opacity: isMinimized ? 0.8 : 1.0,
            child: AnimatedScale(
              scale: _pressed ? 0.90 : 1.0,
              duration: _pressed
                  ? const Duration(milliseconds: 90)
                  : const Duration(milliseconds: 320),
              curve: _pressed ? Curves.easeOut : Curves.elasticOut,
              child: AnimatedContainer(
                duration: _snapDuration,
                curve: Curves.easeOut,
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: EspatiColors.peach,
                  border: Border.fromBorderSide(
                      BorderSide(color: Colors.black, width: 2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.pets_rounded,
                  color: Colors.black,
                  size: isMinimized ? 22 : 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
