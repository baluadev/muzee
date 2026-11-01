import 'package:flutter/foundation.dart';
import 'package:muzee/main.dart' show audioHandler;
import 'package:muzee/services/settings_manager.dart';

/// The sleep timer as the app shows it: when the music will stop, or that
/// it stops after the current song.
///
/// The player only knows the duration it was given; this keeps the moment
/// it ends, so the UI can count down. Both clear when the timer fires, is
/// turned off, or the player resets it.
class SleepTimer {
  SleepTimer._() {
    sleepTimerNotifier.addListener(_onPlayerTimerChanged);
  }
  static final SleepTimer instance = SleepTimer._();

  /// When the music stops; null when no timed timer runs.
  final endsAt = ValueNotifier<DateTime?>(null);

  /// "Stop after this song" is on.
  ValueListenable<bool> get afterThisSong => audioHandler.sleepAtEndOfTrack;

  /// Any kind of timer is on.
  bool get isActive => endsAt.value != null || afterThisSong.value;

  /// Rebuilds on any change to the timer.
  Listenable get changes => Listenable.merge([endsAt, afterThisSong]);

  /// Time left, or null when no timed timer runs.
  Duration? remaining([DateTime? now]) {
    final end = endsAt.value;
    if (end == null) return null;
    final left = end.difference(now ?? DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void start(Duration duration) {
    audioHandler.setSleepTimer(duration);
    endsAt.value = DateTime.now().add(duration);
  }

  void stopAfterThisSong() {
    audioHandler.setSleepAtEndOfTrack();
    endsAt.value = null;
  }

  void turnOff() {
    audioHandler.cancelSleepTimer();
    endsAt.value = null;
  }

  void _onPlayerTimerChanged() {
    final value = sleepTimerNotifier.value;
    // The player sets zero when the timer fires or is cancelled.
    if (value == null || value == Duration.zero) endsAt.value = null;
  }
}

/// [duration] as a short clock: "45:00", "1:05:30".
String formatCountdown(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = duration.inHours;
  final m = duration.inMinutes.remainder(60);
  final s = duration.inSeconds.remainder(60);
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
