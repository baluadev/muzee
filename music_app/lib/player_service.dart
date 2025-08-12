import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:muzee/services/database/db_service.dart';
import 'package:video_player/video_player.dart';

import 'models/song_model.dart';
import 'services/ytb/ytb_service.dart';

const deviceid = 'userId';

enum VideoProcessingState {
  idle,
  loading,
  buffering,
  ready,
  completed,
  error,
}

class PlayerService extends BaseAudioHandler with QueueHandler, SeekHandler {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final List<SongModel> _queue = [];
  final StreamController<({Duration position, Duration duration})>
      _progressController = StreamController.broadcast();
  final StreamController<({SongModel song, int position, int duration})>
      _finishStreamController = StreamController.broadcast();
  final StreamController<List<SongModel>> _queueStreamController =
      StreamController.broadcast();

  int _currentIndex = 0;
  bool _isShuffle = false;
  bool _enableSuggests = false;
  bool _isFetchingSuggested = false;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  VideoPlayerController? _player;
  Completer<void>? _completer;
  bool _isListenerAttached = false;

  final ValueNotifier<VideoPlayerController?> videoControllerStream =
      ValueNotifier(null);

  final LinkedHashMap<String, VideoPlayerController> _controllerCache =
      LinkedHashMap();
  final Set<String> _prefetchFailed = {};
  static const int MAX_CACHE_SIZE = 3;

  Stream<({Duration position, Duration duration})> get progressStream =>
      _progressController.stream;

  Stream<({SongModel song, int position, int duration})> get finishStream =>
      _finishStreamController.stream;

