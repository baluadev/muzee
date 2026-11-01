// TuberAudioHandler on its own: a fake host and the silent media_kit backend
// from package:tuber_playback/testing.dart. Every song goes through the real
// playSong (host stream lookup, open, play).

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:tuber_playback/testing.dart';
import 'package:tuber_playback/tuber_playback.dart';

import 'helpers/fake_playback_host.dart';

String songId(int index) => 'song_${index.toString().padLeft(6, '0')}';

List<Map<String, dynamic>> buildSongs(int count) => [
  for (var i = 0; i < count; i++)
    {
      'ytid': songId(i),
      'title': 'Song $i',
      'artist': 'Artist $i',
      'highResImage': 'https://img.test/$i.jpg',
      'lowResImage': 'https://img.test/$i-low.jpg',
      'isLive': false,
    },
];

/// Lets stream deliveries and the handler's microtask chains finish.
Future<void> settle() => pumpEventQueue(times: 50);

/// Longer than the handler's wait before moving past a failed song (2 s).
const retryWindow = Duration(milliseconds: 2600);

/// Opens fine but never starts the URIs in [stalling], like a resolved stream
/// after the network dropped.
class _StallingPlayer extends SilentPlatformPlayer {
  final stalling = <String>{};

  @override
  Future<void> play() async {
    if (opened.isNotEmpty && stalling.contains(opened.last)) return stall();
    return super.play();
  }
}

/// Fails to open the first [failures] sources, like a cached URL that expired.
class _FlakyOpenPlayer extends SilentPlatformPlayer {
  int failures = 1;

  @override
  Future<void> open(Playable playable, {bool play = true}) async {
    if (failures-- > 0) throw Exception('HTTP 403');
    return super.open(playable, play: play);
  }
}

/// Takes a moment to stop, like the native player: the idle state arrives
/// before stop() returns.
class _SlowStopPlayer extends SilentPlatformPlayer {
  @override
  Future<void> stop() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return super.stop();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePlaybackHost host;
  late SilentPlatformPlayer engine;
  late TuberAudioHandler handler;

  /// Songs whose stream was opened, in order.
  List<String> played() => [
    for (final uri in engine.opened) uri.split('/').last,
  ];

  List<String> queueIds() => [
    for (final s in handler.currentQueue) s['ytid'] as String,
  ];

  void useEngine(SilentPlatformPlayer backend) {
    engine = backend;
    handler = TuberAudioHandler(host: host, player: engine.adapter());
    engine.start();
  }

  Future<void> start(List<Map> songs, {int startIndex = 0}) async {
    await handler.addPlaylistToQueue(
      songs,
      replace: true,
      startIndex: startIndex,
    );
    await settle();
  }

  Future<void> finishTrack() async {
    engine.completeTrack();
    await settle();
    engine.emitPlaying(false);
    await settle();
  }

  setUp(() {
    // Offline mode turns off background preloading and autoplay lookups, so
    // the host only sees the lookups each test makes. Queue songs still
    // resolve through the host.
    host = FakePlaybackHost()..offlineMode.value = true;
    useEngine(SilentPlatformPlayer());
  });

  tearDown(() => handler.stop());

  group('queue, shuffle and repeat (PLAY-003)', () {
    final songs = buildSongs(20);
    final allIds = [for (final s in songs) s['ytid'] as String];

    test(
      'shuffle keeps all 20 songs once, current first, and saves the setting',
      () async {
        await start(songs);

        await handler.setShuffleMode(AudioServiceShuffleMode.all);

        expect(queueIds(), hasLength(20));
        expect(queueIds().toSet(), allIds.toSet());
        expect(queueIds().first, songId(0));
        expect(queueIds(), isNot(allIds), reason: '1 in 19! chance by luck');
        expect(host.shuffleEnabled.value, isTrue);
        expect(host.savedSettings['shuffleEnabled'], isTrue);
      },
    );

    test(
      'turning shuffle off restores the order and keeps the current song',
      () async {
        await start(songs);
        await handler.setShuffleMode(AudioServiceShuffleMode.all);
        for (var i = 0; i < 5; i++) {
          await finishTrack();
        }
        final current = handler.currentSong!['ytid'] as String;

        await handler.setShuffleMode(AudioServiceShuffleMode.none);

        expect(queueIds(), allIds);
        expect(handler.currentSong?['ytid'], current);
      },
    );

    test(
      'shuffle then repeat all plays each song once per pass, then wraps',
      () async {
        await start(songs);
        await handler.setShuffleMode(AudioServiceShuffleMode.all);
        await handler.setRepeatMode(AudioServiceRepeatMode.all);
        final shuffledOrder = queueIds();

        for (var i = 0; i < 19; i++) {
          await finishTrack();
        }
        expect(played(), shuffledOrder);

        await finishTrack();

        expect(handler.currentQueueIndex, 0);
        expect(played(), [...shuffledOrder, shuffledOrder.first]);
        expect(
          host.savedSettings['repeatMode'],
          AudioServiceRepeatMode.all.index,
        );
      },
    );

    test('repeat one replays the current song', () async {
      await start(songs);
      await handler.setRepeatMode(AudioServiceRepeatMode.one);

      await finishTrack();
      await finishTrack();

      expect(played(), List.filled(3, songId(0)));
      expect(handler.currentQueueIndex, 0);
    });
  });

