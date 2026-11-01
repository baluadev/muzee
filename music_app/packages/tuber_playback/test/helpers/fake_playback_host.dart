import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:tuber_playback/tuber_playback.dart';

/// Stream URL [FakePlaybackHost] resolves [ytid] to.
String streamUrlFor(String ytid) => 'https://media.test/$ytid';

/// A [PlaybackHost] that keeps everything in memory and records what the
/// handler asked of it.
class FakePlaybackHost implements PlaybackHost {
  @override
  final ValueNotifier<bool> offlineMode = ValueNotifier(false);

  @override
  final playNextAutomatically = ValueNotifier(false);

  @override
  final shuffleEnabled = ValueNotifier(false);

  @override
  final repeatMode = ValueNotifier(AudioServiceRepeatMode.none);

  @override
  final sleepTimer = ValueNotifier<Duration?>(null);

  final savedSettings = <String, Object>{};

  /// ytids with no stream (removed, region-blocked...).
  final unplayable = <String>{};

  /// Every [resolveStream] call, in order.
  final lookups = <String>[];

  final cachedUrls = <String, String>{};
  final clearedCaches = <String>[];

  /// Downloaded songs by ytid (`audioPath`, `artworkPath`).
  final downloads = <String, Map<String, dynamic>>{};

  /// Returned by [similarSong].
  Map? similar;

  final listens = <String>[];
  final logs = <String>[];

  @override
  void savePlaybackSetting(String key, Object value) =>
      savedSettings[key] = value;

  @override
  Future<StreamPlaybackInfo?> resolveStream(
    String ytid, {
    required bool isLive,
  }) async {
    lookups.add(ytid);
    if (unplayable.contains(ytid)) return null;
    return StreamPlaybackInfo(
      url: streamUrlFor(ytid),
      isVideo: false,
      cacheKey: StreamPlaybackInfo.cacheKeyFor(ytid, isVideo: false),
    );
  }

  @override
  Future<void> cacheStreamUrl(String cacheKey, String url) async =>
      cachedUrls[cacheKey] = url;

  @override
  Future<void> clearCachedStreams(String ytid) async => clearedCaches.add(ytid);

  @override
  Map<String, dynamic> offlineSong(String ytid) => downloads[ytid] ?? {};

  @override
  Future<Map?> similarSong(String ytid) async => similar;

  /// Every [recordPlayEnd] call: ytid and whether it ran to the end.
  final playEnds = <(String, bool)>[];

  @override
  void recordPlayEnd(
    Map song, {
    required Duration position,
    required Duration? duration,
    required bool completed,
  }) => playEnds.add((song['ytid'].toString(), completed));

  @override
  Future<void> recordListen(String ytid) async => listens.add(ytid);

  @override
  void log(String message, {Object? error, StackTrace? stackTrace}) =>
      logs.add(error == null ? message : '$message: $error');
}
