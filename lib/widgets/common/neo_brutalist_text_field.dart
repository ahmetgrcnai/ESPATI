import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;

/// A reusable Neo-Brutalist form field (Design System Step 53) — a sharp,
/// zero-radius, 2px darkBrown-bordered cream block with a small bold label
/// above it. On focus, casts a hard offset shadow (no blur, no elevation)
/// instead of Material's underline/highlight — the same "pressed forward"
/// language every other interactive block in the app uses.
///
/// Stateful only to track focus for the shadow — everything else
/// ([controller], [validator]) is handed straight through to the inner
/// [TextFormField].
class NeoBrutalistTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  /// Shadow color cast on focus — defaults to peach; pass mintGreen (or any
  /// other [EspatiColors] token) to vary the accent per field.
  final Color focusShadowColor;

  /// Optional small widget rendered after the label (e.g. a "Yakında"
  /// badge for a field that isn't wired to persistence yet).
  final Widget? labelTrailing;

  const NeoBrutalistTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.validator,
    this.focusShadowColor = EspatiColors.peach,
    this.labelTrailing,
  });

  @override
  State<NeoBrutalistTextField> createState() => _NeoBrutalistTextFieldState();
}

class _NeoBrutalistTextFieldState extends State<NeoBrutalistTextField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focused == _focusNode.hasFocus) return;
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
            if (widget.labelTrailing != null) ...[
              const SizedBox(width: 8),
              widget.labelTrailing!,
            ],
          ],
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: Colors.black, width: 2),
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
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: widget.maxLines,
            textCapitalization: widget.textCapitalization,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.35),
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              errorStyle: GoogleFonts.poppins(fontSize: 11, color: EspatiColors.red),
            ),
          ),
        ),
      ],
    );
  }
}
