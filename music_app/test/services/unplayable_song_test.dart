// PLAY-004: a song that was removed or is region-blocked. The app shows a
// clear error and moves on to the next song.
//
// Blocked songs go through the real MusifyAudioHandler.playSong and
// fetchSongStreamInfo; the fake network answers the way YouTube does for
// such videos. Playable songs use the harness's fake playback. The message
// itself is shown by AppShell from MusifyAudioHandler.playbackErrors.

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/settings_manager.dart';

import '../helpers/audio_test_harness.dart';
import '../helpers/fake_youtube_http.dart';

const _regionBlockedReason =
    'The uploader has not made this video available in your country';

void main() {
  late Directory storage;
  late TestAudioHandler handler;
  final http = FakeYouTubeHttp();
  final songs = buildSongs(5);

  // Longer than MusifyAudioHandler._errorRetryDelay (2 s).
  const retryWindow = Duration(milliseconds: 2600);

  /// Region-blocked ids answer UNPLAYABLE; removed ids have no watch page.
  void serve({
    Set<String> regionBlocked = const {},
    Set<String> removed = const {},
  }) {
    http.responder = youtubeResponder(
      removed: removed,
      player: (id) => regionBlocked.contains(id)
          ? playerUnplayableReply('UNPLAYABLE', _regionBlockedReason)
          : playerOkReply(id),
    );
  }

  int attemptsOf(String id) => handler.attempts.where((a) => a == id).length;

  Future<void> startPlaylist({int startIndex = 0}) async {
    await handler.addPlaylistToQueue(
      songs,
      replace: true,
      startIndex: startIndex,
    );
    await settle();
  }

  setUpAll(() async {
    storage = await setUpTestStorage();
    HttpOverrides.global = http;
  });

  tearDownAll(() => tearDownTestStorage(storage));

  setUp(() async {
    // Stream URLs are cached in memory and in Hive; start each test cold.
    await clearCache();
    shuffleNotifier.value = false;
    repeatNotifier.value = AudioServiceRepeatMode.none;
    playNextSongAutomatically.value = false;
    // Turns off background preloading of upcoming streams; the failing
    // song's own lookup still goes to the (fake) network.
    offlineMode.value = true;
    http.requests.clear();
    handler = TestAudioHandler.create();
  });

  tearDown(() {
    handler.retire();
    expect(handler.unexpectedErrors, isEmpty);
  });

  group('stream lookup', () {
    test(
      'a region-blocked video resolves to no stream instead of throwing',
      () async {
        serve(regionBlocked: {songId(2)});

        final info = await fetchSongStreamInfo(songId(2), false);

        expect(info, isNull);
        expect(
          http.requests.where((r) => r.playerVideoId == songId(2)),
          isNotEmpty,
          reason: 'the lookup reached the YouTube player endpoint',
        );
      },
    );

    test('a removed video resolves to no stream instead of throwing', () async {
      serve(removed: {songId(3)});

      final info = await fetchSongStreamInfo(songId(3), false);

      expect(info, isNull);
      expect(
        http.requests.where((r) => r.url.queryParameters['v'] == songId(3)),
        isNotEmpty,
      );
    });
  });

  group('player', () {
    test(
      'a blocked song in the queue is skipped and the next song plays',
      () async {
        serve(regionBlocked: {songId(2)});
        handler.unplayable.add(songId(2));
        await startPlaylist();
        await handler.finishCurrentTrack(); // song 0 ends -> song 1
        await handler.finishCurrentTrack(); // song 1 ends -> song 2 (blocked)
        expect(attemptsOf(songId(2)), 1);
        expect(handler.played, [songId(0), songId(1)]);

        await Future<void>.delayed(retryWindow);

        expect(handler.played, [songId(0), songId(1), songId(3)]);
        expect(attemptsOf(songId(2)), 1, reason: 'not retried');
        expect(handler.currentSong?['ytid'], songId(3));
      },
    );

    test('a blocked first song is skipped and the second song plays', () async {
      serve(regionBlocked: {songId(0)});
      handler.unplayable.add(songId(0));
      await startPlaylist();
      expect(handler.played, isEmpty);

      await Future<void>.delayed(retryWindow);

      expect(handler.played, [songId(1)]);
      expect(attemptsOf(songId(0)), 1);
    });

    test(
      'starting a playlist on a blocked song plays the song after it',
      () async {
        serve(regionBlocked: {songId(2)});
        handler.unplayable.add(songId(2));
        await startPlaylist(startIndex: 2);

        await Future<void>.delayed(retryWindow);

        expect(handler.played, [songId(3)]);
      },
    );

    test('a removed song is skipped the same way', () async {
      serve(removed: {songId(1)});
      handler.unplayable.add(songId(1));
      await startPlaylist();
      await handler.finishCurrentTrack(); // song 0 ends -> song 1 (removed)

      await Future<void>.delayed(retryWindow);

      expect(handler.played, [songId(0), songId(2)]);
    });

    test(
      'three blocked songs in a row stop playback instead of retrying forever',
      () async {
        final blocked = {songId(1), songId(2), songId(3)};
        serve(regionBlocked: blocked);
        handler.unplayable.addAll(blocked);
        await startPlaylist();
        await handler.finishCurrentTrack(); // song 0 ends -> blocked songs

        // 3 failures need 2 retry delays; wait one more to prove it stopped.
        await Future<void>.delayed(retryWindow * 3);

        expect(handler.attempts, [
          songId(0),
          ...blocked,
        ], reason: 'each tried once');
        expect(handler.played, [songId(0)]);
        expect(
          handler.playbackState.value.processingState,
          AudioProcessingState.idle,
        );
      },
    );

    test(
      'picking another song right after a failure is not undone by the pending retry',
      () async {
        final queue = buildSongs(8);
        serve(regionBlocked: {songId(2)});
        handler.unplayable.add(songId(2));
        await handler.addPlaylistToQueue(queue, replace: true, startIndex: 1);
        await settle();
        await handler.finishCurrentTrack(); // song 1 ends -> song 2 (blocked)

        await handler.skipToSong(5); // user taps another song
        await settle();
        expect(handler.played.last, songId(5));

        await Future<void>.delayed(retryWindow);

        expect(handler.currentSong?['ytid'], songId(5));
        expect(handler.played.last, songId(5));
      },
    );

    test(
      'stopping right after a failure is not undone by the pending retry',
      () async {
        serve(regionBlocked: {songId(2)});
        handler.unplayable.add(songId(2));
        await startPlaylist();
        await handler.finishCurrentTrack();
        await handler.finishCurrentTrack(); // -> song 2 (blocked)
        final attemptsBeforeStop = handler.attempts.length;

        await handler.stop();
        await Future<void>.delayed(retryWindow);

        expect(handler.attempts, hasLength(attemptsBeforeStop));
      },
    );

    test(
      'pausing right after a failure is not undone by the pending retry',
      () async {
        serve(regionBlocked: {songId(2)});
        handler.unplayable.add(songId(2));
        await startPlaylist();
        await handler.finishCurrentTrack();
        await handler.finishCurrentTrack(); // -> song 2 (blocked)
        final attemptsBeforePause = handler.attempts.length;

        await handler.pause();
        await Future<void>.delayed(retryWindow);

        expect(handler.attempts, hasLength(attemptsBeforePause));
      },
    );

    test('a blocked song is reported so the UI can tell the user', () async {
      serve(regionBlocked: {songId(1)});
      handler.unplayable.add(songId(1));
      final reported = <Map>[];
      final sub = handler.playbackErrors.listen(reported.add);
      addTearDown(sub.cancel);
      await startPlaylist();

      await handler.finishCurrentTrack(); // song 0 ends -> song 1 (blocked)
      await settle();

      expect(reported.map((s) => s['ytid']), [songId(1)]);
      expect(reported.single['title'], 'Song 1');
    });

    test('songs that play fine are not reported', () async {
      serve();
      final reported = <Map>[];
      final sub = handler.playbackErrors.listen(reported.add);
      addTearDown(sub.cancel);
      await startPlaylist();
      await handler.finishCurrentTrack();
      await settle();

      expect(reported, isEmpty);
    });

    test(
      'a failed song with nothing after it leaves the player paused, not loading',
      () async {
        serve(regionBlocked: {songId(0)});
        handler.unplayable.add(songId(0));
        await handler.addPlaylistToQueue([songs[0]], replace: true);
        await settle();

        final state = handler.playbackState.value;
        expect(state.processingState, AudioProcessingState.idle);
        expect(state.playing, isFalse);
      },
    );

    test('pressing play after a failure tries that song again', () async {
      serve(regionBlocked: {songId(0)});
      handler.unplayable.add(songId(0));
      await handler.addPlaylistToQueue([songs[0]], replace: true);
      await settle();
      expect(handler.played, isEmpty);

      // The song becomes available again (e.g. the network is back).
      handler.unplayable.clear();
      await handler.play();
      await settle();

      expect(handler.attempts, [songId(0), songId(0)]);
      expect(handler.played, [songId(0)]);
    });
  });

  group('preloading', () {
    test('stops once playback has stopped', () async {
      // Preloading only runs with offline mode off.
      offlineMode.value = false;
      addTearDown(() => offlineMode.value = true);
      serve();
      handler.realLookup.add(songId(0));
      await startPlaylist();
      final upcoming = {songId(1), songId(2), songId(3)};
      Set<String?> preloaded() => http.requests
          .map((r) => r.playerVideoId)
          .where(upcoming.contains)
          .toSet();
      // Let the first round finish (it runs at most 2 lookups at a time).
      for (var i = 0; i < 30 && preloaded().length < upcoming.length; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await settle();
      expect(
        preloaded(),
        upcoming,
        reason: 'upcoming songs preload while playing',
      );

      await handler.stop();
      await clearCache(); // nothing cached, so a preload would hit the network
      http.requests.clear();
      // The real load also schedules a preload 2 s after it started.
      await Future<void>.delayed(retryWindow);

      expect(preloaded(), isEmpty);
    });
  });

  group('player errors after the song loaded', () {
    Future<void> waitForAttempt(String id) async {
      for (var i = 0; i < 40 && handler.attempts.lastOrNull != id; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(handler.attempts.last, id);
    }

    test(
      'a stream that fails to start (network dropped) is reported and skipped',
      () async {
        handler.stalls.add(songId(1));
        final reported = <Map>[];
        final sub = handler.playbackErrors.listen(reported.add);
        addTearDown(sub.cancel);
        await startPlaylist();
        await handler
            .finishCurrentTrack(); // song 0 ends -> song 1 loads, stalls

        handler.reportPlayerError();
        await settle();
        expect(reported.map((s) => s['ytid']), [songId(1)]);

        await Future<void>.delayed(retryWindow);
        expect(handler.played, [songId(0), songId(2)]);
      },
    );

    test(
      'an error that arrives while the song is still loading is not lost',
      () async {
        handler
          ..stalls.add(songId(1))
          ..errorsWhileLoading.add(songId(1));
        final reported = <Map>[];
        final sub = handler.playbackErrors.listen(reported.add);
        addTearDown(sub.cancel);
        await startPlaylist();
        await handler.finishCurrentTrack(); // song 1 errors during its load

        expect(reported.map((s) => s['ytid']), [songId(1)]);
        await Future<void>.delayed(retryWindow);
        expect(handler.played, [songId(0), songId(2)]);
      },
    );

    test('an error while a song is playing is left to the player', () async {
      final reported = <Map>[];
      final sub = handler.playbackErrors.listen(reported.add);
      addTearDown(sub.cancel);
      await startPlaylist();

      handler.reportPlayerError();
      await settle();
      await Future<void>.delayed(retryWindow);

      expect(reported, isEmpty);
      expect(handler.attempts, [songId(0)]);
    });

    test('three songs in a row that never start stop playback', () async {
      final stalling = [songId(1), songId(2), songId(3)];
      handler.stalls.addAll(stalling);
      await startPlaylist();
      await handler.finishCurrentTrack(); // song 0 ends -> song 1

      for (final id in stalling) {
        await waitForAttempt(id);
        handler.reportPlayerError();
        await settle();
        if (id != stalling.last) await Future<void>.delayed(retryWindow);
      }
      await Future<void>.delayed(retryWindow);

      expect(handler.attempts, [
        songId(0),
        ...stalling,
      ], reason: 'stopped, no 4th');
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.idle,
      );
      expect(
        handler.playbackState.value.playing,
        isFalse,
        reason: 'shows Play, not Pause',
      );
    });
  });
}
