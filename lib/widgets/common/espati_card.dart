import 'package:flutter/material.dart';

import '../../core/neo_brutalist_tokens.dart';

/// Reusable Neo-Brutalist card — white surface, solid black border, hard
/// (non-blurred) offset drop shadow. The base building block every
/// Post/Community/Feed card in the design system should compose with.
class EspatiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;

  const EspatiCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2),
        boxShadow: NeoBrutal.shadow(),
      ),
      child: child,
    );
  }
}
