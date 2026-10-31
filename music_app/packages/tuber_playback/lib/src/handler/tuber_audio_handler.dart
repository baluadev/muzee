import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuber_playback/src/engine/media_player_adapter.dart';
import 'package:tuber_playback/src/media_item_mapping.dart';
import 'package:tuber_playback/src/playback_host.dart';
import 'package:tuber_playback/src/position_data.dart';
import 'package:tuber_playback/src/queue/queue_entry_id_manager.dart';
import 'package:tuber_playback/src/stream_playback_info.dart';
import 'package:tuber_playback/src/utils/map_utils.dart';

/// Queue-aware playback for audio_service: plays song maps (`ytid`, `title`,
/// `artist`, `highResImage`...) through [MediaPlayerAdapter], skipping songs
/// that can't be played and recovering from stream failures.
///
/// App-specific behaviour (settings, stream lookup, offline songs,
/// recommendations) comes from [host].
class TuberAudioHandler extends BaseAudioHandler {
  /// [player] defaults to a [MediaPlayerAdapter] over the native player.
  TuberAudioHandler({required this.host, MediaPlayerAdapter? player}) {
    audioPlayer = player ?? MediaPlayerAdapter();

    _setupEventSubscriptions();
    _updatePlaybackState();

    _initialize();
  }

  final PlaybackHost host;

  late final MediaPlayerAdapter audioPlayer;

  Timer? _sleepTimer;
  Timer? _debounceTimer;
  bool sleepTimerExpired = false;

  final List<Map> _queueList = [];
  final List<Map> _originalQueueList = [];
  final List<Map> _historyList = [];
  final BehaviorSubject<List<Map>> _queueMapStream =
      BehaviorSubject<List<Map>>.seeded([]);
  final QueueEntryIdManager _queueEntryIds = QueueEntryIdManager();
  int _currentQueueIndex = 0;
  int _currentLoadingIndex = -1;
  int _currentLoadingTransitionId = -1;
  bool _isUpdatingState = false;
  int _songTransitionCounter = 0;
  bool _completionEventPending = false;
  bool _completionHandlerLoadStarted = false;

  /// Bumped when user replaces the queue or picks another row; stale in-flight
  /// similar-song fetches must not call [addToQueue].
  int _queueInteractiveGeneration = 0;

  String? _lastError;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 3;

  /// Pending "move on after a failed song" step. Cancelled when the user (or
  /// the app) starts something else, so a stale retry can't override them.
  Timer? _errorRetryTimer;

  final StreamController<Map> _playbackErrors = StreamController.broadcast();

  /// The current queue song failed to start; Play retries it instead of
  /// resuming whatever the player still holds.
  bool _currentTrackFailed = false;

  /// A native player error that arrived while a load was in flight; handled
  /// once that load finishes, if the track still hasn't started.
  String? _pendingPlayerError;

  /// [_songTransitionCounter] of the last track failed by a player error, so a
  /// burst of errors for one track is handled once.
  int _playerErrorTransition = -1;

  static const int _maxHistorySize = 50;
  static const int _queueLookahead = 3;
  static const int _maxConcurrentPreloads = 2;
  static const Duration _errorRetryDelay = Duration(seconds: 2);
  static const Duration _songTransitionTimeout = Duration(seconds: 30);
  static const Duration _debounceInterval = Duration(milliseconds: 150);

