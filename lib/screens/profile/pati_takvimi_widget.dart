import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../data/models/reminder_model.dart';
import '../../widgets/common/neo_brutalist_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PATI TAKVİMİ WIDGET (Design System Step 40, upgraded Step 41)
//
// Neo-Brutalist vertical timeline embedded in ProfileScreen. Renders real
// [ReminderModel]s from [ProfileViewModel.reminders] — not fabricated data.
// Card status (Overdue/Upcoming/Completed) is derived straight from
// [ReminderModel.isCompleted] + [ReminderModel.dateTime] vs. now, same
// "overdue" logic [ReminderCard] (in reminder_manager_screen.dart, the
// full-screen manager — still untouched, out of this widget's scope) uses.
//
// Step 41: completed tasks are hidden by default behind a
// "Tamamlananları Göster/Gizle" toggle, and each active card gets a
// tappable checkbox. Checking one calls the real
// [ProfileViewModel.completeReminder] (via [onComplete]) — this widget has
// no local copy of the data to "own", so ticking a box doesn't fabricate a
// completion; it optimistically renders the item as done immediately
// ([_optimisticallyCompleted]) while the real Firestore write is in
// flight, then quietly stops mattering once the write round-trips back
// through the (by-then-updated) `reminders` prop.
//
// A `ListView.builder` with `shrinkWrap: true` +
// `NeverScrollableScrollPhysics` (for both the active and completed
// sections) so this composes inside ProfileScreen's own outer
// `SingleChildScrollView` (Step 29) without a nested-scroll conflict.
// ─────────────────────────────────────────────────────────────────────────────

enum _TimelineStatus { overdue, upcoming, completed }

/// Coral/red for the overdue state — not (yet) an [EspatiColors] token,
/// same ad-hoc-pastel situation as `_cafeAccent` (map_pin.dart) and the
/// yellow/blue accents in action_hub_sheet.dart / chat_screen.dart.
const Color _coral = Color(0xFFE8735C);

extension on _TimelineStatus {
  Color get dotColor => switch (this) {
        _TimelineStatus.overdue => _coral,
        _TimelineStatus.upcoming => EspatiColors.sageGreen,
        _TimelineStatus.completed => Colors.black,
      };

  Color get cardColor => switch (this) {
        _TimelineStatus.overdue => _coral,
        _TimelineStatus.upcoming => EspatiColors.sageGreen,
        _TimelineStatus.completed => Colors.white,
      };
}

class PatiTakvimiWidget extends StatefulWidget {
  final List<ReminderModel> reminders;
  final bool isLoading;
  final Future<bool> Function(String id) onComplete;
  final VoidCallback onSeeAll;

  final ValueChanged<ReminderModel> onAdd;

  const PatiTakvimiWidget({
    super.key,
    required this.reminders,
    required this.isLoading,
    required this.onComplete,
    required this.onSeeAll,
    required this.onAdd,
  });

  @override
  State<PatiTakvimiWidget> createState() => _PatiTakvimiWidgetState();
}

class _PatiTakvimiWidgetState extends State<PatiTakvimiWidget> {
  /// How many active entries the Profile preview shows — deliberately more
  /// than a single item so the timeline actually reads as a timeline;
  /// "Tümünü Gör / Düzenle" opens the full list. Completed tasks (shown
  /// only once expanded) aren't capped — the user explicitly asked to see
  /// them, so a truncated list there would just be confusing.
  static const int _activePreviewCount = 5;

  bool showCompleted = false;

  /// Ids checked off locally, rendered as completed immediately — see the
  /// file-level doc comment above for why this exists.
  final Set<String> _optimisticallyCompleted = {};

