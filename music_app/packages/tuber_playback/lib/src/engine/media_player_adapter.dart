// ignore_for_file: cascade_invocations

import 'dart:async';
import 'dart:io';

import 'package:media_kit/media_kit.dart';
import 'package:rxdart/rxdart.dart';

enum MusifyProcessingState { idle, loading, buffering, ready, completed }

enum MusifyLoopMode { off }

class MusifyPlayerState {
  const MusifyPlayerState({
    required this.processingState,
    required this.playing,
  });

  final MusifyProcessingState processingState;
  final bool playing;
}

class MusifyAudioSource {
  const MusifyAudioSource._({required this.uri, this.tag, this.isFile = false});

  factory MusifyAudioSource.uri(Uri uri, {dynamic tag}) =>
      MusifyAudioSource._(uri: uri.toString(), tag: tag);

  factory MusifyAudioSource.file(String path, {dynamic tag}) =>
      MusifyAudioSource._(uri: path, tag: tag, isFile: true);

  final String uri;
  final dynamic tag;
  final bool isFile;
}

class MediaPlayerAdapter {
  /// [player] defaults to a native media_kit [Player]; tests pass one built
  /// with `Player(platformPlayer: ...)`.
  MediaPlayerAdapter({Player? player}) : _player = player ?? Player() {
    _subs.add(_player.stream.position.listen(_positionCtrl.add));
    _subs.add(_player.stream.buffer.listen(_bufferCtrl.add));
    _subs.add(
      _player.stream.duration.listen((duration) {
        _durationCtrl.add(duration == Duration.zero ? null : duration);
      }),
    );
    _subs.add(
      Rx.combineLatest3<bool, bool, bool, MusifyProcessingState>(
        _player.stream.playing,
        _player.stream.buffering,
        _player.stream.completed,
        (playing, buffering, completed) {
          if (_source == null) return MusifyProcessingState.idle;
          if (completed) return MusifyProcessingState.completed;
          if (buffering) return MusifyProcessingState.buffering;
          if (playing || _player.state.duration > Duration.zero) {
            return MusifyProcessingState.ready;
          }
          return MusifyProcessingState.loading;
        },
      ).listen(_processingCtrl.add),
    );
    _subs.add(
      Rx.combineLatest2<MusifyProcessingState, bool, MusifyPlayerState>(
        _processingCtrl.stream,
        _player.stream.playing,
        (processing, playing) =>
            MusifyPlayerState(processingState: processing, playing: playing),
      ).listen(_playerStateCtrl.add),
    );
    _subs.add(
      Rx.combineLatest4<Duration, Duration, Duration?, bool, void>(
        _positionCtrl.stream,
        _bufferCtrl.stream,
        _durationCtrl.stream,
        _player.stream.playing,
        (_, __, ___, ____) {},
      ).listen(_eventCtrl.add),
    );
  }

  final Player _player;
  final List<StreamSubscription<dynamic>> _subs = [];
  MusifyAudioSource? _source;

  final _positionCtrl = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _bufferCtrl = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _durationCtrl = BehaviorSubject<Duration?>.seeded(null);
  final _processingCtrl = BehaviorSubject<MusifyProcessingState>.seeded(
    MusifyProcessingState.idle,
  );
  final _playerStateCtrl = BehaviorSubject<MusifyPlayerState>.seeded(
    const MusifyPlayerState(
      processingState: MusifyProcessingState.idle,
      playing: false,
    ),
  );
  final _eventCtrl = StreamController<void>.broadcast();

  Stream<Duration> get positionStream => _positionCtrl.stream;
  Stream<Duration> get bufferedPositionStream => _bufferCtrl.stream;
  Stream<Duration?> get durationStream => _durationCtrl.stream;
  Stream<MusifyProcessingState> get processingStateStream =>
      _processingCtrl.stream;
  Stream<MusifyPlayerState> get playerStateStream => _playerStateCtrl.stream;

  /// Errors reported by the native player while opening or streaming a
  /// source (network failures, HTTP errors from the stream URL, decoding).
  Stream<String> get errorStream => _player.stream.error;
  Stream<void> get playbackEventStream => _eventCtrl.stream;

  Duration get position => _positionCtrl.value;
  Duration get bufferedPosition => _bufferCtrl.value;
  Duration? get duration => _durationCtrl.valueOrNull;
  bool get playing => _player.state.playing;
  double get speed => _player.state.rate;
  MusifyProcessingState get processingState => _processingCtrl.value;
  MusifyAudioSource? get audioSource => _source;

  Future<void> setAudioSource(MusifyAudioSource source) async {
    _source = source;
    _processingCtrl.add(MusifyProcessingState.loading);
    final uri = source.isFile ? File(source.uri).uri.toString() : source.uri;
    await _player.open(Media(uri), play: false);
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();

  /// Stopping unloads the source, so the processing state is idle rather than
  /// "loading" (a loaded source with no duration).
  Future<void> stop() {
    _source = null;
    _processingCtrl.add(MusifyProcessingState.idle);
    return _player.stop();
  }

  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> setShuffleModeEnabled(bool enabled) =>
      _player.setShuffle(enabled);
  Future<void> setLoopMode(MusifyLoopMode mode) async {}
  Future<void> setRate(double rate) => _player.setRate(rate);
  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _eventCtrl.close();
    await _positionCtrl.close();
    await _bufferCtrl.close();
    await _durationCtrl.close();
    await _processingCtrl.close();
    await _playerStateCtrl.close();
    await _player.dispose();
  }

  Player get nativePlayer => _player;
}
