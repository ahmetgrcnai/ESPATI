import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;

/// Reusable Neo-Brutalist search field (Design System Step 67) — same
/// focus-triggered hard-shadow language as [NeoBrutalistTextField], with a
/// leading search icon and a clear ("x") button once there's text to clear.
/// Sharp, zero-radius, 2px darkBrown border always visible; the offset
/// shadow only appears while focused.
class NeoBrutalistSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Color focusShadowColor;

  /// Grabs keyboard focus as soon as this bar mounts — e.g.
  /// NewChatSearchScreen (Step 69), where the user arrived specifically to
  /// type a search.
  final bool autofocus;

  /// Scales up icon/text/padding for a "hero" search bar that's the
  /// dominant element on its screen (Step 69), vs. the compact default used
  /// e.g. inline in InboxScreen.
  final bool large;

  const NeoBrutalistSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Ara...',
    this.onChanged,
    this.focusShadowColor = EspatiColors.sageGreen,
    this.autofocus = false,
    this.large = false,
  });

  @override
  State<NeoBrutalistSearchBar> createState() => _NeoBrutalistSearchBarState();
}

class _NeoBrutalistSearchBarState extends State<NeoBrutalistSearchBar> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focused == _focusNode.hasFocus) return;
      setState(() => _focused = _focusNode.hasFocus);
    });
    // Repaint the clear button as text changes, independent of whatever
    // the caller's own onChanged does with it.
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.large ? 26.0 : 20.0;
    final fontSize = widget.large ? 17.0 : 14.0;
    final verticalPadding = widget.large ? 18.0 : 12.0;
    final borderWidth = widget.large ? 2.5 : 2.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.black, width: borderWidth),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: widget.focusShadowColor,
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ]
            : const [],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(Icons.search_rounded,
                size: iconSize, color: Colors.black),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: GoogleFonts.poppins(
                  fontSize: fontSize,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                filled: false,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 10, vertical: verticalPadding),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                widget.onChanged?.call('');
              },
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.close_rounded,
                    size: widget.large ? 22 : 18,
                    color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}
