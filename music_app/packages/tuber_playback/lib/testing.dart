/// Test support: run a [TuberAudioHandler] without libmpv.
///
/// ```dart
/// final engine = SilentPlatformPlayer();
/// final handler = TuberAudioHandler(
///   host: fakeHost,
///   player: engine.adapter(),
/// );
/// engine.start();
/// ```
library;

// The engine drives media_kit's own stream controllers, like the native
// backend does.
// ignore_for_file: invalid_use_of_protected_member

import 'package:media_kit/media_kit.dart';
import 'package:tuber_playback/tuber_playback.dart';

/// A media_kit backend that plays nothing. It reports what a real player
/// would (opened, playing, paused, finished, errors) when told to, so tests
/// can drive the handler through every state.
class SilentPlatformPlayer extends PlatformPlayer {
  SilentPlatformPlayer() : super(configuration: const PlayerConfiguration());

  /// URIs the handler opened, in order.
  final List<String> opened = [];

  /// A [MediaPlayerAdapter] over this backend, to pass as the handler's
  /// `player`.
  MediaPlayerAdapter adapter() =>
      MediaPlayerAdapter(player: Player(platformPlayer: this));

  /// Sends the first playing/buffering/completed values. MediaPlayerAdapter
  /// combines the three, so it reports no processing state until each has
  /// one. Call once the adapter is subscribed (after building the handler).
  void start() {
    playingController.add(false);
    bufferingController.add(false);
    completedController.add(false);
  }

  /// Sends an error the way media_kit reports one (from mpv's error log).
  void reportError(String message) => errorController.add(message);

  /// The current track reached its end: media_kit reports `completed`, then
  /// `playing: false` (let the handler react in between).
  void completeTrack() {
    state = state.copyWith(completed: true, playing: false);
    completedController.add(true);
  }

  /// Sends a `playing` change without touching [state].
  void emitPlaying(bool playing) => playingController.add(playing);

  /// Says it is playing without ever emitting it: a loaded stream that never
  /// starts, like a resolved URL after the network dropped.
  void stall() => state = state.copyWith(playing: true);

  @override
  Future<void> open(Playable playable, {bool play = true}) async {
    if (playable is Media) opened.add(playable.uri);
    state = state.copyWith(completed: false, playing: false);
    completedController.add(false);
  }

  @override
  Future<void> play() async {
    state = state.copyWith(playing: true);
    playingController.add(true);
  }

  @override
  Future<void> pause() async {
    state = state.copyWith(playing: false);
    playingController.add(false);
  }

  @override
  Future<void> stop() async {
    state = state.copyWith(playing: false, completed: false);
    playingController.add(false);
  }

  @override
  Future<void> seek(Duration duration) async {}

  @override
  Future<void> setShuffle(bool shuffle) async {}

  @override
  Future<void> setRate(double rate) async {}
}
