import 'package:flutter/material.dart';

/// Wraps any Neo-Brutalist block (a [Container] with the hard-shadow/
/// solid-border decoration) with a tactile "snappy spring" press reaction —
/// scales down sharply on tap-down, then overshoots back to full size on
/// release, giving the flat block a physical, springy feel instead of
/// Material's flat ripple/opacity feedback.
///
/// Built on [AnimatedScale] rather than `flutter_animate`'s timeline API:
/// the press/release states are driven by discrete gesture events (tap-down
/// / tap-up / tap-cancel), not a fixed timeline, so an implicit animation
/// that just retargets on state change is the simpler, more direct tool —
/// `flutter_animate` stays reserved for time-driven effects elsewhere
/// (story progress bars, feed card entrances).
///
/// Icon-only buttons must pass [semanticLabel] — this is a plain
/// [GestureDetector], which has no built-in name for a screen reader, so
/// without it the control announces as an unlabeled "button". Buttons that
/// already carry a visible [Text] child (e.g. [EspatiButton]) should leave
/// [semanticLabel] null; the merged semantics tree picks up that Text
/// automatically.
class NeoBrutalistButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  /// Required for icon-only buttons (a FAB, a badge) — announced to screen
  /// readers in place of the (nonexistent) visible label.
  final String? semanticLabel;

  const NeoBrutalistButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
  });

  @override
  State<NeoBrutalistButton> createState() => _NeoBrutalistButtonState();
}

class _NeoBrutalistButtonState extends State<NeoBrutalistButton> {
  static const _pressScale = 0.90;
  static const _pressDuration = Duration(milliseconds: 90);
  static const _releaseDuration = Duration(milliseconds: 320);

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    // Respect the OS-level "reduce motion" setting — jump straight to each
    // state instead of scaling/springing through it.
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget content = GestureDetector(
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: !reduceMotion && _pressed ? _pressScale : 1.0,
        duration: _pressed ? _pressDuration : _releaseDuration,
        curve: _pressed ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );

    if (widget.semanticLabel != null) {
      content = Semantics(
        button: true,
        enabled: enabled,
        label: widget.semanticLabel,
        excludeSemantics: true,
        child: content,
      );
    }

    return content;
  }
}
