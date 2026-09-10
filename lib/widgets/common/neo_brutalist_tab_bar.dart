import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import 'neo_brutalist_button.dart';

/// A row of blocky, thick-bordered segment buttons — the Neo-Brutalist
/// stand-in for a Material [TabBar]/segmented control.
///
/// The active segment pops forward (sageGreen fill + hard offset shadow);
/// inactive segments sit flat (cream fill, no shadow) so only one button
/// ever reads as "pressed". Purely presentational — callers own the
/// selected index and switch their own body content (e.g. via
/// `IndexedStack`) in response to [onChanged].
class NeoBrutalistTabBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Optional — one icon per [labels] entry, shown left of the label.
  final List<IconData>? icons;

  const NeoBrutalistTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  }) : icons = null;

  const NeoBrutalistTabBar.withIcons({
    super.key,
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    assert(icons == null || icons!.length == labels.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: index == labels.length - 1 ? 0 : 10),
              child: NeoBrutalistButton(
                onPressed: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? EspatiColors.sageGreen
                        : Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                        color: Colors.black, width: 2.5),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icons != null) ...[
                        Icon(icons![index],
                            size: 15, color: Colors.black),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          labels[index],
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunitoSans(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12.5,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
