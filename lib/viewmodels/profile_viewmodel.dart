import 'package:flutter/foundation.dart';
import '../core/notification_service.dart';
import '../core/result.dart';
import '../data/models/reminder_model.dart';
import '../data/repositories/interfaces/i_reminder_repository.dart';

/// ViewModel for the Profile screen's Pati Takvimi (pet schedule) section.
///
/// Manages the full reminder lifecycle:
///   1. Load from [IReminderRepository]
///   2. Add → persist + schedule notification
///   3. Complete → persist + cancel notification
///   4. Delete → persist + cancel notification
class ProfileViewModel extends ChangeNotifier {
  final IReminderRepository _reminderRepo;
  final NotificationService _notifService;

  ProfileViewModel({
    required IReminderRepository reminderRepository,
    NotificationService? notificationService,
  })  : _reminderRepo = reminderRepository,
        _notifService = notificationService ?? NotificationService.instance {
    loadReminders();
  }

  // ── State ──────────────────────────────────────────────────────────────────

  List<ReminderModel> _reminders = [];
  List<ReminderModel> get reminders => List.unmodifiable(_reminders);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// The next [maxCount] non-completed reminders, sorted by [dateTime].
  List<ReminderModel> upcomingReminders({int maxCount = 3}) {
    return _reminders
        .where((r) => !r.isCompleted)
        .take(maxCount)
        .toList(growable: false);
  }

  // ── Public Methods ─────────────────────────────────────────────────────────

  /// Fetches reminders from the repository and refreshes UI state.
  Future<void> loadReminders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _reminderRepo.getAll();
    switch (result) {
      case Success(:final data):
        _reminders = data.toList();
      case Failure(:final message):
        _errorMessage = message;
        debugPrint('[ProfileViewModel] loadReminders error: $message');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Persists [reminder] and schedules its local notification.
  ///
  /// Adds optimistically to [_reminders] before the async save completes so
  /// the UI updates immediately; rolls back on failure.
  Future<void> addReminder(ReminderModel reminder) async {
    // Optimistic insert
    _reminders = [..._reminders, reminder]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();

    final result = await _reminderRepo.add(reminder);
    if (result case Failure(:final message)) {
      // Roll back
      _reminders = _reminders.where((r) => r.id != reminder.id).toList();
      _errorMessage = message;
      notifyListeners();
      return;
    }

    // Schedule notification (non-blocking; errors are logged inside the service)
    await _notifService.scheduleReminder(reminder);
  }

  /// Marks a reminder as completed and cancels its pending notification.
  Future<void> completeReminder(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx == -1) return;

    final updated = _reminders[idx].copyWith(isCompleted: true);

    // Optimistic update
    final previous = _reminders[idx];
    _reminders = List.of(_reminders)..[idx] = updated;
    notifyListeners();

    final result = await _reminderRepo.update(updated);
    if (result case Failure(:final message)) {
      // Roll back
      _reminders = List.of(_reminders)..[idx] = previous;
      _errorMessage = message;
      notifyListeners();
      return;
    }

    await _notifService.cancelReminder(id);
  }

  /// Permanently removes a reminder and cancels its pending notification.
  Future<void> deleteReminder(String id) async {
    final removed = _reminders.firstWhere(
      (r) => r.id == id,
      orElse: () => throw StateError('Reminder not found: $id'),
    );

    // Optimistic remove
    _reminders = _reminders.where((r) => r.id != id).toList();
    notifyListeners();

    final result = await _reminderRepo.delete(id);
    if (result case Failure(:final message)) {
      // Roll back
      _reminders = [..._reminders, removed]
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _errorMessage = message;
      notifyListeners();
      return;
    }

    await _notifService.cancelReminder(id);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
