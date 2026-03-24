import 'package:flutter/foundation.dart';
// Hide flutter_local_notifications' RepeatInterval to avoid collision with
// our own RepeatInterval enum in reminder_model.dart.
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide RepeatInterval;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../data/models/reminder_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION SERVICE
//
// Singleton that owns the [FlutterLocalNotificationsPlugin] instance.
// Call [init] once from main() before runApp().
// ─────────────────────────────────────────────────────────────────────────────

/// Handles initialisation, scheduling, and cancellation of local notifications.
///
/// ### Android setup required:
/// - Permissions in AndroidManifest.xml:
///   `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`
/// - BroadcastReceivers for `ScheduledNotificationReceiver` and
///   `ScheduledNotificationBootReceiver` (auto-merged from the plugin manifest)
///
/// ### iOS setup:
/// Permissions are requested at runtime via [requestPermissions]. No Info.plist
/// changes are required for local notifications.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'espati_reminders';
  static const _channelName = 'Pati Hatırlatıcıları';
  static const _channelDesc = 'Evcil hayvan bakım hatırlatmaları';

  bool _initialized = false;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Must be called once in [main] before [runApp].
  ///
  /// Sets up timezone data, Android & iOS/macOS settings, and creates the
  /// notification channel on Android 8.0+.
  Future<void> init() async {
    if (_initialized) return;

    // ── Timezone ──
    tz_data.initializeTimeZones();
    // Hardcoded to Europe/Istanbul for this Eskişehir-focused app.
    // Replace with flutter_timezone package for dynamic device timezone.
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (_) {
      // Silently fall back to UTC if timezone data is unavailable.
      debugPrint('[NotificationService] Timezone init failed — using UTC.');
    }

    // ── Android settings ──
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ── Darwin (iOS / macOS) settings ──
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We request explicitly via [requestPermissions]
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTappedBackground,
    );

    _initialized = true;
    debugPrint('[NotificationService] Initialized.');
  }

  // ── Permission Requests ───────────────────────────────────────────────────

  /// Requests notification permissions.
  ///
  /// - Android 13+ (API 33): runtime `POST_NOTIFICATIONS` dialog.
  /// - Android 12 (API 31–32): opens system settings for `SCHEDULE_EXACT_ALARM`.
  /// - iOS: native permission dialog.
  ///
  /// Returns true if all critical permissions were granted.
  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final darwin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    bool granted = true;

    if (android != null) {
      // POST_NOTIFICATIONS (Android 13+)
      final notifGranted =
          await android.requestNotificationsPermission() ?? false;

      // SCHEDULE_EXACT_ALARM (Android 12+) — opens device settings if needed
      final canSchedule =
          await android.canScheduleExactNotifications() ?? false;
      if (!canSchedule) {
        await android.requestExactAlarmsPermission();
      }

      granted = notifGranted;
    }

    if (darwin != null) {
      final iosGranted = await darwin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      granted = iosGranted;
    }

    debugPrint('[NotificationService] Permission granted: $granted');
    return granted;
  }

  // ── Scheduling ────────────────────────────────────────────────────────────

  /// Schedules a local notification to fire at [reminder.dateTime].
  ///
  /// For repeating reminders, [matchDateTimeComponents] is set so the
  /// notification recurs on the correct weekly or monthly cadence.
  ///
  /// No-ops silently if the [reminder.dateTime] is more than 1 second in the
  /// past and the reminder is not repeating.
  Future<void> scheduleReminder(ReminderModel reminder) async {
    assert(_initialized,
        'NotificationService.init() must be called before scheduling.');

    final scheduled = tz.TZDateTime.from(reminder.dateTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    // Skip one-time reminders that are already in the past.
    if (!reminder.isRepeating && scheduled.isBefore(now)) {
      debugPrint(
          '[NotificationService] Skipping past reminder: ${reminder.id}');
      return;
    }

    final details = _buildDetails(reminder);
    final matchComponents = _matchComponents(reminder);

    try {
      await _plugin.zonedSchedule(
        _notifId(reminder.id),
        reminder.title,
        _buildBody(reminder),
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
      );
      debugPrint('[NotificationService] Scheduled: ${reminder.id}');
    } catch (e) {
      debugPrint('[NotificationService] Schedule error: $e');
    }
  }

  /// Cancels the pending notification for [reminderId].
  Future<void> cancelReminder(String reminderId) async {
    await _plugin.cancel(_notifId(reminderId));
    debugPrint('[NotificationService] Cancelled: $reminderId');
  }

  /// Cancels every pending notification managed by this service.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationService] Cancelled all notifications.');
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  /// Converts a String reminder ID to a stable int notification ID.
  int _notifId(String reminderId) => reminderId.hashCode.abs() % (1 << 30);

  String _buildBody(ReminderModel reminder) {
    final catLabel = reminder.category.label;
    if (reminder.isRepeating) {
      return '$catLabel hatırlatıcısı — ${reminder.repeatInterval?.label ?? ''}';
    }
    return '$catLabel zamanı geldi! 🐾';
  }

  NotificationDetails _buildDetails(ReminderModel reminder) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        // Use a dedicated small white icon in production:
        // icon: '@drawable/ic_notification'
        icon: '@mipmap/ic_launcher',
        color: reminder.category.color,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          _buildBody(reminder),
          summaryText: 'Pati Takvimi',
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  DateTimeComponents? _matchComponents(ReminderModel reminder) {
    if (!reminder.isRepeating) return null;
    return reminder.repeatInterval == RepeatInterval.weekly
        ? DateTimeComponents.dayOfWeekAndTime
        : DateTimeComponents.dayOfMonthAndTime;
  }
}

// ── Notification tap callbacks (top-level — required by flutter_local_notifications) ──

/// Called when the user taps a notification while the app is in the foreground
/// or in the background (but not terminated).
@pragma('vm:entry-point')
void _onNotificationTapped(NotificationResponse response) {
  // TODO: navigate to the relevant reminder using a navigator key or deep link.
  debugPrint('[NotificationService] Tapped: ${response.payload}');
}

/// Called when the user taps a notification while the app is terminated.
@pragma('vm:entry-point')
void _onNotificationTappedBackground(NotificationResponse response) {
  debugPrint('[NotificationService] Background tap: ${response.payload}');
}