  Stream<List<SongModel>> get queueStream => _queueStreamController.stream;
  AudioServiceRepeatMode get repeatMode => _repeatMode;
  List<SongModel> get currentQueue => List.unmodifiable(_queue);
  SongModel? get currentSong =>
      _queue.isNotEmpty ? _queue[_currentIndex] : null;
  bool get isPlaying => _player?.value.isPlaying ?? false;
  bool get isInitialized => _player?.value.isInitialized ?? false;
  bool get isShuffle => _isShuffle;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
  }

  Future<void> setQueue(List<SongModel> items) async {
    if (items.isEmpty) return;

    _queue
      ..clear()
      ..addAll(items);
    queue.add(items.map((e) => e.toMediaItem()).toList());
    _queueStreamController.add(currentQueue);
    _currentIndex = 0;

    _enableSuggests = items.length == 1;
    if (_enableSuggests) {
      await addSuggestedVideos();
    }

    playSong(_queue.first);
  }

  Future<void> insertToQueue(List<SongModel> items, [int? index]) async {
    if (items.isEmpty) return;

    if (index != null && index >= 0 && index <= _queue.length) {
      _queue.insertAll(index, items);
      if (index <= _currentIndex) {
        _currentIndex += items.length;
      }
    } else {
      _queue.addAll(items);
    }

    queue.add(_queue.map((e) => e.toMediaItem()).toList());

    if (_queue.length == items.length) {
      _currentIndex = 0;
      await _playSong(_queue.first);
    }

    _queueStreamController.add(currentQueue);
  }

  Future<void> changeQueuePosition(int oldIndex, int newIndex) async {
    if (oldIndex >= 0 &&
        oldIndex < _queue.length &&
        newIndex >= 0 &&
        newIndex < _queue.length) {
      final item = _queue.removeAt(oldIndex);
      _queue.insert(newIndex, item);
      if (_currentIndex == oldIndex) {
        _currentIndex = newIndex;
      } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
        _currentIndex -= 1;
      } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
        _currentIndex += 1;
      }
      queue.add(_queue.map((e) => e.toMediaItem()).toList());
      _queueStreamController.add(currentQueue);
    }
  }

  Future<void> addSuggestedVideos({int max = 5}) async {
    if (_isFetchingSuggested) return;
    _isFetchingSuggested = true;

    final current = currentSong;
    if (current != null) {
      final related = await DBService.inst.getRelatedVideosWithCache(
        videoId: current.songId,
        userId: deviceid,
      );

      if (related.isNotEmpty) {
        final toInsert = related.take(max).toList();
        final insertIndex = _currentIndex + 1;
        await insertToQueue(toInsert, insertIndex);
      }
    }

    _isFetchingSuggested = false;
  }

  Future<void> playSong(SongModel song) async {
    final index = _queue.indexWhere((item) => item.songId == song.songId);
    if (index != -1) {
      _currentIndex = index;
      await _playSong(_queue[_currentIndex]);
    }
  }

  Future<void> _prefetchController(SongModel song) async {
    if (_controllerCache.containsKey(song.songId)) return;
    if (_prefetchFailed.contains(song.songId)) return;

    try {
      final url = await _getUrlFromId(song.songId);
      if (url == null) throw Exception("Null URL");

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
      );
      await controller.initialize();

      _controllerCache[song.songId] = controller;
      while (_controllerCache.length > MAX_CACHE_SIZE) {
        final oldestKey = _controllerCache.keys.first;
        _controllerCache.remove(oldestKey)?.dispose();
      }
    } catch (e) {
      debugPrint('Prefetch failed for ${song.songId}: $e');
      _prefetchFailed.add(song.songId);
    }
  }

  Future<void> _playSong(SongModel song) async {
    if (_completer != null) {
      await _completer!.future;
    }
    _completer = Completer<void>();
    mediaItem.add(song.toMediaItem());
    videoControllerStream.value = null;

    try {
      await _player?.pause();
      await _player?.dispose();
      _isListenerAttached = false;

      VideoPlayerController controller;
      if (_controllerCache.containsKey(song.songId)) {
        controller = _controllerCache.remove(song.songId)!;
        _controllerCache[song.songId] = controller;
      } else {
        final url = await _getUrlFromId(song.songId);
        if (url == null) throw Exception('Không lấy được URL');

        controller = VideoPlayerController.networkUrl(
          Uri.parse(url),
          videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
        );
        await controller.initialize();
      }

      _player = controller;
      videoControllerStream.value = controller;
      mediaItem.add(
          song.toMediaItem().copyWith(duration: controller.value.duration));
      await controller.play();
      _attachListener(song);

      final nextSongs = _getNextSongs(count: 2);
      for (final s in nextSongs) {
        _prefetchController(s);
      }
    } catch (e) {
      debugPrint('Lỗi khi phát bài: $e');
      skipToNext();
    } finally {
      _completer?.complete();
      _completer = null;
    }
  }

  List<SongModel> _getNextSongs({int count = 2}) {
    if (_queue.isEmpty) return [];
    final List<SongModel> result = [];
    final seen = <String>{};

    if (_isShuffle) {
      final remaining = List<SongModel>.from(_queue)..removeAt(_currentIndex);
      remaining.shuffle();
      for (final song in remaining) {
        if (seen.length >= count) break;
        if (!seen.contains(song.songId)) {
          result.add(song);
          seen.add(song.songId);
        }
      }
    } else {
      for (int i = _currentIndex + 1;
          i < _queue.length && result.length < count;
          i++) {
        result.add(_queue[i]);
      }
    }
    return result;
  }

  void _attachListener(SongModel song) {
    if (_isListenerAttached) return;
    _isListenerAttached = true;
    _player?.addListener(() async {
      final position = _player?.value.position ?? Duration.zero;
      final duration = _player?.value.duration ?? Duration.zero;
      _progressController.add((position: position, duration: duration));
      playbackState.add(_transformEvent(_player!.value));
      if (position >= duration && duration != Duration.zero) {
        _finishStreamController.add((
          song: song,
          position: position.inSeconds,
          duration: duration.inSeconds
        ));
        switch (_repeatMode) {
          case AudioServiceRepeatMode.none:
          case AudioServiceRepeatMode.all:
            skipToNext();
            break;
          case AudioServiceRepeatMode.one:
            _playSong(song);
            break;
          case AudioServiceRepeatMode.group:
            break;
        }
      }
    });
  }

  PlaybackState _transformEvent(VideoPlayerValue value) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (value.isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        VideoProcessingState.idle: AudioProcessingState.idle,
        VideoProcessingState.loading: AudioProcessingState.loading,
        VideoProcessingState.buffering: AudioProcessingState.buffering,
        VideoProcessingState.ready: AudioProcessingState.ready,
        VideoProcessingState.completed: AudioProcessingState.completed,
      }[convertVideoState(value)]!,
      playing: value.isPlaying,
      updatePosition: value.position,
      bufferedPosition:
          value.buffered.isNotEmpty ? value.buffered.first.end : Duration.zero,
      speed: value.playbackSpeed,
      repeatMode: value.isLooping
          ? AudioServiceRepeatMode.one
          : AudioServiceRepeatMode.none,
      queueIndex: 0,
    );
  }

  VideoProcessingState convertVideoState(VideoPlayerValue value) {
    if (value.isInitialized) return VideoProcessingState.ready;
    if (value.isBuffering) return VideoProcessingState.buffering;
    if (value.position == value.duration) return VideoProcessingState.completed;
    if (!value.isInitialized) return VideoProcessingState.loading;
    return VideoProcessingState.idle;
  }

  @override
  Future<void> play() async {
    await _player?.play();
    playbackState.add(playbackState.value
        .copyWith(playing: true, processingState: AudioProcessingState.ready));
  }

  @override
  Future<void> pause() async {
    await _player?.pause();
    playbackState.add(playbackState.value
        .copyWith(playing: false, processingState: AudioProcessingState.ready));
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;

    if (_isShuffle) {
      final indices = List.generate(_queue.length, (i) => i)..shuffle();
      _currentIndex = indices.first;
    } else {
      _currentIndex++;
    }

    if (_currentIndex >= _queue.length) {
      await addSuggestedVideos();
      if (_currentIndex >= _queue.length) return;
    }

    await _playSong(_queue[_currentIndex]);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    _currentIndex =
        (_currentIndex - 1) < 0 ? _queue.length - 1 : _currentIndex - 1;
    await _playSong(_queue[_currentIndex]);
  }

  @override
  Future<void> skipToQueueItem(int indexx) async {
    final index = _queue.indexWhere((item) => item.id == indexx);
    if (index != -1) {
      _currentIndex = index;
      await _playSong(_queue[_currentIndex]);
    }
  }

  @override
  Future<void> stop() => exit(0);

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
  }

  void toggleRepeatMode() {
    if (_repeatMode == AudioServiceRepeatMode.one) {
      _repeatMode = AudioServiceRepeatMode.none;
    } else {
      _repeatMode = AudioServiceRepeatMode.one;
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player?.seekTo(position);
  }

  Future<String?> _getUrlFromId(String id) async {
    return await YtbService.getUrl(id);
  }

  void dispose() {
    _player?.dispose();
    for (final controller in _controllerCache.values) {
      controller.dispose();
    }
    _controllerCache.clear();
    _progressController.close();
  }
}