  int _activePreloadCount = 0;
  final Set<String> _preloadingYtIds = <String>{};
  final Set<String> _preloadedYtIds = <String>{};

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        audioPlayer.positionStream,
        audioPlayer.bufferedPositionStream,
        audioPlayer.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      ).distinct((prev, curr) {
        const threshold = Duration(milliseconds: 500);
        return (prev.position - curr.position).abs() < threshold &&
            prev.duration == curr.duration &&
            (prev.bufferedPosition - curr.bufferedPosition).abs() < threshold;
      });

  Stream<PlaybackState> get playbackStateStream => playbackState.distinct(
    (prev, curr) =>
        prev.playing == curr.playing &&
        prev.processingState == curr.processingState &&
        prev.queueIndex == curr.queueIndex,
  );

  static const _playingControls = [
    MediaControl.skipToPrevious,
    MediaControl.pause,
    MediaControl.stop,
    MediaControl.skipToNext,
  ];

  static const _pausedControls = [
    MediaControl.skipToPrevious,
    MediaControl.play,
    MediaControl.stop,
    MediaControl.skipToNext,
  ];

  final processingStateMap = {
    MusifyProcessingState.idle: AudioProcessingState.idle,
    MusifyProcessingState.loading: AudioProcessingState.loading,
    MusifyProcessingState.buffering: AudioProcessingState.buffering,
    MusifyProcessingState.ready: AudioProcessingState.ready,
    MusifyProcessingState.completed: AudioProcessingState.completed,
  };

  void _setupEventSubscriptions() {
    audioPlayer.playbackEventStream
        .throttleTime(const Duration(milliseconds: 100))
        .listen(
          (event) {
            _updatePlaybackState();
          },
          onError: (error, stackTrace) {
            host.log(
              'Playback event stream error',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );

    audioPlayer.processingStateStream.distinct().listen(
      _handleProcessingStateChange,
      onError: (error, stackTrace) {
        host.log(
          'Processing state stream error',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    audioPlayer.errorStream.listen(
      _handlePlayerError,
      onError: (error, stackTrace) {
        host.log(
          'Player error stream error',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    audioPlayer.durationStream
        .distinct()
        .throttleTime(const Duration(milliseconds: 200))
        .listen(
          (duration) {
            if (_currentQueueIndex < _queueList.length && duration != null) {
              _updateCurrentMediaItemWithDuration(duration);
            }
          },
          onError: (error, stackTrace) {
            host.log(
              'Duration stream error',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );

    audioPlayer.playerStateStream
        .distinct()
        .throttleTime(const Duration(milliseconds: 100))
        .listen(
          (state) {
            if (state.processingState == MusifyProcessingState.idle &&
                !state.playing &&
                _lastError != null) {
              Future.microtask(_handlePlaybackError);
            }
            _debouncedStateUpdate();
          },
          onError: (error, stackTrace) {
            host.log(
              'Player state stream error',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }

  void _debouncedStateUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceInterval, () {
      if (!_isUpdatingState) {
        _updatePlaybackState();
      }
    });
  }

  void _hydrateQueueEntryIds() {
    _queueEntryIds
      ..ensureIds(_queueList)
      ..ensureIds(_originalQueueList);
  }

  /// The downloaded copy of [song], or an empty map.
  Map<String, dynamic> _offlineSongOf(Map song) {
    final ytid = song['ytid']?.toString();
    return ytid == null || ytid.isEmpty ? const {} : host.offlineSong(ytid);
  }

  MediaItem _mediaItemFor(Map song) =>
      mapToMediaItem(song, offlineSong: _offlineSongOf(song));

  MediaItem _getMediaItemForQueue(Map song) {
    return _mediaItemFor(song).copyWith(id: _queueEntryIds.ensureId(song));
  }

  void _syncCurrentQueueVideoMetadata(Map songData) {
    if (_currentQueueIndex < 0 || _currentQueueIndex >= _queueList.length) {
      return;
    }

    final isVideo = songData['isVideo'] == true;
    final videoSource = songData['videoSource'];
    final currentSong = _queueList[_currentQueueIndex];
    currentSong['isVideo'] = isVideo;
    currentSong['videoSource'] = isVideo ? videoSource : null;

    final queueEntryId = currentSong['queueEntryId'];
    if (queueEntryId != null) {
      for (final song in _originalQueueList) {
        if (song['queueEntryId'] == queueEntryId) {
          song['isVideo'] = isVideo;
          song['videoSource'] = isVideo ? videoSource : null;
          break;
        }
      }
    }
  }

  void _updateCurrentMediaItemWithDuration(Duration duration) {
    final capturedQueueIndex = _currentQueueIndex;
    final capturedTransitionCounter = _songTransitionCounter;

    Future.microtask(() async {
      try {
        if (_currentQueueIndex >= _queueList.length) return;

        // If state changed while waiting for microtask, abort
        if (capturedQueueIndex != _currentQueueIndex ||
            capturedTransitionCounter != _songTransitionCounter) {
          return;
        }

        final currentSong = _queueList[capturedQueueIndex];
        final currentMediaItem = _getMediaItemForQueue(currentSong);
        final uniqueId = currentMediaItem.id;
        final currentItem = mediaItem.valueOrNull;
        final mergedExtras = <String, dynamic>{
          ...?currentMediaItem.extras,
          ...?currentItem?.extras,
        };

        if (currentItem != null &&
            currentItem.id == uniqueId &&
            (currentItem.duration == null ||
                !durationEquals(currentItem.duration, duration))) {
          mediaItem.add(
            currentMediaItem.copyWith(duration: duration, extras: mergedExtras),
          );
        }

        final newQueue = _queueList
            .asMap()
            .entries
            .map((entry) => _getMediaItemForQueue(entry.value))
            .toList();

        if (capturedQueueIndex < newQueue.length) {
          newQueue[capturedQueueIndex] = newQueue[capturedQueueIndex].copyWith(
            duration: duration,
          );
          queue.add(newQueue);
        }
      } catch (e, stackTrace) {
        host.log(
          'Error updating media item with duration',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<void> _initialize() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      await audioPlayer.setLoopMode(MusifyLoopMode.off);

      // Apply stored shuffle mode to audio player
      await audioPlayer.setShuffleModeEnabled(host.shuffleEnabled.value);
    } catch (e, stackTrace) {
      host.log(
        'Error initializing audio session',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<MusifyEqualizerParameters?> getEqualizerParameters() async => null;

  Future<void> setEqualizerEnabled(bool enabled) async {}

  Future<void> setEqualizerBandGain(int index, double gain) async {}

  Future<void> resetEqualizerBands() async {}

  bool _hasSignificantPositionChange(
    Duration currentPosition,
    Duration lastUpdatePosition,
    DateTime lastUpdateTime,
    DateTime now,
    double speed,
  ) {
    final expectedPosition =
        lastUpdatePosition + (now.difference(lastUpdateTime)) * speed;
    return (currentPosition - expectedPosition).abs() >
        const Duration(milliseconds: 500);
  }

  void _updatePlaybackState() {
    if (_isUpdatingState) return;

    _isUpdatingState = true;

    Future.microtask(() {
      try {
        final now = DateTime.now();
        final currentPosition = audioPlayer.position;
        final isPlaying = audioPlayer.playing;
        final currentState = playbackState.valueOrNull;
        final newProcessingState =
            processingStateMap[audioPlayer.processingState] ??
            AudioProcessingState.idle;

        final shouldUpdate =
            currentState == null ||
            currentState.playing != isPlaying ||
            currentState.processingState != newProcessingState ||
            currentState.queueIndex != _currentQueueIndex ||
            (_hasSignificantPositionChange(
              currentPosition,
              currentState.updatePosition,
              currentState.updateTime,
              now,
              currentState.speed,
            ));

        if (shouldUpdate) {
          playbackState.add(
            PlaybackState(
              controls: isPlaying ? _playingControls : _pausedControls,
              systemActions: const {
                MediaAction.seek,
                MediaAction.seekForward,
                MediaAction.seekBackward,
              },
              androidCompactActionIndices: const [0, 1, 3],
              processingState: newProcessingState,
              playing: isPlaying,
              updatePosition: currentPosition,
              bufferedPosition: audioPlayer.bufferedPosition,
              speed: audioPlayer.speed,
              queueIndex: _currentQueueIndex < _queueList.length
                  ? _currentQueueIndex
                  : null,
              updateTime: now,
            ),
          );
        }
      } catch (e, stackTrace) {
        host.log(
          'Error updating playback state',
          error: e,
          stackTrace: stackTrace,
        );
      } finally {
        _isUpdatingState = false;
      }
    });
  }

  void _handleProcessingStateChange(MusifyProcessingState state) {
    try {
      if (state == MusifyProcessingState.completed) {
        if (!sleepTimerExpired && !_completionEventPending) {
          _completionEventPending = true;

          Future.microtask(() async {
            try {
              if (!sleepTimerExpired && _completionEventPending) {
                await _handleSongCompletion();
              }
            } finally {
              // Only reset if still marked as pending (another event didn't override)
              if (_completionEventPending) {
                _completionEventPending = false;
                _completionHandlerLoadStarted = false;
              }
              // else {
              //   host.log(
              //     '[COMPLETION] Flag already false in finally block (was overridden)',
              //     null,
              //     null,
              //   );
              // }
            }
          });
        }
      } else if (state == MusifyProcessingState.ready) {
        _completionEventPending = false;
        _completionHandlerLoadStarted = false;
        // Only a track that actually started counts as a success; a load that
        // "succeeds" and then fails to stream must not reset the error count.
        _consecutiveErrors = 0;
        _currentTrackFailed = false;
      }
    } catch (e, stackTrace) {
      host.log(
        'Error handling processing state change',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  bool _canRetryPlayback() =>
      hasNext ||
      (host.repeatMode.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) ||
      host.playNextAutomatically.value;

  void _handlePlaybackError() {
    _consecutiveErrors++;
    _currentTrackFailed = true;
    host.log(
      'Playback error occurred. Consecutive errors: $_consecutiveErrors',
      error: _lastError,
    );

    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      host.log('Max consecutive errors reached. Stopping playback.');
      // stop() keeps the last `playing` flag, which a failed load may have
      // set; show Play, not Pause.
      unawaited(stop().then((_) => _showStoppedAfterFailure()));
      return;
    }

    if (_canRetryPlayback()) {
      _errorRetryTimer?.cancel();
      _errorRetryTimer = Timer(_errorRetryDelay, () {
        _errorRetryTimer = null;
        skipToNext();
      });
    } else {
      _showStoppedAfterFailure();
    }
  }

  /// Nothing else will update the state after a failed load, so replace the
  /// "loading" spinner with a paused state; Play then retries the song.
  void _showStoppedAfterFailure() {
    final state = playbackState.valueOrNull;
    if (state == null) return;
    playbackState.add(
      state.copyWith(
        controls: _pausedControls,
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  void _handlePlayerError(String message) {
    host.log('Player error', error: message);
    if (_currentLoadingIndex >= 0) {
      // playSong is still running; decide once it has finished.
      _pendingPlayerError = message;
      return;
    }
    _failTrackOnPlayerError(message);
  }

  /// Fails the current track when the native player reports an error before
  /// the track started (e.g. the network dropped after the stream URL was
  /// resolved). Errors while audio is already playing are left to the player,
  /// which retries and otherwise ends the track.
  void _failTrackOnPlayerError(String message) {
    final state = audioPlayer.processingState;
    if (state == MusifyProcessingState.ready ||
        state == MusifyProcessingState.completed) {
      return;
    }
    if (_playerErrorTransition == _songTransitionCounter) return;
    _playerErrorTransition = _songTransitionCounter;

    final current = mediaItem.valueOrNull;
    final song = current != null ? mediaItemToMap(current) : currentSong;
    if (song == null) return;

    _lastError = message;
    _playbackErrors.add(cloneMap(song));
    _handlePlaybackError();
  }

  void _cancelErrorRetry() {
    _errorRetryTimer?.cancel();
    _errorRetryTimer = null;
  }

  Future<void> _handleSongCompletion() async {
    try {
      if (_currentQueueIndex >= 0 && _currentQueueIndex < _queueList.length) {
        _addToHistory(_queueList[_currentQueueIndex]);
      }

      // Determine what to play next based on queue position and repeat mode
      if (host.repeatMode.value == AudioServiceRepeatMode.one) {
        // Repeat single song - play current song again
        await _playFromQueue(_currentQueueIndex);
      } else {
        // For all other cases (next song, repeat all, auto-play), skipToNext handles it
        await skipToNext();
      }
    } catch (e, stackTrace) {
      host.log(
        'Error handling song completion',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _bumpQueueInteractiveGeneration() {
    _queueInteractiveGeneration++;
  }

  Future<void> _backgroundAddSongsToQueue(int generationWhenScheduled) async {
    // Fire and forget - this runs as a background task without blocking playback
    if (host.offlineMode.value) return;

    // Use microtask to avoid blocking the current operation
    unawaited(
      Future.microtask(() async {
        try {
          if (generationWhenScheduled != _queueInteractiveGeneration) {
            return;
          }
          // Only add songs if we're still playing
          if (!audioPlayer.playing) {
            return;
          }

          final baseSong = _getCurrentSongForRecommendations();
          if (baseSong == null) {
            return;
          }

          // Fetch similar songs silently in the background
          final songToAdd = await host
              .similarSong(baseSong['ytid'].toString())
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  host.log('Background song fetch timed out');
                  return null;
                },
              );

          if (generationWhenScheduled != _queueInteractiveGeneration) {
            return;
          }
          // If we got a recommendation, add it to the queue
          // But only if still playing (user might have paused during fetch)
          if (!audioPlayer.playing) {
            return;
          }

          if (songToAdd != null) {
            // Queue after current track so autoplay reaches it; end-of-queue felt "broken".
            await addToQueue(songToAdd, playNext: true);
            host.log(
              'Background song queued after current: "${songToAdd['title']}" '
              '(ytid=${songToAdd['ytid']})',
            );
          }
        } catch (e, stackTrace) {
          host.log(
            'Error in background song addition',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }),
    );
  }

  Map? _getCurrentSongForRecommendations() {
    final currentMediaItem = mediaItem.valueOrNull;

    if (currentMediaItem == null || currentMediaItem.id.isEmpty) {
      host.log('No current media item available');
      return null;
    }

    return mediaItemToMap(currentMediaItem);
  }

  void _addToHistory(Map song) {
    try {
      _historyList.insert(0, cloneMap(song));

      if (_historyList.length > _maxHistorySize) {
        _historyList.removeRange(_maxHistorySize, _historyList.length);
      }
    } catch (e, stackTrace) {
      host.log('Error adding to history', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> addToQueue(Map song, {bool playNext = false}) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        host.log('Invalid song data for queue');
        return;
      }

      int insertIndex;

      if (playNext) {
        insertIndex = _currentQueueIndex + 1;
        if (insertIndex < 0) insertIndex = 0;
        if (insertIndex > _queueList.length) {
          insertIndex = _queueList.length;
        }
      } else {
        insertIndex = _queueList.length;
      }

      final queueSong = _queueEntryIds.createSong(song);
      queueSong['isManuallyAdded'] = true;
      _queueList.insert(insertIndex, queueSong);

      if (_currentQueueIndex < 0) {
        _currentQueueIndex = 0;
      }

      _updateQueueMediaItems();
      _cleanupOldPreloadedSongs();

      if (!audioPlayer.playing && _queueList.length == 1) {
        await _playFromQueue(0);
      }
    } catch (e, stackTrace) {
      host.log('Error adding to queue', error: e, stackTrace: stackTrace);
    }
  }

  void _cleanupOldPreloadedSongs() {
    Future.microtask(() async {
      try {
        final queueYtIds = _queueList
            .map((song) => song['ytid']?.toString())
            .where((ytid) => ytid != null)
            .toSet();

        final oldPreloadedSongs = _preloadedYtIds
            .where((ytid) => !queueYtIds.contains(ytid))
            .toList();

        for (final ytid in oldPreloadedSongs) {
          _preloadedYtIds.remove(ytid);
        }

        final stalePreloadingEntries = _preloadingYtIds
            .where((ytid) => !queueYtIds.contains(ytid))
            .toList();

        for (final ytid in stalePreloadingEntries) {
          _preloadingYtIds.remove(ytid);
        }

        if (oldPreloadedSongs.isNotEmpty || stalePreloadingEntries.isNotEmpty) {
          host.log(
            'Cleaned up ${oldPreloadedSongs.length + stalePreloadingEntries.length} old preload entries',
          );
        }
      } catch (e, stackTrace) {
        host.log(
          'Error cleaning up preloaded songs',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<void> addPlaylistToQueue(
    List<Map> songs, {
    bool replace = false,
    int? startIndex,
  }) async {
    try {
      final manuallyAddedSongs = replace ? _getUnplayedManualSongs() : <Map>[];
      if (replace) {
        _bumpQueueInteractiveGeneration();
        _queueList.clear();
        _originalQueueList.clear();
        _currentQueueIndex = 0;
        _currentLoadingIndex = -1;
        _currentLoadingTransitionId = -1;
        _resetPreloadingState();
        host.shuffleEnabled.value = false;
        host.savePlaybackSetting('shuffleEnabled', false);
        await audioPlayer.setShuffleModeEnabled(false);
      }

      int? targetQueueIndex;
      final sourceIndexToQueueIndex = <int, int>{};

      for (var i = 0; i < songs.length; i++) {
        final song = songs[i];
        if (song['ytid'] != null && song['ytid'].toString().isNotEmpty) {
          _queueList.add(_queueEntryIds.createSong(song));
          sourceIndexToQueueIndex[i] = _queueList.length - 1;
        }
      }

      if (replace && startIndex != null) {
        final si = startIndex;
        targetQueueIndex = sourceIndexToQueueIndex[si];
        if (targetQueueIndex == null && si < songs.length) {
          for (var j = si + 1; j < songs.length; j++) {
            final qIdx = sourceIndexToQueueIndex[j];
            if (qIdx != null) {
              targetQueueIndex = qIdx;
              host.log(
                'Playlist row $si has no valid ytid; starting at '
                'next playable row $j instead.',
              );
              break;
            }
          }
        }
        if (targetQueueIndex == null && si < songs.length) {
          host.log(
            'Cannot play playlist row $si: no ytid and no playable '
            'rows after it.',
          );
        }
      }

      if (replace && manuallyAddedSongs.isNotEmpty) {
        // Always insert after the starting song index
        final insertIndex = (targetQueueIndex ?? 0) + 1;
        final safeInsertIndex = insertIndex > _queueList.length
            ? _queueList.length
            : insertIndex;
        _queueList.insertAll(safeInsertIndex, manuallyAddedSongs);
      }

      _hydrateQueueEntryIds();
      _updateQueueMediaItems();

      if (targetQueueIndex != null) {
        await _playFromQueue(targetQueueIndex);
      } else if (startIndex != null &&
          startIndex < _queueList.length &&
          !replace) {
        await _playFromQueue(startIndex);
      } else if (replace && _queueList.isNotEmpty) {
        await _playFromQueue(0);
        if (startIndex != null && sourceIndexToQueueIndex[startIndex] == null) {
          host.log(
            'Playlist play: tapped row $startIndex had no ytid and no later '
            'playable row — started first queued song instead.',
          );
        }
      }
    } catch (e, stackTrace) {
      host.log(
        'Error adding playlist to queue',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> removeFromQueue(int index) async {
    try {
      if (index < 0 || index >= _queueList.length) return;

      final removedSong = _queueList[index];
      final removedQueueEntryId = _queueEntryIds.ensureId(removedSong);
      _queueList.removeAt(index);

      if (host.shuffleEnabled.value && _originalQueueList.isNotEmpty) {
        _originalQueueList.removeWhere(
          (s) => _queueEntryIds.ensureId(s) == removedQueueEntryId,
        );
      }

      if (index == _currentLoadingIndex) {
        _currentLoadingIndex = -1;
        _currentLoadingTransitionId = -1;
      } else if (index < _currentLoadingIndex) {
        _currentLoadingIndex--;
      }

      if (index < _currentQueueIndex) {
        _currentQueueIndex--;
      } else if (index == _currentQueueIndex) {
        if (_queueList.isEmpty) {
          await stop();
        } else {
          if (_currentQueueIndex >= _queueList.length) {
            _currentQueueIndex = _queueList.length - 1;
          }
          await _playFromQueue(_currentQueueIndex);
        }
      }

      _hydrateQueueEntryIds();
      _updateQueueMediaItems();
    } catch (e, stackTrace) {
      host.log('Error removing from queue', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      _queueEntryIds.ensureIds(_queueList);

      if (oldIndex < 0 ||
          oldIndex >= _queueList.length ||
          newIndex < 0 ||
          newIndex > _queueList.length - 1) {
        return;
      }

      final song = _queueList.removeAt(oldIndex);
      _queueList.insert(newIndex, song);

      if (oldIndex == _currentQueueIndex) {
        _currentQueueIndex = newIndex;
      } else if (oldIndex < _currentQueueIndex &&
          newIndex >= _currentQueueIndex) {
        _currentQueueIndex--;
      } else if (oldIndex > _currentQueueIndex &&
          newIndex <= _currentQueueIndex) {
        _currentQueueIndex++;
      }

      // Also update _currentLoadingIndex if the currently-loading song is being reordered
      if (oldIndex == _currentLoadingIndex) {
        _currentLoadingIndex = newIndex;
      } else if (oldIndex < _currentLoadingIndex &&
          newIndex >= _currentLoadingIndex) {
        _currentLoadingIndex--;
      } else if (oldIndex > _currentLoadingIndex &&
          newIndex <= _currentLoadingIndex) {
        _currentLoadingIndex++;
      }

      _updateQueueMediaItems();
    } catch (e, stackTrace) {
      host.log('Error reordering queue', error: e, stackTrace: stackTrace);
    }
  }

  void clearQueue() {
    _cancelErrorRetry();
    try {
      _queueList.clear();
      _originalQueueList.clear();
      _currentQueueIndex = 0;
      _currentLoadingIndex = -1;
      _currentLoadingTransitionId = -1;
      _resetPreloadingState();
      _updateQueueMediaItems();
    } catch (e, stackTrace) {
      host.log('Error clearing queue', error: e, stackTrace: stackTrace);
    }
  }

  void _updateQueueMediaItems() {
    try {
      _queueEntryIds.ensureIds(_queueList);

      final mediaItems = _queueList
          .asMap()
          .entries
          .map((entry) => _getMediaItemForQueue(entry.value))
          .toList();
      queue.add(mediaItems);

      _queueMapStream.add(List.unmodifiable(_queueList));

      if (_currentQueueIndex < mediaItems.length) {
        final currentMediaItem = mediaItems[_currentQueueIndex];
        mediaItem.add(currentMediaItem);
      }
    } catch (e, stackTrace) {
      host.log(
        'Error updating queue media items',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _emitOptimisticLoadingState({
    Map? song,
    int? queueIndex,
    bool includeMediaItem = false,
    String? mediaId,
  }) {
    try {
      if (includeMediaItem && song != null) {
        var immediateMediaItem = _mediaItemFor(song);
        if (mediaId != null) {
          immediateMediaItem = immediateMediaItem.copyWith(id: mediaId);
        }
        Future.microtask(() {
          mediaItem.add(immediateMediaItem);
        });
      }

      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: AudioProcessingState.loading,
          queueIndex:
              queueIndex ??
              (_currentQueueIndex < _queueList.length
                  ? _currentQueueIndex
                  : null),
          updateTime: DateTime.now(),
        ),
      );
    } catch (e, stackTrace) {
      host.log(
        'Error emitting optimistic loading state',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _playFromQueue(int index) async {
    if (index < 0 || index >= _queueList.length) {
      host.log('Invalid queue index: $index');
      return;
    }

    // If already loading any song, skip the request
    // UNLESS we're in the middle of handling a completion event (allow one load attempt)
    if (_currentLoadingIndex == index && !_completionEventPending) {
      return;
    }

    if (_currentLoadingIndex >= 0 &&
        _completionEventPending &&
        !_completionHandlerLoadStarted) {
      _completionHandlerLoadStarted = true;
    } else if (_currentLoadingIndex >= 0 &&
        _completionEventPending &&
        _completionHandlerLoadStarted) {
      return;
    }

    // Start new transition
    _cancelErrorRetry();
    _currentTrackFailed = false;
    _pendingPlayerError = null;
    _songTransitionCounter++;
    final currentTransitionId = _songTransitionCounter;
    _currentLoadingIndex = index;
    _currentLoadingTransitionId = currentTransitionId;

    try {
      _currentQueueIndex = index;

      final currentSong = _queueList[_currentQueueIndex];
      final currentMediaItem = _getMediaItemForQueue(currentSong);
      final uniqueId = currentMediaItem.id;

      await Future.microtask(() {
        mediaItem.add(currentMediaItem);
      });

      _emitOptimisticLoadingState(
        queueIndex: _currentQueueIndex,
        mediaId: uniqueId,
      );

      final success = await playSong(
        _queueList[index],
        mediaId: uniqueId,
        transitionId: currentTransitionId,
      );

      // Only process result if this is still the current transition
      if (currentTransitionId == _currentLoadingTransitionId) {
        if (success) {
          _preloadUpcomingSongs();
          // Trigger background song addition if auto-play is enabled
          if (host.playNextAutomatically.value) {
            final genAtSchedule = _queueInteractiveGeneration;
            unawaited(_backgroundAddSongsToQueue(genAtSchedule));
          }
        } else {
          // Stay on the failed song so the retry's skipToNext moves past it.
          _handlePlaybackError();
        }
        final pendingError = _pendingPlayerError;
        _pendingPlayerError = null;
        if (success && pendingError != null) {
          _failTrackOnPlayerError(pendingError);
        }
      }
    } catch (e, stackTrace) {
      host.log('Error playing from queue', error: e, stackTrace: stackTrace);
      _handlePlaybackError();
    } finally {
      // Only reset if this is still the transition that started it
      if (currentTransitionId == _currentLoadingTransitionId) {
        _currentLoadingIndex = -1;
        _currentLoadingTransitionId = -1;
      }
    }
  }

  /// Preloading spends network on songs that may never play; only do it
  /// while something is actually playing or loading.
  bool get _preloadAllowed =>
      !host.offlineMode.value &&
      !_currentTrackFailed &&
      playbackState.valueOrNull?.processingState != AudioProcessingState.idle;

  void _preloadUpcomingSongs() {
    if (!_preloadAllowed) return;

    Future.microtask(() async {
      try {
        final songsToPreload = <Map>[];

        for (var i = 1; i <= _queueLookahead; i++) {
          final nextIndex = _currentQueueIndex + i;
          if (nextIndex < _queueList.length) {
            final nextSong = _queueList[nextIndex];
            final ytid = nextSong['ytid'];

            if (ytid != null &&
                host.offlineSong(ytid.toString()).isEmpty &&
                !_preloadedYtIds.contains(ytid) &&
                !_preloadingYtIds.contains(ytid)) {
              songsToPreload.add(nextSong);
            }
          }
        }

        await _preloadSongsSequentially(songsToPreload);
      } catch (e, stackTrace) {
        host.log(
          'Error in _preloadUpcomingSongs',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<void> _preloadSongsSequentially(List<Map> songsToPreload) async {
    for (final song in songsToPreload) {
      while (_activePreloadCount >= _maxConcurrentPreloads) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Playback may have stopped (or failed) while waiting for a slot.
      if (!_preloadAllowed) return;

      final ytid = song['ytid'];
      if (ytid == null || _preloadingYtIds.contains(ytid)) {
        continue;
      }

      unawaited(_preloadSingleSongControlled(song));
    }
  }

  Future<void> _preloadSingleSongControlled(Map nextSong) async {
    final ytid = nextSong['ytid'];
    if (ytid == null) return;

    _preloadingYtIds.add(ytid);
    _activePreloadCount++;
    String? preloadUrl;

    try {
      // Don't attempt to fetch remote streams while offline mode is enabled
      if (host.offlineMode.value) {
        host.log('Offline mode enabled; skipping preload for $ytid');
        preloadUrl = null;
      } else {
        // The host handles caching, freshness checks, and validation
        final info = await host
            .resolveStream(ytid, isLive: nextSong['isLive'] ?? false)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                host.log('Preload timeout for song $ytid');
                return null;
              },
            );
        preloadUrl = info?.url;
      }
    } catch (e, stackTrace) {
      host.log('Error preloading song $ytid', error: e, stackTrace: stackTrace);
    } finally {
      _preloadingYtIds.remove(ytid);
      if (_activePreloadCount > 0) {
        _activePreloadCount--;
      }
      if (preloadUrl != null && preloadUrl.isNotEmpty) {
        _preloadedYtIds.add(ytid);
      }
    }
  }

  List<Map> get currentQueue => List.unmodifiable(_queueList);
  List<Map> get playHistory => List.unmodifiable(_historyList);

  /// Songs that could not be played (removed, region-blocked, no network).
  Stream<Map> get playbackErrors => _playbackErrors.stream;

  Stream<List<Map>> get queueAsMapStream => _queueMapStream.stream;
  int get currentQueueIndex => _currentQueueIndex;
  Map? get currentSong =>
      _currentQueueIndex >= 0 && _currentQueueIndex < _queueList.length
      ? _queueList[_currentQueueIndex]
      : null;

  bool get hasNext => _currentQueueIndex < _queueList.length - 1;

  bool get hasPrevious => _currentQueueIndex > 0 || _historyList.isNotEmpty;

  @override
  Future<void> onTaskRemoved() async {
    try {
      await stop();
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e, stackTrace) {
      host.log('Error in onTaskRemoved', error: e, stackTrace: stackTrace);
    }
    await super.onTaskRemoved();
  }

  @override
  Future<void> play() async {
    // After a failed load the player still holds the previous track; Play
    // means "try this song again", not "resume the old one".
    if (_currentTrackFailed &&
        currentSong != null &&
        _currentLoadingIndex < 0) {
      await _playFromQueue(_currentQueueIndex);
      return;
    }
    try {
      await audioPlayer.play();
    } catch (e, stackTrace) {
      host.log('Error in play()', error: e, stackTrace: stackTrace);
      _lastError = e.toString();
    }
  }

  @override
  Future<void> pause() async {
    _cancelErrorRetry();
    try {
      await audioPlayer.pause();
    } catch (e, stackTrace) {
      host.log('Error in pause()', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> stop() async {
    _debounceTimer?.cancel();
    _cancelErrorRetry();
    _completionEventPending = false;
    _currentLoadingIndex = -1;
    _currentLoadingTransitionId = -1;
    // Before the player stops: its idle state arrives while stop() is still
    // running, and with an error still recorded it would count as another
    // failed song.
    _lastError = null;
    try {
      await audioPlayer.stop();
      _consecutiveErrors = 0;
      _resetPreloadingState();
    } catch (e, stackTrace) {
      host.log('Error in stop()', error: e, stackTrace: stackTrace);
    }
    await super.stop();
  }

  /// Returns unplayed manually added songs after the current queue index.
  List<Map> _getUnplayedManualSongs() {
    return _queueList
        .skip(_currentQueueIndex >= 0 ? _currentQueueIndex + 1 : 0)
        .where((song) => song['isManuallyAdded'] == true)
        .toList();
  }

  void _resetPreloadingState() {
    _activePreloadCount = 0;
    _preloadingYtIds.clear();
    _preloadedYtIds.clear();
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await audioPlayer.seek(position);
    } catch (e, stackTrace) {
      host.log('Error in seek()', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> fastForward() =>
      seek(Duration(seconds: audioPlayer.position.inSeconds + 15));

  @override
  Future<void> rewind() =>
      seek(Duration(seconds: audioPlayer.position.inSeconds - 15));

  Future<bool> _resolveOfflineAndSetPaths(Map songData) async {
    try {
      final ytid = songData['ytid']?.toString();
      if (ytid != null && ytid.isNotEmpty) {
        final offlineSong = host.offlineSong(ytid);
        if (offlineSong.isNotEmpty) {
          final audioPath = offlineSong['audioPath']?.toString();
          if (audioPath != null && audioPath.isNotEmpty) {
            final f = File(audioPath);
            if (await f.exists()) {
              songData['audioPath'] = audioPath;
              if (offlineSong['artworkPath'] != null) {
                songData['artworkPath'] = offlineSong['artworkPath'];
              }
              return true;
            }
          }
        }
      }
    } catch (e, st) {
      host.log('Error while checking offline songs', error: e, stackTrace: st);
    }

    // Fallback: prefer an existing local `audioPath` on the passed song
    // object if the file exists.
    try {
      final path = songData['audioPath']?.toString();
      if (path != null && path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) return true;
      }
    } catch (_) {}

    return false;
  }

  /// Check if the given transitionId is stale (outdated by a newer request).
  bool _isStaleTransition(int? transitionId) {
    return transitionId != null && transitionId != _currentLoadingTransitionId;
  }

  Future<bool> playSong(Map song, {String? mediaId, int? transitionId}) async {
    final success = await _loadAndPlay(
      song,
      mediaId: mediaId,
      transitionId: transitionId,
    );
    // A load superseded by a newer request is not an error worth reporting.
    if (!success && !_isStaleTransition(transitionId)) {
      _playbackErrors.add(cloneMap(song));
      // Queue loads (with a transitionId) settle the state in
      // _handlePlaybackError; a direct call has nothing else to do it.
      if (transitionId == null) _showStoppedAfterFailure();
    }
    return success;
  }

  Future<bool> _loadAndPlay(
    Map song, {
    String? mediaId,
    int? transitionId,
  }) async {
    try {
      final songData = cloneMap(song);

      if (songData['ytid'] == null || songData['ytid'].toString().isEmpty) {
        host.log('Invalid song data: missing ytid');
        return false;
      }

      _lastError = null;
      if (audioPlayer.playing) await audioPlayer.pause();

      final playback = await _resolvePlaybackSource(songData);

      // Abort if a newer song was requested while we were fetching the stream URL.
      // This is the primary guard against the race condition where a slow streaming
      // load overrides a song the user already switched to.
      if (_isStaleTransition(transitionId)) {
        host.log(
          'Song load superseded by newer request, aborting: ${songData['ytid']}',
        );
        return false;
      }

      if (playback == null) {
        _lastError = 'Failed to get song URL';
        return false;
      }
      _syncCurrentQueueVideoMetadata(songData);

      _emitOptimisticLoadingState(
        song: songData,
        includeMediaItem: true,
        mediaId: mediaId,
      );

      final audioSource = await buildAudioSource(
        songData,
        playback.songUrl,
        playback.isOffline,
      );

      // Check again after building the audio source (SponsorBlock fetch can also be slow).
      if (_isStaleTransition(transitionId)) {
        host.log(
          'Song load superseded after building audio source, aborting: ${songData['ytid']}',
        );
        return false;
      }

      if (audioSource == null) {
        host.log('Failed to build audio source for ${songData['ytid']}');
        _lastError = 'Failed to build audio source';
        return false;
      }

      return await _setAudioSourceAndPlay(
        songData,
        audioSource,
        playback.songUrl,
        playback.isOffline,
        mediaId: mediaId,
        transitionId: transitionId,
      );
    } catch (e, stackTrace) {
      host.log('Error playing song', error: e, stackTrace: stackTrace);
      _lastError = e.toString();
      return false;
    }
  }

  Future<_PlaybackSource?> _resolvePlaybackSource(Map songData) async {
    final isOffline = await _resolveOfflineAndSetPaths(songData);
    final offlineOrExplicitUrl = await _getPlaybackUrl(songData, isOffline);

    if (offlineOrExplicitUrl == null || offlineOrExplicitUrl.isEmpty) {
      if (!isOffline) {
        host.log('Failed to get song URL for ${songData['ytid']}');
        return null;
      }

      // If offline mode is enabled, do NOT fall back to online streams.
      // This prevents network requests while the user explicitly requested
      // offline-only operation.
      try {
        if (host.offlineMode.value) {
          host.log(
            'Offline mode enabled and offline file missing for ${songData['ytid']}. Not falling back to online.',
          );
          return null;
        }
      } catch (_) {
        // If offlineMode isn't available for some reason, continue with fallback.
      }

      host.log(
        'Offline file missing for ${songData['ytid']}, switching to online',
      );

      final streamInfo = await host.resolveStream(
        songData['ytid'],
        isLive: songData['isLive'] ?? false,
      );

      if (streamInfo == null || streamInfo.url.isEmpty) {
        host.log('Failed to get song URL for ${songData['ytid']}');
        return null;
      }

      songData['isVideo'] = streamInfo.isVideo;
      songData['videoSource'] = streamInfo.isVideo ? streamInfo.url : null;
      return _PlaybackSource(
        songUrl: streamInfo.url,
        isOffline: false,
        isVideo: streamInfo.isVideo,
        cacheKey: streamInfo.cacheKey,
      );
    }

    if (isOffline) {
      songData['isVideo'] = false;
      songData['videoSource'] = null;
      return _PlaybackSource(songUrl: offlineOrExplicitUrl, isOffline: true);
    }

    final isVideo = songData['isVideo'] == true;
    return _PlaybackSource(
      songUrl: offlineOrExplicitUrl,
      isOffline: false,
      isVideo: isVideo,
      cacheKey: StreamPlaybackInfo.cacheKeyFor(
        songData['ytid'].toString(),
        isVideo: isVideo,
      ),
    );
  }

  Future<String?> _getPlaybackUrl(Map song, bool isOffline) async {
    final isVideo = song['isVideo'] == true;
    final explicitVideoSource = song['videoSource']?.toString();
    if (isVideo &&
        explicitVideoSource != null &&
        explicitVideoSource.isNotEmpty) {
      return explicitVideoSource;
    }

    if (isOffline) {
      return _getOfflineSongUrl(song);
    }

    final streamInfo = await host.resolveStream(
      song['ytid'],
      isLive: song['isLive'] ?? false,
    );
    if (streamInfo == null) return null;

    song['isVideo'] = streamInfo.isVideo;
    song['videoSource'] = streamInfo.isVideo ? streamInfo.url : null;
    return streamInfo.url;
  }

  Future<String?> _getOfflineSongUrl(Map song) async {
    final audioPath = song['audioPath'];
    if (audioPath == null || audioPath.isEmpty) {
      host.log('Missing audioPath for offline song: ${song['ytid']}');
      return null;
    }

    final file = File(audioPath);
    if (await file.exists()) {
      return audioPath;
    }

    host.log('Offline audio file not found: $audioPath');

    final offlineSong = _offlineSongOf(song);

    if (offlineSong.isNotEmpty && offlineSong['audioPath'] != null) {
      final fallbackPath = offlineSong['audioPath'];
      final fallbackFile = File(fallbackPath);
      if (await fallbackFile.exists()) {
        song['audioPath'] = fallbackPath;
        return fallbackPath;
      }
    }

    return null;
  }

  Future<bool> _setAudioSourceAndPlay(
    Map song,
    MusifyAudioSource audioSource,
    String songUrl,
    bool isOffline, {
    String? mediaId,
    bool allowOnlineRetry = true,
    int? transitionId,
  }) async {
    try {
      // Final staleness check before we touch the audio player.
      // If another song was requested between the URL fetch and here, abort.
      if (_isStaleTransition(transitionId)) {
        return false;
      }

      // Player errors from here on belong to this source, not the previous one.
      _pendingPlayerError = null;
      await audioPlayer
          .setAudioSource(audioSource)
          .timeout(_songTransitionTimeout);

      // Check once more after the async setAudioSource: a fast offline song
      // could have loaded and started playing while we were buffering/setting up.
      // If so, stop the source we just loaded and yield to the newer song.
      if (_isStaleTransition(transitionId)) {
        unawaited(audioPlayer.stop());
        return false;
      }

      if (audioPlayer.duration != null) {
        var currentMediaItem = _mediaItemFor(song);
        if (mediaId != null) {
          currentMediaItem = currentMediaItem.copyWith(id: mediaId);
        }
        mediaItem.add(
          currentMediaItem.copyWith(
            duration: audioPlayer.duration,
            extras: {
              ...?mediaItem.valueOrNull?.extras,
              ...?currentMediaItem.extras,
            },
          ),
        );
      }

      await audioPlayer.play();

      if (!isOffline) {
        final cacheKey = StreamPlaybackInfo.cacheKeyFor(
          song['ytid'].toString(),
          isVideo: song['isVideo'] == true,
        );
        unawaited(host.cacheStreamUrl(cacheKey, songUrl));
      }

      _updatePlaybackState();

      Future.delayed(const Duration(seconds: 2), _preloadUpcomingSongs);

      return true;
    } catch (e, stackTrace) {
      host.log('Error setting audio source', error: e, stackTrace: stackTrace);

      if (isOffline) {
        // If offline mode is explicitly enabled, do not attempt any online
        // fallback — respect the user's offline-only preference.
        try {
          if (host.offlineMode.value) {
            return false;
          }
        } catch (_) {
          // If offlineMode isn't accessible, fallthrough to attempt fallback.
        }

        return _attemptOfflineFallback(
          song,
          mediaId: mediaId,
          transitionId: transitionId,
        );
      }

      if (allowOnlineRetry) {
        if (host.offlineMode.value) {
          _lastError = e.toString();
          return false;
        }
        final songId = song['ytid']?.toString();
        if (songId != null && songId.isNotEmpty) {
          await host.clearCachedStreams(songId);

          final refreshedInfo = await host.resolveStream(
            songId,
            isLive: song['isLive'] ?? false,
          );

          if (refreshedInfo != null && refreshedInfo.url.isNotEmpty) {
            song['isVideo'] = refreshedInfo.isVideo;
            song['videoSource'] = refreshedInfo.isVideo
                ? refreshedInfo.url
                : null;
            final refreshedSource = await buildAudioSource(
              song,
              refreshedInfo.url,
              false,
            );

            if (refreshedSource != null) {
              return _setAudioSourceAndPlay(
                song,
                refreshedSource,
                refreshedInfo.url,
                false,
                mediaId: mediaId,
                allowOnlineRetry: false,
                transitionId: transitionId,
              );
            }
          }
        }
      }

      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> _attemptOfflineFallback(
    Map song, {
    String? mediaId,
    int? transitionId,
  }) async {
    // Do not attempt any network calls when offline mode is enabled.
    if (host.offlineMode.value) return false;

    final onlineInfo = await host.resolveStream(
      song['ytid'],
      isLive: song['isLive'] ?? false,
    );
    if (onlineInfo != null && onlineInfo.url.isNotEmpty) {
      song['isVideo'] = onlineInfo.isVideo;
      song['videoSource'] = onlineInfo.isVideo ? onlineInfo.url : null;
      final onlineSource = await buildAudioSource(song, onlineInfo.url, false);
      if (onlineSource != null) {
        return _setAudioSourceAndPlay(
          song,
          onlineSource,
          onlineInfo.url,
          false,
          mediaId: mediaId,
          transitionId: transitionId,
        );
      }
    }
    return false;
  }

  Future<void> playNext(Map song) async {
    await addToQueue(song, playNext: true);
  }

  Future<void> playPlaylistSong({
    Map<dynamic, dynamic>? playlist,
    required int songIndex,
  }) async {
    try {
      if (playlist != null && playlist['list'] != null) {
        await addPlaylistToQueue(
          List<Map>.from(playlist['list']),
          replace: true,
          startIndex: songIndex,
        );
      }
    } catch (e, stackTrace) {
      host.log('Error playing playlist', error: e, stackTrace: stackTrace);
    }
  }

  Future<MusifyAudioSource?> buildAudioSource(
    Map song,
    String songUrl,
    bool isOffline,
  ) async {
    try {
      if (isOffline) {
        return MusifyAudioSource.file(songUrl);
      }

      final uri = Uri.parse(songUrl);
      return MusifyAudioSource.uri(uri);
    } catch (e, stackTrace) {
      host.log('Error building audio source', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // SponsorBlock clipping is temporarily disabled for media_kit migration.

  Future<void> skipToSong(int newIndex) async {
    try {
      if (newIndex < 0 || newIndex >= _queueList.length) {
        host.log('Invalid song index: $newIndex');
        return;
      }
      _bumpQueueInteractiveGeneration();
      await _playFromQueue(newIndex);
    } catch (e, stackTrace) {
      host.log('Error skipping to song', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) => skipToSong(index);

  @override
  Future<void> skipToNext() async {
    try {
      if (_currentQueueIndex < _queueList.length - 1) {
        await _playFromQueue(_currentQueueIndex + 1);
      } else if (host.repeatMode.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) {
        await _playFromQueue(0);
      } else if (host.playNextAutomatically.value &&
          _currentLoadingIndex == -1) {
        // At end of queue with auto-play enabled - trigger background fetch
        final genAtSchedule = _queueInteractiveGeneration;
        unawaited(_backgroundAddSongsToQueue(genAtSchedule));
      }

      _cleanupOldPreloadedSongs();
    } catch (e, stackTrace) {
      host.log('Error skipping to next song', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      if (_currentQueueIndex > 0) {
        await _playFromQueue(_currentQueueIndex - 1);
      } else if (_historyList.isNotEmpty) {
        final lastSong = cloneMap(_historyList.removeLast());
        _queueList.insert(0, lastSong);
        _currentQueueIndex = 0;
        _updateQueueMediaItems();
        await _playFromQueue(0);
      }

      _cleanupOldPreloadedSongs();
    } catch (e, stackTrace) {
      host.log(
        'Error skipping to previous song',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> playAgain() async {
    try {
      await audioPlayer.seek(Duration.zero);
      // Track the replay as a new listen
      if (currentSong != null) {
        await host.recordListen(currentSong!['ytid'].toString());
      }
    } catch (e, stackTrace) {
      host.log('Error playing again', error: e, stackTrace: stackTrace);
    }
  }

  Map<Map, String> _buildIdMap(List<Map> songs) {
    return {for (final song in songs) song: _queueEntryIds.ensureId(song)};
  }

  void _enableShuffle(
    List<Map> unplayedManualSongs,
    Set<String> manualSongIds,
  ) {
    _originalQueueList
      ..clear()
      ..addAll(cloneMaps(_queueList));

    final currentSong = _queueList[_currentQueueIndex];
    final currentQueueEntryId = _queueEntryIds.ensureId(currentSong);

    final queueIdMap = _buildIdMap(_queueList);
    _queueList
      ..removeWhere((song) => manualSongIds.contains(queueIdMap[song]))
      ..shuffle();

    final newCurrentIndex = _queueList.indexWhere(
      (song) => _queueEntryIds.ensureId(song) == currentQueueEntryId,
    );

    if (newCurrentIndex != -1 && newCurrentIndex != 0) {
      _queueList
        ..removeAt(newCurrentIndex)
        ..insert(0, currentSong);
    }

    _queueList.insertAll(_queueList.isNotEmpty ? 1 : 0, unplayedManualSongs);

    _currentQueueIndex = 0;
    _updateQueueMediaItems();
  }

  void _disableShuffle(
    List<Map> unplayedManualSongs,
    Set<String> manualSongIds,
  ) {
    if (_originalQueueList.isEmpty) return;

    final currentSong = _queueList[_currentQueueIndex];
    final currentQueueEntryId = _queueEntryIds.ensureId(currentSong);

    final restoredQueue = cloneMaps(_originalQueueList);
    final restoredQueueIdMap = _buildIdMap(restoredQueue);
    restoredQueue.removeWhere(
      (song) => manualSongIds.contains(restoredQueueIdMap[song]),
    );

    _queueList
      ..clear()
      ..addAll(restoredQueue);

    _currentQueueIndex = _queueList.indexWhere(
      (song) => _queueEntryIds.ensureId(song) == currentQueueEntryId,
    );

    if (_currentQueueIndex == -1) {
      _currentQueueIndex = 0;
    }

    final insertIndex = _currentQueueIndex + 1;
    _queueList.insertAll(insertIndex, unplayedManualSongs);

    _originalQueueList.clear();
    _updateQueueMediaItems();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    try {
      final shuffleEnabled = shuffleMode != AudioServiceShuffleMode.none;
      final wasShuffled = host.shuffleEnabled.value;

      host.shuffleEnabled.value = shuffleEnabled;
      host.savePlaybackSetting('shuffleEnabled', shuffleEnabled);
      await audioPlayer.setShuffleModeEnabled(shuffleEnabled);

      if (_queueList.isEmpty) return;

      if (shuffleEnabled && !wasShuffled) {
        _hydrateQueueEntryIds();
        final unplayedManualSongs = _getUnplayedManualSongs();
        final manualSongIds = unplayedManualSongs
            .map(_queueEntryIds.ensureId)
            .toSet();
        _enableShuffle(unplayedManualSongs, manualSongIds);
      } else if (!shuffleEnabled && wasShuffled) {
        _hydrateQueueEntryIds();
        final unplayedManualSongs = _getUnplayedManualSongs();
        final manualSongIds = unplayedManualSongs
            .map(_queueEntryIds.ensureId)
            .toSet();
        _disableShuffle(unplayedManualSongs, manualSongIds);
      }
    } catch (e, stackTrace) {
      host.log('Error setting shuffle mode', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    try {
      host.repeatMode.value = repeatMode;
      host.savePlaybackSetting('repeatMode', repeatMode.index);

      await audioPlayer.setLoopMode(MusifyLoopMode.off);
    } catch (e, stackTrace) {
      host.log('Error setting repeat mode', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> setSleepTimer(Duration duration) async {
    try {
      _sleepTimer?.cancel();
      sleepTimerExpired = false;
      host.sleepTimer.value = duration;

      _sleepTimer = Timer(duration, () async {
        sleepTimerExpired = true;
        await pause();
        host.sleepTimer.value = Duration.zero;
      });
    } catch (e, stackTrace) {
      host.log('Error setting sleep timer', error: e, stackTrace: stackTrace);
    }
  }

  void cancelSleepTimer() {
    try {
      _sleepTimer?.cancel();
      _sleepTimer = null;
      sleepTimerExpired = false;
      host.sleepTimer.value = Duration.zero;
    } catch (e, stackTrace) {
      host.log('Error canceling sleep timer', error: e, stackTrace: stackTrace);
    }
  }

  void changeAutoPlayNextStatus() {
    host.playNextAutomatically.value = !host.playNextAutomatically.value;
    host.savePlaybackSetting(
      'playNextSongAutomatically',
      host.playNextAutomatically.value,
    );
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    try {
      switch (name) {
        case 'clearQueue':
          clearQueue();
          break;
        case 'addToQueue':
          if (extras?['song'] != null) {
            await addToQueue(
              extras!['song'] as Map,
              playNext: extras['playNext'] ?? false,
            );
          }
          break;
        case 'removeFromQueue':
          if (extras?['index'] != null) {
            await removeFromQueue(extras!['index'] as int);
          }
          break;
        case 'reorderQueue':
          if (extras?['oldIndex'] != null && extras?['newIndex'] != null) {
            await reorderQueue(
              extras!['oldIndex'] as int,
              extras['newIndex'] as int,
            );
          }
          break;
        default:
          await super.customAction(name, extras);
      }
    } catch (e, stackTrace) {
      host.log(
        'Error in customAction: $name',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

class _PlaybackSource {
  const _PlaybackSource({
    required this.songUrl,
    required this.isOffline,
    this.isVideo = false,
    this.cacheKey,
  });

  final String songUrl;
  final bool isOffline;
  final bool isVideo;
  final String? cacheKey;
}

class MusifyEqualizerParameters {
  const MusifyEqualizerParameters({
    this.minDecibels = -12,
    this.maxDecibels = 12,
    this.bands = const [],
  });

  final double minDecibels;
  final double maxDecibels;
  final List<MusifyEqualizerBand> bands;
}

class MusifyEqualizerBand {
  const MusifyEqualizerBand({
    required this.centerFrequency,
    required this.gain,
  });

  final double centerFrequency;
  final double gain;
}
