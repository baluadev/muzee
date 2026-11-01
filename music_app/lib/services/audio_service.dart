import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:muzee/main.dart' show audioHandler, logger;
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/settings_manager.dart' as settings;
import 'package:tuber_playback/tuber_playback.dart';

/// Muzee's player: the shared [TuberAudioHandler] running on
/// [MuzeePlaybackHost].
class MusifyAudioHandler extends TuberAudioHandler {
  MusifyAudioHandler({super.player}) : super(host: MuzeePlaybackHost());
}

/// Connects [TuberAudioHandler] to Muzee's settings (Hive `settings` box),
/// stream lookup and URL cache, downloaded songs and recommendations.
class MuzeePlaybackHost implements PlaybackHost {
  @override
  ValueListenable<bool> get offlineMode => settings.offlineMode;

  @override
  ValueNotifier<bool> get playNextAutomatically =>
      settings.playNextSongAutomatically;

  @override
  ValueNotifier<bool> get shuffleEnabled => settings.shuffleNotifier;

  @override
  ValueNotifier<AudioServiceRepeatMode> get repeatMode =>
      settings.repeatNotifier;

  @override
  ValueNotifier<Duration?> get sleepTimer => settings.sleepTimerNotifier;

  @override
  void savePlaybackSetting(String key, Object value) {
    unawaited(Hive.box('settings').put(key, value));
  }

  @override
  Future<StreamPlaybackInfo?> resolveStream(
    String ytid, {
    required bool isLive,
  }) => fetchSongStreamInfo(ytid, isLive);

  @override
  Future<void> cacheStreamUrl(String cacheKey, String url) =>
      addOrUpdateData('cache', cacheKey, url);

  @override
  Future<void> clearCachedStreams(String ytid) async {
    await deleteData(
      'cache',
      StreamPlaybackInfo.cacheKeyFor(ytid, isVideo: true),
    );
    await deleteData(
      'cache',
      StreamPlaybackInfo.cacheKeyFor(ytid, isVideo: false),
    );
  }

  @override
  Map<String, dynamic> offlineSong(String ytid) => getOfflineSongByYtid(ytid);

  /// How many recent listens autoplay avoids repeating.
  static const _recentToSkip = 30;

  @override
  Future<Map?> similarSong(String ytid) {
    final exclude = <String>{
      for (final item in audioHandler.queue.value) '${item.extras?['ytid']}',
      for (final song in userRecentlyPlayed.take(_recentToSkip))
        '${song['ytid']}',
    };
    return getSimilarSong(ytid, exclude: exclude);
  }

  @override
  Future<void> recordListen(String ytid) => updateRecentlyPlayed(ytid);

  @override
  void recordPlayEnd(
    Map song, {
    required Duration position,
    required Duration? duration,
    required bool completed,
  }) {
    unawaited(
      tasteProfile
          .recordPlayEnd(
            song,
            position: position,
            duration: duration,
            completed: completed,
          )
          .catchError(
            (Object e, StackTrace s) =>
                logger.log('Recording a play failed', error: e, stackTrace: s),
          ),
    );
  }

  @override
  void log(String message, {Object? error, StackTrace? stackTrace}) =>
      logger.log(message, error: error, stackTrace: stackTrace);
}
