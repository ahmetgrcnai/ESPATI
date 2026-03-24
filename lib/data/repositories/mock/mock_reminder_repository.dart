import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/result.dart';
import '../../models/reminder_model.dart';
import '../interfaces/i_reminder_repository.dart';

/// [SharedPreferences]-backed implementation of [IReminderRepository].
///
/// Data persists across app restarts. All methods are O(n) over the stored
/// JSON list — acceptable for the expected reminder count (< 100).
class MockReminderRepository implements IReminderRepository {
  static const _kKey = 'espati_reminders';

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<List<ReminderModel>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return _seedDefaults();
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(ReminderModel.fromJson).toList();
    } catch (_) {
      return _seedDefaults();
    }
  }

  Future<void> _saveAll(List<ReminderModel> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kKey, jsonEncode(reminders.map((r) => r.toJson()).toList()));
  }

  /// Pre-populates with demo reminders on a fresh install.
  Future<List<ReminderModel>> _seedDefaults() async {
    final now = DateTime.now();
    final defaults = [
      ReminderModel(
        id: 'reminder_seed_001',
        petId: null,
        title: 'Luna\'nun karma aşısı',
        category: ReminderCategory.vaccine,
        dateTime: now.add(const Duration(days: 3, hours: 10)),
        isRepeating: false,
        isCompleted: false,
      ),
      ReminderModel(
        id: 'reminder_seed_002',
        petId: null,
        title: 'Max\'in sabah maması',
        category: ReminderCategory.food,
        dateTime: DateTime(now.year, now.month, now.day, 8, 0)
            .add(const Duration(days: 1)),
        isRepeating: true,
        repeatInterval: RepeatInterval.weekly,
        isCompleted: false,
      ),
      ReminderModel(
        id: 'reminder_seed_003',
        petId: null,
        title: 'Bella\'nın iç parazit ilacı',
        category: ReminderCategory.medicine,
        dateTime: now.add(const Duration(days: 7, hours: 9)),
        isRepeating: true,
        repeatInterval: RepeatInterval.monthly,
        isCompleted: false,
      ),
    ];
    await _saveAll(defaults);
    return defaults;
  }

  // ── IReminderRepository ───────────────────────────────────────────────────

  @override
  Future<Result<List<ReminderModel>>> getAll() async {
    try {
      final reminders = await _loadAll();
      reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return Success(List.unmodifiable(reminders));
    } on Exception catch (e) {
      return Failure('Hatırlatıcılar yüklenemedi.', exception: e);
    }
  }

  @override
  Future<Result<ReminderModel>> add(ReminderModel reminder) async {
    try {
      final list = await _loadAll();
      list.add(reminder);
      await _saveAll(list);
      return Success(reminder);
    } on Exception catch (e) {
      return Failure('Hatırlatıcı eklenemedi.', exception: e);
    }
  }

  @override
  Future<Result<void>> update(ReminderModel reminder) async {
    try {
      final list = await _loadAll();
      final idx = list.indexWhere((r) => r.id == reminder.id);
      if (idx == -1) return const Failure('Hatırlatıcı bulunamadı.');
      list[idx] = reminder;
      await _saveAll(list);
      return const Success(null);
    } on Exception catch (e) {
      return Failure('Hatırlatıcı güncellenemedi.', exception: e);
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final list = await _loadAll();
      list.removeWhere((r) => r.id == id);
      await _saveAll(list);
      return const Success(null);
    } on Exception catch (e) {
      return Failure('Hatırlatıcı silinemedi.', exception: e);
    }
  }
}
