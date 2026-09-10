import '../../../core/result.dart';
import '../../models/reminder_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REMINDER REPOSITORY INTERFACE
// ─────────────────────────────────────────────────────────────────────────────

/// Contract for persistent reminder storage.
///
/// Swap [MockReminderRepository] for a Firestore / REST implementation without
/// touching the ViewModel or UI layer.
abstract class IReminderRepository {
  /// Returns all reminders sorted by [ReminderModel.dateTime] ascending.
  Future<Result<List<ReminderModel>>> getAll();

  /// Streams all reminders in real-time, sorted by [ReminderModel.dateTime]
  /// ascending. Implementations without native push updates (e.g. local
  /// storage) may emit a single snapshot instead of a live stream.
  Stream<List<ReminderModel>> watchAll();

  /// Persists a new reminder. Returns the saved model on success.
  Future<Result<ReminderModel>> add(ReminderModel reminder);

  /// Overwrites an existing reminder (matched by [ReminderModel.id]).
  Future<Result<void>> update(ReminderModel reminder);

  /// Permanently removes a reminder by [id].
  Future<Result<void>> delete(String id);
}
