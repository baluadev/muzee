// Test harness for MusifyAudioHandler.
//
// The handler gets a MediaPlayerAdapter over tuber_playback's
// [SilentPlatformPlayer], a no-op media_kit backend the harness drives to
// simulate "track loaded", "track finished" and player errors. No libmpv is
// needed.
//
// `playSong` is overridden to record what the handler asked to play. Songs in
// [TestAudioHandler.unplayable] or [TestAudioHandler.realLookup] go through
// the real `MusifyAudioHandler.playSong` (stream lookup via the fake network).

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:muzee/services/audio_service.dart';
import 'package:tuber_playback/testing.dart';
import 'package:tuber_playback/tuber_playback.dart';

/// Boxes that main.dart opens at startup; many top-level globals read them on
/// first use.
const _hiveBoxes = [
  'settings',
  'user',
  'userNoBackup',
  'cache',
  'monetization',
];

/// Initializes the test binding and an isolated Hive store in a temp dir.
Future<Directory> setUpTestStorage() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = await Directory.systemTemp.createTemp('muzee_test_');
  Hive.init(dir.path);
  for (final name in _hiveBoxes) {
    await Hive.openBox(name);
  }
  return dir;
}

Future<void> tearDownTestStorage(Directory dir) async {
  try {
    // Writes the app started on a testWidgets fake clock never finish, and
    // Hive.close() would wait for them forever.
    await Hive.close().timeout(const Duration(seconds: 2));
  } catch (_) {}
  try {
    await dir.delete(recursive: true);
  } catch (_) {}
}

/// ytid of the [index]th song from [buildSongs]. Real YouTube ids are 11
/// characters; youtube_explode rejects anything else before any request.
String songId(int index) => 'song_${index.toString().padLeft(6, '0')}';

/// Builds a playlist of [count] songs with ytids `song_000000`, ...
List<Map<String, dynamic>> buildSongs(int count) => [
  for (var i = 0; i < count; i++)
    {
      'ytid': songId(i),
      'title': 'Song $i',
      'artist': 'Artist $i',
      'image': 'https://img.test/$i.jpg',
      'lowResImage': 'https://img.test/$i-low.jpg',
      'highResImage': 'https://img.test/$i-high.jpg',
      'isLive': false,
    },
];

/// Lets microtasks and zero-delay timers (stream deliveries, the handler's
/// `Future.microtask` chains) run to completion.
Future<void> settle() => pumpEventQueue(times: 50);

class TestAudioHandler extends MusifyAudioHandler {
  TestAudioHandler._(this._engine, this.unexpectedErrors)
    : super(player: _engine.adapter());

  /// Errors that reached the zone the handler was built in (its stream
  /// listeners and the work they schedule). Tests should expect this to stay
  /// empty.
  final List<Object> unexpectedErrors;

  /// ytids whose stream can't be resolved. These are passed to the real
  /// [MusifyAudioHandler.playSong], so the app's own lookup/failure path runs.
  final Set<String> unplayable = {};

  /// ytids that go through the real [MusifyAudioHandler.playSong] and are
  /// expected to resolve (the fake network answers OK), e.g. to exercise
  /// what the real load schedules afterwards.
  final Set<String> realLookup = {};

  /// ytids whose source loads but never starts streaming, like a resolved
  /// stream URL after the network dropped. The player reports nothing on its
  /// own; call [reportPlayerError] to send media_kit's error.
  final Set<String> stalls = {};

  /// Stalling ytids whose player error arrives while playSong is still
  /// running (before the handler's load has finished).
  final Set<String> errorsWhileLoading = {};

  /// Every song the handler asked to play, in order, including failures.
  final List<String> attempts = [];

  /// Songs that actually started playing, in order.
  final List<String> played = [];

  /// Positions passed to [seek], in order.
  final List<Duration> seeks = [];

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    await super.seek(position);
  }

  /// Reports a loaded track of [length], playing at [position], the way
  /// media_kit would.
  void reportTrack(Duration length, {Duration position = Duration.zero}) {
    _engine
      ..durationController.add(length)
      ..positionController.add(position);
  }

  final SilentPlatformPlayer _engine;
  bool _retired = false;

  /// Makes this handler inert once its test is over: stops it, which cancels
  /// a pending retry (it would otherwise fire during a later test and preload
  /// that test's song ids), and answers any late playSong without touching
  /// the network or the shared stream cache.
  void retire() {
    _retired = true;
    unawaited(stop());
  }

  static TestAudioHandler create() {
    late TestAudioHandler handler;
    final zoneErrors = <Object>[];
    runZonedGuarded(() {
      handler = TestAudioHandler._(SilentPlatformPlayer(), zoneErrors);
    }, (error, _) => zoneErrors.add(error));
    handler._engine.start();
    return handler;
  }

  /// Sends an error the way media_kit reports one (from mpv's error log).
  void reportPlayerError([
    String message =
        "tcp: Failed to resolve hostname rr1---sn-test.googlevideo.com",
  ]) => _engine.reportError(message);

  /// Simulates the current track reaching its end, as media_kit reports it.
  Future<void> finishCurrentTrack() async {
    _engine.completeTrack();
    await settle();
    _engine.emitPlaying(false);
    await settle();
  }

  @override
  Future<bool> playSong(Map song, {String? mediaId, int? transitionId}) async {
    if (_retired) return true;
    final ytid = song['ytid'].toString();
    attempts.add(ytid);
    if (unplayable.contains(ytid) || realLookup.contains(ytid)) {
      final ok = await super.playSong(
        song,
        mediaId: mediaId,
        transitionId: transitionId,
      );
      if (ok) played.add(ytid);
      return ok;
    }
    await audioPlayer.setAudioSource(
      MusifyAudioSource.uri(Uri.parse('https://media.test/$ytid')),
    );
    if (stalls.contains(ytid)) {
      // The real load calls play(); media_kit's state then says `playing`
      // even though the stream never starts (no playing event is emitted).
      _engine.stall();
      if (errorsWhileLoading.contains(ytid)) {
        reportPlayerError();
        await settle();
      }
      return true;
    }
    await audioPlayer.play();
    played.add(ytid);
    return true;
  }
}
