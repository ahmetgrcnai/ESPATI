import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/notification_service.dart';
import '../../data/models/reminder_model.dart';
import '../../data/sample_data.dart';
import '../../viewmodels/profile_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REMINDER MANAGER SCREEN
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen list of all reminders with swipe-to-delete and a FAB to add new
/// ones. State is driven by [ProfileViewModel].
class ReminderManagerScreen extends StatelessWidget {
  const ReminderManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Pati Takvimi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: cs.onSurface,
          ),
        ),
        actions: [
          // Request permissions shortcut (useful on first open)
          IconButton(
            tooltip: 'Bildirim izni',
            icon: Icon(Icons.notifications_active_rounded,
                color: AppColors.softTeal),
            onPressed: () async {
              final granted =
                  await NotificationService.instance.requestPermissions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(granted
                        ? 'Bildirim izni verildi ✓'
                        : 'Bildirim izni reddedildi.'),
                    backgroundColor:
                        granted ? AppColors.success : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {
          // Error snackbar
          if (vm.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(vm.errorMessage!),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
              vm.clearError();
            });
          }

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.reminders.isEmpty) {
            return _EmptyState(
              onAdd: () => _showAddSheet(context),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: vm.reminders.length,
            itemBuilder: (context, index) {
              final reminder = vm.reminders[index];
              return ReminderCard(
                reminder: reminder,
                petName: _petNameFor(reminder.petId),
                onComplete: () => vm.completeReminder(reminder.id),
                onDelete: () => vm.deleteReminder(reminder.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.softTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: Text('Hatırlatıcı Ekle',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  String? _petNameFor(String? petId) {
    if (petId == null) return null;
    const pets = SampleData.userPets;
    final match = pets.cast<Map<String, String>?>().firstWhere(
          (p) => p?['name']?.toLowerCase() == petId.toLowerCase(),
          orElse: () => null,
        );
    return match?['name'];
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
// REMINDER CARD  (public — also used in ProfileScreen preview)
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final isOverdue =
        !reminder.isCompleted && reminder.dateTime.isBefore(now);
    final accentColor =
        isOverdue ? AppColors.peach : AppColors.softTeal;
    final cardColor = reminder.isCompleted
        ? cs.surface.withValues(alpha: 0.5)
        : cs.surface;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep_rounded,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Hatırlatıcıyı sil'),
                content: Text(
                    '"${reminder.title}" silinecek. Bu işlem geri alınamaz.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Sil',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Left color bar ──────────────────────────────────────────────
            Container(
              width: 5,
              height: 80,
              decoration: BoxDecoration(
                color: reminder.isCompleted
                    ? cs.onSurface.withValues(alpha: 0.2)
                    : accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Category icon ───────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: reminder.isCompleted
                    ? cs.onSurface.withValues(alpha: 0.08)
                    : reminder.category.color.withValues(
                        alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                reminder.category.icon,
                size: 22,
                color: reminder.isCompleted
                    ? cs.onSurface.withValues(alpha: 0.3)
                    : reminder.category.color,
              ),
            ),

            const SizedBox(width: 12),

            // ── Text content ────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    reminder.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: reminder.isCompleted
                          ? cs.onSurface.withValues(alpha: 0.4)
                          : cs.onSurface,
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
                            ? AppColors.peach
                            : cs.onSurface.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(reminder.dateTime),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isOverdue && !reminder.isCompleted
                              ? AppColors.peach
                              : cs.onSurface.withValues(alpha: 0.45),
                          fontWeight: isOverdue && !reminder.isCompleted
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (petName != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.pets_rounded,
                            size: 12,
                            color: cs.onSurface.withValues(alpha: 0.35)),
                        const SizedBox(width: 3),
                        Text(
                          petName!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.45),
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
                              color: AppColors.softTeal.withValues(alpha: 0.7)),
                          const SizedBox(width: 3),
                          Text(
                            reminder.repeatInterval?.label ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color:
                                  AppColors.softTeal.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Complete checkbox ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: reminder.isCompleted,
                  onChanged: reminder.isCompleted
                      ? null
                      : (_) => onComplete(),
                  activeColor: AppColors.softTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(
                    color: isOverdue
                        ? AppColors.peach
                        : cs.onSurface.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.softTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 60,
                color: AppColors.softTeal.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz hatırlatıcı yok',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Evcil hayvanlarınızın aşı, mama ve ilaç\ntakvimlerini takip edin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_alarm_rounded),
              label: Text(
                'İlk hatırlatıcını ekle!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD REMINDER BOTTOM SHEET
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
              primary: AppColors.softTeal,
              onPrimary: Colors.white,
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

    await context.read<ProfileViewModel>().addReminder(reminder);

    if (mounted) Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
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
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                'Yeni Hatırlatıcı',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // ── Category selection ────────────────────────────────────────
              _SectionLabel(label: 'Kategori'),
              const SizedBox(height: 10),
              _CategoryGrid(
                selected: _category,
                onSelected: (c) => setState(() => _category = c),
              ),

              const SizedBox(height: 20),

              // ── Title field ───────────────────────────────────────────────
              _SectionLabel(label: 'Başlık'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: 'Örn: Luna\'nun karma aşısı',
                  prefixIcon:
                      Icon(_category.icon, color: _category.color, size: 20),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Başlık giriniz.' : null,
              ),

              const SizedBox(height: 20),

              // ── Pet selection ─────────────────────────────────────────────
              _SectionLabel(label: 'Evcil Hayvan (isteğe bağlı)'),
              const SizedBox(height: 10),
              _PetChips(
                selectedPetId: _selectedPetId,
                onSelected: (id) =>
                    setState(() => _selectedPetId = id == _selectedPetId ? null : id),
              ),

              const SizedBox(height: 20),

              // ── Date & Time ───────────────────────────────────────────────
              _SectionLabel(label: 'Tarih & Saat'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.calendar_month_rounded,
                      label: _formatDate(_date),
                      color: AppColors.softTeal,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.access_time_rounded,
                      label:
                          '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                      color: AppColors.primary,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Repeat toggle ─────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  title: Text(
                    'Tekrar Et',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Haftalık veya aylık tekrarlayan hatırlatıcı',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                  value: _isRepeating,
                  onChanged: (v) => setState(() => _isRepeating = v),
                  activeThumbColor: AppColors.softTeal,
                  activeTrackColor: AppColors.softTealLight,
                  secondary: Icon(Icons.repeat_rounded,
                      color: _isRepeating
                          ? AppColors.softTeal
                          : cs.onSurface.withValues(alpha: 0.4)),
                ),
              ),

              // Repeat interval selector
              if (_isRepeating) ...[
                const SizedBox(height: 10),
                Row(
                  children: RepeatInterval.values.map((interval) {
                    final isSelected = _repeatInterval == interval;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _repeatInterval = interval),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(
                              right: interval == RepeatInterval.weekly ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.softTeal
                                : cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.softTeal
                                  : theme.dividerColor,
                            ),
                          ),
                          child: Text(
                            interval.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : cs.onSurface.withValues(alpha: 0.7),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softTeal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.softTeal.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Kaydet & Bildir',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
    final theme = Theme.of(context);
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? cat.color.withValues(alpha: 0.15)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? cat.color : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat.icon,
                    size: 24,
                    color: isSelected
                        ? cat.color
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.45)),
                const SizedBox(height: 4),
                Text(
                  cat.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? cat.color
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
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

class _PetChips extends StatelessWidget {
  final String? selectedPetId;
  final ValueChanged<String> onSelected;

  const _PetChips({this.selectedPetId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const pets = SampleData.userPets;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pets.map((pet) {
        final name = pet['name']!;
        final isSelected = selectedPetId == name;
        return GestureDetector(
          onTap: () => onSelected(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.softTeal.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.softTeal : AppColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets_rounded,
                    size: 14,
                    color: isSelected
                        ? AppColors.softTeal
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.45)),
                const SizedBox(width: 5),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.softTeal
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
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
  final Color color;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
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
