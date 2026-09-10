import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/neo_brutalist_tokens.dart';
import '../data/models/reminder_model.dart';
import '../screens/profile/reminder_manager_screen.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'common/neo_brutalist_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UPCOMING REMINDERS BANNER (Phase 2 Step 5 — "Madde 6" retention feature)
//
// FOMO-driven countdown for the single most urgent Pati Takvimi reminder due
// within the next 7 days. Reads real data from [ProfileViewModel.reminders]
// (already Firestore/mock-repository-backed via [IReminderRepository]) —
// no fabricated content. Collapses to zero space when there is nothing due
// in that window, so it never renders an empty/broken-looking card.
//
// Restyled to the sharp Neo-Brutalist system [ProfileScreen]/
// [AlgorithmicFeedScreen] run on — solid [EspatiColors.peach] block, zero
// radius, black border, hard offset shadow — replacing the earlier soft
// gradient/blurred-shadow pill.
// ─────────────────────────────────────────────────────────────────────────────

class UpcomingRemindersBanner extends StatelessWidget {
  /// How many days ahead counts as "upcoming" for this banner. Reminders due
  /// further out than this, already overdue, or completed are ignored.
  static const int _windowDays = 7;

  const UpcomingRemindersBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        final upcoming = _dueWithinWindow(vm.reminders);
        if (upcoming.isEmpty) return const SizedBox.shrink();

        final soonest = upcoming.first;
        final extraCount = upcoming.length - 1;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: NeoBrutalistButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ReminderManagerScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EspatiColors.peach,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(2.5),
                boxShadow: NeoBrutal.shadow(),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero,
                      border: NeoBrutal.border(2),
                    ),
                    child: Icon(soonest.category.icon,
                        color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _headline(soonest),
                          style: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          extraCount > 0
                              ? '${soonest.category.label} • Pati Takvimi\'nde $extraCount görev daha'
                              : '${soonest.category.label} • Pati Takvimi',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.65),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Colors.black),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Non-completed reminders due today through [_windowDays] days from now,
  /// soonest first. Empty when nothing qualifies — the caller collapses.
  List<ReminderModel> _dueWithinWindow(List<ReminderModel> reminders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final due = reminders.where((r) {
      if (r.isCompleted) return false;
      final target = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
      final daysUntil = target.difference(today).inDays;
      return daysUntil >= 0 && daysUntil <= _windowDays;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return due;
  }

  /// "'{title}' bugün son gün!" / "...yarın..." / "...N gün kaldı" — built
  /// from the reminder's own title with "için" rather than a Turkish dative
  /// suffix on the category label, since suffix choice depends on vowel
  /// harmony ("Aşıya" vs "Mamaya" vs "İlaca") and would need per-category
  /// hardcoding to stay grammatically correct.
  String _headline(ReminderModel r) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
    final daysUntil = target.difference(today).inDays;

    final countdown = switch (daysUntil) {
      0 => 'bugün son gün!',
      1 => 'için yarın son gün!',
      _ => 'için $daysUntil gün kaldı',
    };
    return "'${r.title}' $countdown";
  }
}
