import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../core/notification_service.dart';
import '../../data/models/pet_model.dart';
import '../../data/models/reminder_model.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REMINDER MANAGER SCREEN (Neo-Brutalist pass — aligned to the app's actual
// current design system: [NeoBrutal] tokens, same as Keşfet/Paties/Pati-AI.)
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen list of all reminders with swipe-to-delete and a FAB to add new
/// ones. State is driven by [ProfileViewModel].
class ReminderManagerScreen extends StatelessWidget {
  const ReminderManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: _ReminderAppBar(),
      body: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {
          // Error snackbar
          if (vm.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(vm.errorMessage!,
                      style: GoogleFonts.nunitoSans(fontSize: 13)),
                  backgroundColor: EspatiColors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
              );
              vm.clearError();
            });
          }

          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: EspatiColors.sageGreen),
            );
          }

          if (vm.reminders.isEmpty) {
            return _EmptyState(
              onAdd: () => _showAddSheet(context),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: vm.reminders.length,
            itemBuilder: (context, index) {
              final reminder = vm.reminders[index];
              return ReminderCard(
                reminder: reminder,
                petName: _petNameFor(reminder.petId, vm.pets),
                onComplete: () => vm.completeReminder(reminder.id),
                onDelete: () => vm.deleteReminder(reminder.id),
              );
            },
          );
        },
      ),
      floatingActionButton: NeoBrutalistButton(
        semanticLabel: 'Hatırlatıcı Ekle',
        onPressed: () => _showAddSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: EspatiColors.sageGreen,
            borderRadius: BorderRadius.zero,
            border: NeoBrutal.border(2.5),
            boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_alarm_rounded, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text('Hatırlatıcı Ekle',
                  style: GoogleFonts.baloo2(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }

  /// Resolves [ReminderModel.petId] (a real [PetModel.id] as of this fix —
  /// see [_PetChips]'s doc comment) to that pet's current name, from the
  /// user's real, live [ProfileViewModel.pets] rather than the static
  /// [SampleData] demo list this used to match against — that made every
  /// real user's own pets impossible to select or display correctly.
  String? _petNameFor(String? petId, List<PetModel> pets) {
    if (petId == null) return null;
    for (final pet in pets) {
      if (pet.id == petId) return pet.name;
    }
    return null;
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddReminderSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR — sharp back block + Fredoka title, thick black bottom border on
// the [NeoBrutal.scaffoldBg] canvas. Same convention as [AiVetScreen] /
// [ListingFormScreen].
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: NeoBrutal.scaffoldBg,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: NeoBrutal.borderWidth),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              NeoBrutalistButton(
                semanticLabel: 'Geri',
                onPressed: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(2.5),
                    boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.black, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pati Takvimi',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              NeoBrutalistButton(
                semanticLabel: 'Bildirim izni',
                onPressed: () async {
                  final granted =
                      await NotificationService.instance.requestPermissions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          granted
                              ? 'Bildirim izni verildi ✓'
                              : 'Bildirim izni reddedildi.',
                          style: GoogleFonts.nunitoSans(fontSize: 13),
                        ),
                        backgroundColor: granted
                            ? EspatiColors.sageGreen
                            : EspatiColors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: EspatiColors.sageGreen,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(2.5),
                    boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: Colors.black, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REMINDER CARD — white block, thick black border, hard shadow. Category
// color still used as an accent (left bar + icon tile), just no longer
// alpha-tinted-glass — a solid fill with a black border, matching every
// other icon tile in the app's current design.
// ─────────────────────────────────────────────────────────────────────────────

class ReminderCard extends StatelessWidget {
  final ReminderModel reminder;

  /// Human-readable pet name. `null` = general reminder.
  final String? petName;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.petName,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue =
        !reminder.isCompleted && reminder.dateTime.isBefore(now);
    final accentColor = isOverdue ? EspatiColors.red : EspatiColors.sageGreen;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: EspatiColors.red,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
        ),
        child: const Icon(Icons.delete_sweep_rounded,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: reminder.isCompleted
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
          boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
        ),
        child: Row(
          children: [
            // ── Left color bar ──────────────────────────────────────────────
            Container(
              width: 6,
              height: 84,
              decoration: BoxDecoration(
                color: reminder.isCompleted
                    ? Colors.black.withValues(alpha: 0.15)
                    : accentColor,
                border: const Border(
                  right: BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Category icon ───────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: reminder.isCompleted
                    ? Colors.white
                    : reminder.category.color,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(2),
              ),
              child: Icon(
                reminder.category.icon,
                size: 22,
                color: reminder.isCompleted
                    ? Colors.black.withValues(alpha: 0.35)
                    : Colors.black,
              ),
            ),

            const SizedBox(width: 12),

            // ── Text content ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      reminder.title,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: reminder.isCompleted
                            ? Colors.black.withValues(alpha: 0.4)
                            : Colors.black,
                        decoration: reminder.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: isOverdue && !reminder.isCompleted
                              ? EspatiColors.red
                              : Colors.black.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatDateTime(reminder.dateTime),
                            style: GoogleFonts.nunitoSans(
                              fontSize: 12,
                              color: isOverdue && !reminder.isCompleted
                                  ? EspatiColors.red
                                  : Colors.black.withValues(alpha: 0.45),
                              fontWeight: isOverdue && !reminder.isCompleted
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (petName != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.pets_rounded,
                              size: 12,
                              color: Colors.black.withValues(alpha: 0.35)),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              petName!,
                              style: GoogleFonts.nunitoSans(
                                fontSize: 12,
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (reminder.isRepeating)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Icon(Icons.repeat_rounded,
                                size: 11,
                                color:
                                    EspatiColors.sageGreen.withValues(alpha: 0.8)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                reminder.repeatInterval?.label ?? '',
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 11,
                                  color: EspatiColors.sageGreen
                                      .withValues(alpha: 0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Complete checkbox ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: reminder.isCompleted ? null : onComplete,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: reminder.isCompleted
                        ? EspatiColors.sageGreen
                        : Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: isOverdue && !reminder.isCompleted
                          ? EspatiColors.red
                          : Colors.black,
                      width: 1.5,
                    ),
                  ),
                  child: reminder.isCompleted
                      ? const Icon(Icons.check_rounded,
                          size: 17, color: Colors.black)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(3),
                boxShadow: NeoBrutal.shadow(const Offset(4, 4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hatırlatıcıyı sil',
                    style: GoogleFonts.baloo2(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${reminder.title}" silinecek. Bu işlem geri alınamaz.',
                    style: GoogleFonts.nunitoSans(
                        fontSize: 13, color: Colors.black.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: NeoBrutalistButton(
                          semanticLabel: 'İptal',
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.zero,
                              border: NeoBrutal.border(2),
                            ),
                            child: Text('İptal',
                                style: GoogleFonts.baloo2(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: NeoBrutalistButton(
                          semanticLabel: 'Sil',
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: EspatiColors.red,
                              borderRadius: BorderRadius.zero,
                              border: NeoBrutal.border(2),
                              boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
                            ),
                            child: Text('Sil',
                                style: GoogleFonts.baloo2(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.inDays == 0 && dt.day == now.day) {
      return 'Bugün ${_time(dt)}';
    } else if (diff.inDays == 1 ||
        (diff.inDays == 0 && dt.day == now.day + 1)) {
      return 'Yarın ${_time(dt)}';
    } else if (diff.isNegative) {
      final absDays = diff.inDays.abs();
      return absDays == 0
          ? 'Bugün ${_time(dt)} (geçti)'
          : '$absDays gün önce — ${_time(dt)}';
    } else {
      return '${dt.day} ${_month(dt.month)} — ${_time(dt)}';
    }
  }

  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _month(int m) => const [
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
        'Ara'
      ][m];
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EspatiColors.sageGreen,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(3),
                boxShadow: NeoBrutal.shadow(const Offset(4, 4)),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 54,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Henüz hatırlatıcı yok',
              style: GoogleFonts.baloo2(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Evcil hayvanlarınızın aşı, mama ve ilaç\ntakvimlerini takip edin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            NeoBrutalistButton(
              semanticLabel: 'İlk hatırlatıcını ekle',
              onPressed: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: EspatiColors.sageGreen,
                  borderRadius: BorderRadius.zero,
                  border: NeoBrutal.border(2.5),
                  boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_alarm_rounded,
                        color: Colors.black, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'İlk hatırlatıcını ekle!',
                      style: GoogleFonts.baloo2(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD REMINDER BOTTOM SHEET — floats as a white blocky card with margin on
// every side, same convention as [ActionHubSheet]'s sheets, just recolored
// to the current white/black-border/hard-shadow system.
// ─────────────────────────────────────────────────────────────────────────────

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _titleCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ReminderCategory _category = ReminderCategory.other;
  String? _selectedPetId; // null = general (no specific pet)
  DateTime _date = DateTime.now().add(const Duration(hours: 2));
  bool _isRepeating = false;
  RepeatInterval _repeatInterval = RepeatInterval.weekly;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) => _themedPicker(context, child),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
            picked.year, picked.month, picked.day, _date.hour, _date.minute);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      builder: (context, child) => _themedPicker(context, child),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
            _date.year, _date.month, _date.day, picked.hour, picked.minute);
      });
    }
  }

  Widget _themedPicker(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: EspatiColors.sageGreen,
              onPrimary: Colors.black,
            ),
      ),
      child: child!,
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final reminder = ReminderModel(
      id: 'reminder_${DateTime.now().millisecondsSinceEpoch}',
      petId: _selectedPetId,
      title: _titleCtrl.text.trim(),
      category: _category,
      dateTime: _date,
      isRepeating: _isRepeating,
      repeatInterval: _isRepeating ? _repeatInterval : null,
    );

    final success = await context.read<ProfileViewModel>().addReminder(reminder);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      // Keep the sheet open on failure so the filled-in form isn't lost —
      // the parent screen's Consumer already surfaces vm.errorMessage as a
      // snackbar.
      setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(3),
          boxShadow: NeoBrutal.shadow(const Offset(4, 4)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                ),

                // Title
                Text(
                  'Yeni Hatırlatıcı',
                  style: GoogleFonts.baloo2(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Category selection ────────────────────────────────────────
                const _SectionLabel(label: 'Kategori'),
                const SizedBox(height: 10),
                _CategoryGrid(
                  selected: _category,
                  onSelected: (c) => setState(() => _category = c),
                ),

                const SizedBox(height: 20),

                // ── Title field ───────────────────────────────────────────────
                const _SectionLabel(label: 'Başlık'),
                const SizedBox(height: 8),
                _BlockyField(
                  child: TextFormField(
                    controller: _titleCtrl,
                    style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Örn: Luna\'nun karma aşısı',
                      hintStyle: GoogleFonts.nunitoSans(
                          fontSize: 13.5,
                          color: Colors.black.withValues(alpha: 0.4)),
                      prefixIcon:
                          Icon(_category.icon, color: Colors.black, size: 20),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      errorStyle:
                          GoogleFonts.nunitoSans(fontSize: 11, color: EspatiColors.red),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Başlık giriniz.'
                        : null,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Pet selection ─────────────────────────────────────────────
                const _SectionLabel(label: 'Evcil Hayvan (isteğe bağlı)'),
                const SizedBox(height: 10),
                _PetChips(
                  selectedPetId: _selectedPetId,
                  onSelected: (id) => setState(
                      () => _selectedPetId = id == _selectedPetId ? null : id),
                ),

                const SizedBox(height: 20),

                // ── Date & Time ───────────────────────────────────────────────
                const _SectionLabel(label: 'Tarih & Saat'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PickerButton(
                        icon: Icons.calendar_month_rounded,
                        label: _formatDate(_date),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PickerButton(
                        icon: Icons.access_time_rounded,
                        label:
                            '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Repeat toggle ─────────────────────────────────────────────
                _BlockyField(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.repeat_rounded,
                            color: _isRepeating
                                ? EspatiColors.sageGreen
                                : Colors.black.withValues(alpha: 0.4)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tekrar Et',
                                style: GoogleFonts.nunitoSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black),
                              ),
                              Text(
                                'Haftalık veya aylık tekrarlayan hatırlatıcı',
                                style: GoogleFonts.nunitoSans(
                                    fontSize: 11,
                                    color: Colors.black.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isRepeating,
                          onChanged: (v) => setState(() => _isRepeating = v),
                          activeThumbColor: Colors.white,
                          activeTrackColor: EspatiColors.sageGreen,
                          trackOutlineColor:
                              WidgetStateProperty.all(Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),

                // Repeat interval selector
                if (_isRepeating) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: RepeatInterval.values.map((interval) {
                      final isSelected = _repeatInterval == interval;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right:
                                  interval == RepeatInterval.weekly ? 8 : 0),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _repeatInterval = interval),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? EspatiColors.sageGreen
                                    : Colors.white,
                                borderRadius: BorderRadius.zero,
                                border: NeoBrutal.border(isSelected ? 2.5 : 2),
                                boxShadow: isSelected
                                    ? NeoBrutal.shadow(const Offset(2, 2))
                                    : null,
                              ),
                              child: Text(
                                interval.label,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunitoSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Save button ───────────────────────────────────────────────
                NeoBrutalistButton(
                  semanticLabel: 'Kaydet & Bildir',
                  onPressed: _isSaving ? null : _save,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: _isSaving
                          ? EspatiColors.sageGreen.withValues(alpha: 0.5)
                          : EspatiColors.sageGreen,
                      borderRadius: BorderRadius.zero,
                      border: NeoBrutal.border(2.5),
                      boxShadow: _isSaving
                          ? null
                          : NeoBrutal.shadow(const Offset(3, 3)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            'Kaydet & Bildir',
                            style: GoogleFonts.baloo2(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  static const _months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// White/black-bordered/hard-shadow frame around a plain input — same
// convention as [ListingFormScreen]'s `_BlockyField`.
class _BlockyField extends StatelessWidget {
  final Widget child;

  const _BlockyField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.nunitoSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black.withValues(alpha: 0.7),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final ReminderCategory selected;
  final ValueChanged<ReminderCategory> onSelected;

  const _CategoryGrid({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: ReminderCategory.values.map((cat) {
        final isSelected = selected == cat;
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? cat.color : Colors.white,
              borderRadius: BorderRadius.zero,
              border: NeoBrutal.border(isSelected ? 2.5 : 2),
              boxShadow:
                  isSelected ? NeoBrutal.shadow(const Offset(2, 2)) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat.icon,
                    size: 22,
                    color: isSelected
                        ? Colors.black
                        : Colors.black.withValues(alpha: 0.45)),
                const SizedBox(height: 4),
                Text(
                  cat.label,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.black
                        : Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Pet picker for a new reminder — real pets from [ProfileViewModel.pets],
/// keyed by [PetModel.id]. Used to render the static `SampleData` demo pet
/// list and pass a pet's *name* around as if it were an id, so a real
/// user's own pets could never be selected and a saved reminder's "petId"
/// wasn't actually an id at all. See [ReminderManagerScreen._petNameFor].
class _PetChips extends StatelessWidget {
  final String? selectedPetId;
  final ValueChanged<String> onSelected;

  const _PetChips({this.selectedPetId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<ProfileViewModel>().pets;
    if (pets.isEmpty) {
      return Text(
        'Henüz bir patin yok — bu hatırlatıcı genel olarak kaydedilecek.',
        style: GoogleFonts.nunitoSans(
          fontSize: 12,
          color: Colors.black.withValues(alpha: 0.5),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pets.map((pet) {
        final isSelected = selectedPetId == pet.id;
        return GestureDetector(
          onTap: () => onSelected(pet.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? EspatiColors.sageGreen : Colors.white,
              borderRadius: BorderRadius.zero,
              border: NeoBrutal.border(isSelected ? 2.5 : 2),
              boxShadow:
                  isSelected ? NeoBrutal.shadow(const Offset(2, 2)) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets_rounded, size: 14, color: Colors.black),
                const SizedBox(width: 5),
                Text(
                  pet.name,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
