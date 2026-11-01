import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/main.dart' show logger;
import 'package:muzee/services/common_services.dart' show userRecentlyPlayed;
import 'package:muzee/services/firebase/push_service.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:timezone/timezone.dart' as tz;

/// Days without opening Muzee after which a reminder shows; the second one
/// is the last, so people who drifted away aren't nagged.
const reminderAfter = [Duration(days: 2), Duration(days: 4)];

/// Reminders never land in the quiet hours (22:00–9:00).
const _quietFrom = 22;
const _quietUntil = 9;

/// When to show the reminders, counted from [lastOpen] (local time) and
/// moved out of the quiet hours: late evening to 20:00 that day, early
/// morning to 9:00.
List<DateTime> reminderTimes(DateTime lastOpen) => [
  for (final gap in reminderAfter) _outOfQuietHours(lastOpen.add(gap)),
];

DateTime _outOfQuietHours(DateTime at) {
  if (at.hour >= _quietFrom) {
    return DateTime(at.year, at.month, at.day, 20);
  }
  if (at.hour < _quietUntil) {
    return DateTime(at.year, at.month, at.day, _quietUntil);
  }
  return at;
}

/// One scheduled reminder: what it says and what tapping it does.
@immutable
class ReminderContent {
  const ReminderContent(this.title, this.body, {this.songId});
  final String title;
  final String body;

  /// Played when the reminder is tapped; null just opens the app.
  final String? songId;
}

/// The text of reminder number [index] (0 = first). The first one names the
/// last song listened to, when there is one, and plays it on tap.
ReminderContent reminderContent(
  AppLocalizations l10n,
  int index, {
  Map? lastSong,
}) {
  if (index > 0) {
    return ReminderContent(l10n.reminderTitleLater, l10n.reminderBodyLater);
  }
  final title = lastSong?['title']?.toString().trim() ?? '';
  final artist = lastSong?['artist']?.toString().trim() ?? '';
  final songId = lastSong?['ytid']?.toString();
  if (title.isEmpty || artist.isEmpty || songId == null || songId.isEmpty) {
    return ReminderContent(l10n.reminderTitle, l10n.reminderBody);
  }
  return ReminderContent(
    l10n.reminderTitleSong(artist),
    l10n.reminderBodySong(title),
    songId: songId,
  );
}

/// "Come back" reminders, scheduled on the device: every time the app is
/// opened or left, the reminders are moved to 2 and 4 days later, so they
/// only show to someone who hasn't been back. No server involved; tapping
/// one plays the last song (or just opens the app).
class ReminderService with WidgetsBindingObserver {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'muzee_reminders';
  static const _firstId = 7100; // ids 7100, 7101…

  Future<void> init() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_stat_ic_launcher'),
          iOS: DarwinInitializationSettings(
            // Asked by the push setup, not here.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _onTap(response.payload),
      );
      _ready = true;
      // Opened by tapping a reminder while the app wasn't running.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.didNotificationLaunchApp ?? false
          ? launch?.notificationResponse?.payload
          : null;
      if (payload != null) {
        Future.delayed(const Duration(seconds: 1), () => _onTap(payload));
      }
      WidgetsBinding.instance.addObserver(this);
      listeningReminders.addListener(reschedule);
      unawaited(reschedule());
    } catch (e, stackTrace) {
      logger.log('Reminder setup failed', error: e, stackTrace: stackTrace);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving the app: count the days from now, with the song just heard.
    if (state == AppLifecycleState.paused) unawaited(reschedule());
  }

  /// Cancels the pending reminders and, when they are on, schedules them
  /// again from now.
  Future<void> reschedule() async {
    if (!_ready) return;
    try {
      for (var i = 0; i < reminderAfter.length; i++) {
        await _plugin.cancel(id: _firstId + i);
      }
      if (!listeningReminders.value) return;

      final l10n = lookupAppLocalizations(languageSetting);
      final lastSong = userRecentlyPlayed.isEmpty
          ? null
          : userRecentlyPlayed.first as Map;
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          l10n.listeningReminders,
          channelDescription: l10n.listeningRemindersDescription,
          icon: '@mipmap/ic_stat_ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      );
      final times = reminderTimes(DateTime.now());
      for (var i = 0; i < times.length; i++) {
        final content = reminderContent(l10n, i, lastSong: lastSong);
        await _plugin.zonedSchedule(
          id: _firstId + i,
          // An absolute moment: UTC needs no time-zone database.
          scheduledDate: tz.TZDateTime.from(times[i].toUtc(), tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: content.title,
          body: content.body,
          payload: content.songId ?? '',
        );
      }
    } catch (e, stackTrace) {
      logger.log(
        'Scheduling reminders failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _onTap(String? songId) {
    if (songId == null || songId.isEmpty) return;
    unawaited(
      PushService.instance.runAction(PlaySong(songId), source: 'reminder_open'),
    );
  }
}

/// Whether "come back" reminders are scheduled (Settings).
final listeningReminders = ValueNotifier<bool>(
  Hive.box('settings').get('listeningReminders', defaultValue: true),
);
