import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REMINDER MODEL
// ─────────────────────────────────────────────────────────────────────────────

/// Category of a pet care reminder.
enum ReminderCategory {
  vaccine,
  food,
  medicine,
  walk,
  grooming,
  other;

  /// Human-readable Turkish label.
  String get label => switch (this) {
        ReminderCategory.vaccine => 'Aşı',
        ReminderCategory.food => 'Mama',
        ReminderCategory.medicine => 'İlaç',
        ReminderCategory.walk => 'Yürüyüş',
        ReminderCategory.grooming => 'Tımar',
        ReminderCategory.other => 'Diğer',
      };

  /// Icon representing this category.
  IconData get icon => switch (this) {
        ReminderCategory.vaccine => Icons.vaccines_rounded,
        ReminderCategory.food => Icons.restaurant_rounded,
        ReminderCategory.medicine => Icons.medication_rounded,
        ReminderCategory.walk => Icons.directions_walk_rounded,
        ReminderCategory.grooming => Icons.content_cut_rounded,
        ReminderCategory.other => Icons.calendar_today_rounded,
      };

  /// Accent color for the card indicator and icon.
  Color get color => switch (this) {
        ReminderCategory.vaccine => const Color(0xFFE53935),   // error red
        ReminderCategory.food => const Color(0xFFFFC107),      // amber
        ReminderCategory.medicine => const Color(0xFF2196F3),  // primary blue
        ReminderCategory.walk => const Color(0xFF4CAF50),      // green
        ReminderCategory.grooming => const Color(0xFF9C77BD),  // purple
        ReminderCategory.other => const Color(0xFF4DB6AC),     // softTeal
      };
}

/// Repeat interval for recurring reminders.
enum RepeatInterval {
  weekly,
  monthly;

  String get label => switch (this) {
        RepeatInterval.weekly => 'Haftalık',
        RepeatInterval.monthly => 'Aylık',
      };
}

/// Immutable value type representing a single pet care reminder.
///
/// Supports JSON serialisation for [SharedPreferences] persistence.
class ReminderModel {
  /// Stable, unique identifier.
  final String id;

  /// Pet this reminder belongs to. `null` = applies to all pets.
  final String? petId;

  /// Human-readable label shown on the card and in the notification title.
  final String title;

  /// Functional category.
  final ReminderCategory category;

  /// Exact date and time the reminder fires (and the notification is shown).
  final DateTime dateTime;

  /// Whether this reminder repeats on a fixed interval.
  final bool isRepeating;

  /// Interval for repeating reminders. `null` when [isRepeating] is false.
  final RepeatInterval? repeatInterval;

  /// Whether the user has ticked this reminder as done.
  ///
  /// Completed reminders cancel their pending notifications.
  final bool isCompleted;

  const ReminderModel({
    required this.id,
    this.petId,
    required this.title,
    required this.category,
    required this.dateTime,
    required this.isRepeating,
    this.repeatInterval,
    this.isCompleted = false,
  });

  ReminderModel copyWith({
    String? id,
    Object? petId = _sentinel,
    String? title,
    ReminderCategory? category,
    DateTime? dateTime,
    bool? isRepeating,
    Object? repeatInterval = _sentinel,
    bool? isCompleted,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      petId: petId == _sentinel ? this.petId : petId as String?,
      title: title ?? this.title,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      isRepeating: isRepeating ?? this.isRepeating,
      repeatInterval: repeatInterval == _sentinel
          ? this.repeatInterval
          : repeatInterval as RepeatInterval?,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // ── JSON ────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'petId': petId,
        'title': title,
        'category': category.name,
        'dateTime': dateTime.toIso8601String(),
        'isRepeating': isRepeating,
        'repeatInterval': repeatInterval?.name,
        'isCompleted': isCompleted,
      };

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
        id: json['id'] as String,
        petId: json['petId'] as String?,
        title: json['title'] as String,
        category:
            ReminderCategory.values.byName(json['category'] as String),
        dateTime: DateTime.parse(json['dateTime'] as String),
        isRepeating: json['isRepeating'] as bool,
        repeatInterval: json['repeatInterval'] != null
            ? RepeatInterval.values.byName(json['repeatInterval'] as String)
            : null,
        isCompleted: json['isCompleted'] as bool,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ReminderModel(id: $id, title: $title)';
}

// Sentinel for nullable copyWith parameters.
const Object _sentinel = Object();