  /// Optimistically marks [reminder] completed immediately, then rolls that
  /// back if [PatiTakvimiWidget.onComplete] (→
  /// [ProfileViewModel.completeReminder]) reports the write failed —
  /// without this, a failed completion left the card permanently and
  /// invisibly "stuck done" in this widget even after the ViewModel itself
  /// had correctly reverted [ReminderModel.isCompleted].
  Future<void> _handleCheck(ReminderModel reminder) async {
    setState(() => _optimisticallyCompleted.add(reminder.id));
    final success = await widget.onComplete(reminder.id);
    if (!success && mounted) {
      setState(() => _optimisticallyCompleted.remove(reminder.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = widget.reminders.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final activeTasks = sorted
        .where((r) =>
            !r.isCompleted && !_optimisticallyCompleted.contains(r.id))
        .toList();
    final completedTasks = sorted
        .where(
            (r) => r.isCompleted || _optimisticallyCompleted.contains(r.id))
        .toList();
    final activePreview = activeTasks.take(_activePreviewCount).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // Step 57 — the calendar now lives inside its own solid-cream,
      // thick-bordered, hard-shadowed block instead of sitting bare on the
      // scaffold. Before Step 56 that bare placement worked because the
      // scaffold itself was the dark-brown surface; now that the scaffold
      // is light cream (Step 56), an unbordered calendar would have
      // nothing to visually pop off of.
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────────
            // Step 51 — the "Tümünü Gör / Düzenle" text button is gone: on
            // narrow screens it was squeezed into an overflowing "Tü..."
            // next to the title and "+" button. Title left / add button
            // right via spaceBetween now, with nothing left in between to
            // overflow.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  // Tapping the section header opens the full Pati Takvimi
                  // manager (ReminderManagerScreen) — onSeeAll previously
                  // had no tap target wired to it at all.
                  onTap: widget.onSeeAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Step 57 — Neo-Brutalist icon badge (sageGreen +
                      // darkBrown border), replacing a translucent
                      // AppColors.softTeal chip that was both off-palette
                      // (legacy AppColors, not EspatiColors) and too faint to
                      // read against the new cream card.
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: EspatiColors.sageGreen,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                              color: Colors.black, width: 2),
                        ),
                        child: const Icon(Icons.calendar_month_rounded,
                            size: 18, color: Colors.black),
                      ),
                      const SizedBox(width: 10),
                      // Step 57 — darkBrown, not cream: this now sits on the
                      // widget's own cream card (was cream-on-dark-scaffold
                      // before Step 56/57; cream-on-cream would be invisible).
                      Text(
                        'Pati Takvimi',
                        style: GoogleFonts.baloo2(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: Colors.black38),
                    ],
                  ),
                ),
                _AddTaskButton(
                  onTap: () =>
                      _showAddTaskModal(context, onAdd: widget.onAdd),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Loading ───────────────────────────────────────────────────
            if (widget.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: EspatiColors.sageGreen,
                  ),
                ),
              )

            // ── No reminders at all — invite them to add the first one ──
            else if (widget.reminders.isEmpty)
              _TimelineEmptyState(
                onAdd: () => _showAddTaskModal(context, onAdd: widget.onAdd),
              )
            else ...[
              // ── Active timeline (top section) — or "all caught up" ────
              if (activePreview.isEmpty)
                const _AllDoneCard()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activePreview.length,
                  itemBuilder: (context, index) {
                    final reminder = activePreview[index];
                    final status = reminder.dateTime.isBefore(DateTime.now())
                        ? _TimelineStatus.overdue
                        : _TimelineStatus.upcoming;
                    return _TimelineRow(
                      reminder: reminder,
                      status: status,
                      isLast: index == activePreview.length - 1,
                      onCheck: () => _handleCheck(reminder),
                    );
                  },
                ),

              // ── Completed toggle + section (bottom) ────────────────────
              if (completedTasks.isNotEmpty) ...[
                SizedBox(height: activePreview.isEmpty ? 12 : 4),
                _CompletedToggleButton(
                  expanded: showCompleted,
                  count: completedTasks.length,
                  onTap: () => setState(() => showCompleted = !showCompleted),
                ),
                if (showCompleted) ...[
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completedTasks.length,
                    itemBuilder: (context, index) => _TimelineRow(
                      reminder: completedTasks[index],
                      status: _TimelineStatus.completed,
                      isLast: index == completedTasks.length - 1,
                      onCheck: null,
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE ROW — thick dark-brown line + sharp square node + card
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  final ReminderModel reminder;
  final _TimelineStatus status;
  final bool isLast;

  /// Tap handler for the card's checkbox. `null` on completed cards — done
  /// is done, there's no "un-complete" affordance here.
  final VoidCallback? onCheck;

  const _TimelineRow({
    required this.reminder,
    required this.status,
    required this.isLast,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Line + node — the line fills the row's full height (via
          // IntrinsicHeight), so it runs from this node down through the
          // card's height and the gap below, connecting into the next
          // row's node.
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: status.dotColor,
                    borderRadius: BorderRadius.zero,
                    border:
                        Border.all(color: Colors.black, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      color: Colors.black,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TimelineCard(
                reminder: reminder,
                status: status,
                onCheck: onCheck,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE CARD — sharp rectangular block, styled per [_TimelineStatus],
// with an interactive checkbox on the left for active (non-completed) cards
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final ReminderModel reminder;
  final _TimelineStatus status;
  final VoidCallback? onCheck;

  const _TimelineCard({
    required this.reminder,
    required this.status,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == _TimelineStatus.completed;
    final isOverdue = status == _TimelineStatus.overdue;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: status.cardColor,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: Colors.black,
          width: isCompleted ? 1.5 : 2.5,
        ),
        // Flattened, no shadow once completed/past — everything else pops.
        boxShadow: isCompleted
            ? null
            : const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TaskCheckbox(checked: isCompleted, onTap: onCheck),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Icon(reminder.category.icon,
                size: 16, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOverdue ? '${reminder.title} Gecikti!' : reminder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.black,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(reminder.dateTime, isCompleted),
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11.5,
                    fontWeight:
                        isOverdue ? FontWeight.w800 : FontWeight.w400,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dt, bool isCompleted) {
    if (isCompleted) return 'Tamamlandı — ${_date(dt)}';

    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Bugün ${_time(dt)}';
    }
    final diff = dt.difference(now);
    if (diff.isNegative) {
      final days = now.difference(dt).inDays;
      return days <= 0 ? 'Bugün ${_time(dt)}' : '$days gün önce';
    }
    if (diff.inDays == 1) return 'Yarın ${_time(dt)}';
    return '${_date(dt)} — ${_time(dt)}';
  }

  static String _date(DateTime dt) => '${dt.day} ${_month(dt.month)}';

  static String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _month(int m) => const [
        '',
        'Oca',
        'Şub',
        'Mar',
        'Nis',
        'May',
        'Haz',
        'Tem',
        'Ağu',
        'Eyl',
        'Eki',
        'Kas',
        'Ara',
      ][m];
}

/// Sharp square checkbox — cream/unchecked or sageGreen/checked, both with
/// a thick dark-brown border. `onTap: null` renders as a static (already
/// checked) indicator rather than a live control.
class _TaskCheckbox extends StatelessWidget {
  final bool checked;
  final VoidCallback? onTap;

  const _TaskCheckbox({required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: checked ? EspatiColors.sageGreen : Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: checked
            ? const Icon(Icons.check_rounded,
                size: 16, color: Colors.black)
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPLETED TOGGLE BUTTON — blocky, sharp, shows the completed count
// ─────────────────────────────────────────────────────────────────────────────

class _CompletedToggleButton extends StatelessWidget {
  final bool expanded;
  final int count;
  final VoidCallback onTap;

  const _CompletedToggleButton({
    required this.expanded,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 18,
              color: Colors.black,
            ),
            const SizedBox(width: 6),
            Text(
              'Tamamlananları ${expanded ? 'Gizle' : 'Göster'} ($count)',
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w800,
                fontSize: 13,
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
// EMPTY STATES
// ─────────────────────────────────────────────────────────────────────────────

/// Shown when there are zero reminders at all — invites the user to add
/// their first one. Distinct from [_AllDoneCard] (there ARE reminders, all
/// of them are just done) — conflating the two would either falsely
/// congratulate a user who's never added anything, or fail to invite a
/// first-timer to get started.
class _TimelineEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _TimelineEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.add_alarm_rounded,
                size: 34, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              'İlk hatırlatıcını ekle!',
              style: GoogleFonts.baloo2(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aşı, mama, ilaç takvimini takip et',
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when every reminder is completed — nothing active left.
/// Terracotta (Step 56.5 — was peach), with a hard shadow (this one's a
/// genuine accomplishment, not a flattened/muted past-tense card).
class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: EspatiColors.terracotta,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.task_alt_rounded,
              size: 34, color: Colors.black),
          const SizedBox(height: 8),
          Text(
            'Tüm bakımlar tamam!',
            style: GoogleFonts.baloo2(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bekleyen aşı, mama veya ilaç hatırlatıcın yok.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD TASK BUTTON — compact "+ Yeni" block in the header (Design System
// Step 42, upgraded from a bare "+" square to a labeled block Step 51).
// Wrapped in NeoBrutalistButton (Step 44) for the tactile scale/spring every
// other block button gets; the minimalist "Yeni" label (not the old
// "Tümünü Gör / Düzenle" sentence) can't overflow even on the narrowest
// phone widths.
// ─────────────────────────────────────────────────────────────────────────────

class _AddTaskButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTaskButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: EspatiColors.sageGreen,
          borderRadius: BorderRadius.zero,
          border: Border.fromBorderSide(
            BorderSide(color: Colors.black, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: Colors.black),
            const SizedBox(width: 4),
            Text(
              'Yeni',
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w800,
                fontSize: 13,
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
// ADD TASK MODAL (Design System Step 42)
//
// Deliberately a *lighter* quick-capture form than the full
// [ReminderManagerScreen]'s `_AddReminderSheet` (no pet selection, no
// repeat toggle) — a fast entry point living right on the Profile
// timeline, not a replacement for the full add flow. Both save through the
// exact same real API: [ProfileViewModel.addReminder] (passed down as
// [onAdd]), so nothing here writes fake/local-only data.
// ─────────────────────────────────────────────────────────────────────────────

void _showAddTaskModal(
  BuildContext context, {
  required ValueChanged<ReminderModel> onAdd,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddTaskSheet(onAdd: onAdd),
  );
}

class _AddTaskSheet extends StatefulWidget {
  final ValueChanged<ReminderModel> onAdd;
  const _AddTaskSheet({required this.onAdd});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  ReminderCategory _category = ReminderCategory.vaccine;
  DateTime? _date;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date ?? DateTime.now()),
    );
    if (!mounted) return;

    setState(() {
      _date = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? 9,
        pickedTime?.minute ?? 0,
      );
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Başlık giriniz.');
      return;
    }
    final date = _date;
    if (date == null) {
      _showError('Tarih seçiniz.');
      return;
    }

    widget.onAdd(ReminderModel(
      id: 'reminder_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: _category,
      dateTime: date,
      isRepeating: false,
    ));
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.nunitoSans(fontSize: 13, color: Colors.white)),
        backgroundColor: _coral,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.black, width: 1.5),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Floats as a card with margin on every side (same convention as
      // action_hub_sheet.dart's redesigned sheets) so the hard shadow has
      // somewhere to actually land, and the keyboard pushes it up cleanly.
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
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
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
              const SizedBox(height: 16),
              Text(
                'Yeni Hatırlatıcı',
                style: GoogleFonts.baloo2(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 18),

              // ── Task name ─────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                  border:
                      Border.all(color: Colors.black, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.nunitoSans(
                      fontSize: 14, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "Örn: Luna'nın karma aşısı",
                    hintStyle: GoogleFonts.nunitoSans(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Category selector ────────────────────────────────────────
              Text(
                'Kategori',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ReminderCategory.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = ReminderCategory.values[index];
                    final selected = cat == _category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? EspatiColors.mintGreen
                              : Colors.white,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                            color: Colors.black,
                            width: selected ? 2.5 : 2,
                          ),
                          boxShadow: selected
                              ? const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon,
                                size: 15, color: Colors.black),
                            const SizedBox(width: 6),
                            Text(
                              cat.label,
                              style: GoogleFonts.baloo2(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── Date picker ───────────────────────────────────────────────
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border:
                        Border.all(color: Colors.black, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          size: 20, color: Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        _date == null ? 'Tarih Seç' : _formatPicked(_date!),
                        style: GoogleFonts.baloo2(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── Save ──────────────────────────────────────────────────────
              GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: EspatiColors.mintGreen,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    'KAYDET',
                    style: GoogleFonts.baloo2(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatPicked(DateTime dt) {
    const months = [
      '',
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day} ${months[dt.month]} — $time';
  }
}