  group('songs that cannot be played (PLAY-004)', () {
    final songs = buildSongs(5);

    test(
      'a song without a stream is reported and the next one plays',
      () async {
        host.unplayable.add(songId(1));
        final reported = <String>[];
        handler.playbackErrors.listen((s) => reported.add(s['ytid'] as String));

        await start(songs, startIndex: 1);
        expect(reported, [songId(1)]);
        expect(played(), isEmpty);

        await Future<void>.delayed(retryWindow);

        expect(played(), [songId(2)]);
        expect(host.lookups.where((id) => id == songId(1)), hasLength(1));
      },
    );

    test('three in a row stop playback instead of retrying forever', () async {
      host.unplayable.addAll([songId(1), songId(2), songId(3)]);

      await start(songs, startIndex: 1);
      await Future<void>.delayed(retryWindow * 3);

      expect(host.lookups, [songId(1), songId(2), songId(3)]);
      expect(played(), isEmpty);
      final state = handler.playbackState.value;
      expect(state.processingState, AudioProcessingState.idle);
      expect(state.playing, isFalse);
    });

    test('the third failure after a song played stops playback once', () async {
      useEngine(_SlowStopPlayer());
      host.unplayable.addAll([songId(1), songId(2), songId(3)]);
      await start(songs);
      await finishTrack(); // song 0 ends -> three songs without a stream

      await Future<void>.delayed(retryWindow * 3);

      expect(played(), [songId(0)]);
      expect(host.lookups, [songId(0), songId(1), songId(2), songId(3)]);
      // Stopping must not count as a fourth failure.
      final stops = host.logs.where((l) => l.startsWith('Max consecutive'));
      expect(stops, hasLength(1));
      expect(
        host.logs.where((l) => l.contains('Consecutive errors: 4')),
        isEmpty,
      );
    });

    test('pressing play after a failure tries that song again', () async {
      host.unplayable.add(songId(0));
      await start([songs[0]]);
      expect(played(), isEmpty);

      host.unplayable.clear(); // e.g. the network is back
      await handler.play();
      await settle();

      expect(host.lookups, [songId(0), songId(0)]);
      expect(played(), [songId(0)]);
    });

    test('a stream that never starts is reported and skipped', () async {
      final stalling = _StallingPlayer()..stalling.add(streamUrlFor(songId(0)));
      useEngine(stalling);
      final reported = <String>[];
      handler.playbackErrors.listen((s) => reported.add(s['ytid'] as String));

      await start(songs);
      engine.reportError('tcp: Failed to resolve hostname');
      await settle();
      expect(reported, [songId(0)]);

      await Future<void>.delayed(retryWindow);

      expect(played(), [songId(0), songId(1)]);
    });
  });

  group('host', () {
    test(
      'a downloaded song plays from its file without a stream lookup',
      () async {
        final dir = await Directory.systemTemp.createTemp('tuber_playback_');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/song.m4a')..writeAsBytesSync([0]);
        host.downloads[songId(0)] = {'ytid': songId(0), 'audioPath': file.path};

        await start(buildSongs(1));

        expect(host.lookups, isEmpty);
        expect(handler.audioPlayer.audioSource?.isFile, isTrue);
        expect(engine.opened.single, endsWith('song.m4a'));
      },
    );

    test('the URL that played is handed to the host to cache', () async {
      await start(buildSongs(1));

      final key = StreamPlaybackInfo.cacheKeyFor(songId(0), isVideo: false);
      expect(host.cachedUrls, {key: streamUrlFor(songId(0))});
    });

    test(
      'a stream that fails to open is looked up again after clearing the cache',
      () async {
        host.offlineMode.value = false;
        useEngine(_FlakyOpenPlayer());

        await start(buildSongs(1));

        expect(host.clearedCaches, [songId(0)]);
        expect(host.lookups, [songId(0), songId(0)]);
        expect(played(), [songId(0)]);
      },
    );

    test(
      "autoplay queues the host's similar song after the current one",
      () async {
        host
          ..offlineMode.value = false
          ..playNextAutomatically.value = true
          ..similar = buildSongs(8).last;

        await start(buildSongs(1));

        expect(queueIds(), [songId(0), songId(7)]);
      },
    );

    test('a song that runs to the end is reported as completed', () async {
      await start(buildSongs(2));

      await finishTrack();

      expect(host.playEnds, [(songId(0), true)]);
    });

    test('skipping or stopping reports the song as not completed', () async {
      await start(buildSongs(3));

      await handler.skipToNext();
      await settle();
      await handler.stop();

      expect(host.playEnds, [(songId(0), false), (songId(1), false)]);
    });

    test('autoplay leaves a queue with songs still to come alone', () async {
      host
        ..offlineMode.value = false
        ..playNextAutomatically.value = true
        ..similar = buildSongs(8).last;

      await start(buildSongs(3));

      expect(queueIds(), [songId(0), songId(1), songId(2)]);
    });

    test(
      '"stop after this song" pauses at its end instead of moving on',
      () async {
        await start(buildSongs(3));
        handler.setSleepAtEndOfTrack();

        await finishTrack();

        expect(played(), [songId(0)]);
        expect(handler.sleepAtEndOfTrack.value, isFalse);
        expect(host.playEnds, [(songId(0), true)]);
      },
    );

    test('a timed sleep timer cancels "stop after this song"', () async {
      await start(buildSongs(2));
      handler.setSleepAtEndOfTrack();
      await handler.setSleepTimer(const Duration(minutes: 10));
      expect(handler.sleepAtEndOfTrack.value, isFalse);
      handler.cancelSleepTimer();
    });

    test('playing a song again counts a listen', () async {
      await start(buildSongs(1));

      await handler.playAgain();

      expect(host.listens, [songId(0)]);
    });
  });
}
