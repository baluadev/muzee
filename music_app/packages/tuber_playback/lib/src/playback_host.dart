import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:tuber_playback/src/stream_playback_info.dart';

/// Writes a log line; matches the apps' `Logger.log`.
typedef PlaybackLog =
    void Function(String message, {Object? error, StackTrace? stackTrace});

/// What `TuberAudioHandler` needs from the app it runs in.
///
/// The handler owns the queue and the player; everything that depends on the
/// app (its settings, its stream cache, its offline library, its
/// recommendations) comes through here.
abstract class PlaybackHost {
  /// The user asked for offline-only playback: no stream lookups, no preload.
  ValueListenable<bool> get offlineMode;

  /// Keep playing similar songs once the queue runs out.
  ValueNotifier<bool> get playNextAutomatically;

  ValueNotifier<bool> get shuffleEnabled;

  ValueNotifier<AudioServiceRepeatMode> get repeatMode;

  /// Time left on the sleep timer; zero or null when it is off.
  ValueNotifier<Duration?> get sleepTimer;

  /// Persists a playback setting the handler changed: `shuffleEnabled`
  /// (bool), `repeatMode` ([AudioServiceRepeatMode.index]) or
  /// `playNextSongAutomatically` (bool).
  void savePlaybackSetting(String key, Object value);

  /// A playable stream for [ytid], or null when there is none (removed,
  /// region-blocked, no network...). Implementations should not throw.
  Future<StreamPlaybackInfo?> resolveStream(
    String ytid, {
    required bool isLive,
  });

  /// [url] played; remember it under [cacheKey] (see
  /// [StreamPlaybackInfo.cacheKeyFor]).
  Future<void> cacheStreamUrl(String cacheKey, String url);

  /// The cached URLs for [ytid] stopped working; drop them before the
  /// handler asks [resolveStream] again.
  Future<void> clearCachedStreams(String ytid);

  /// The downloaded copy of [ytid] (`audioPath`, `artworkPath`), or an empty
  /// map when it isn't downloaded.
  Map<String, dynamic> offlineSong(String ytid);

  /// A song to queue after [ytid] for autoplay, or null.
  Future<Map?> similarSong(String ytid);

  /// [ytid] was played again from the start; count it as a listen.
  Future<void> recordListen(String ytid);

  /// [song] stopped playing at [position] of [duration]: it ran to the end
  /// ([completed]), or the user skipped, picked another song or stopped.
  /// Apps use it to learn what the listener likes. Must not throw.
  void recordPlayEnd(
    Map song, {
    required Duration position,
    required Duration? duration,
    required bool completed,
  });

  void log(String message, {Object? error, StackTrace? stackTrace});
}
