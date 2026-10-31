// PLAY-003: a 20-song queue with shuffle, then repeat, enabled. No song is
// played twice when it shouldn't be, and none is skipped.
//
// Drives the real MusifyAudioHandler queue/shuffle/repeat code through
// test/helpers/audio_test_harness.dart (see that file for the seam).

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/services/settings_manager.dart';

import '../helpers/audio_test_harness.dart';
import '../helpers/fake_youtube_http.dart';

void main() {
  late Directory storage;
  late TestAudioHandler handler;
  final songs = buildSongs(20);
  final allIds = [for (final s in songs) s['ytid'] as String];

  List<String> queueIds() => [
    for (final s in handler.currentQueue) s['ytid'] as String,
  ];

  Future<void> startPlaylist({int startIndex = 0}) async {
    await handler.addPlaylistToQueue(
      songs,
      replace: true,
      startIndex: startIndex,
    );
    await settle();
  }

  Future<void> enableShuffleThenRepeat(AudioServiceRepeatMode repeat) async {
    await handler.setShuffleMode(AudioServiceShuffleMode.all);
    await handler.setRepeatMode(repeat);
    await settle();
  }

  setUpAll(() async {
    storage = await setUpTestStorage();
    // Nothing in this file should reach the network.
    HttpOverrides.global = FakeYouTubeHttp();
  });

  tearDownAll(() => tearDownTestStorage(storage));

  setUp(() {
    shuffleNotifier.value = false;
    repeatNotifier.value = AudioServiceRepeatMode.none;
    playNextSongAutomatically.value = false;
    // Turns off look-ahead stream preloading, which would hit the network in
    // the background. It does not change queue/shuffle/repeat decisions.
    offlineMode.value = true;
    handler = TestAudioHandler.create();
  });

  tearDown(() {
    handler.retire();
    expect(handler.unexpectedErrors, isEmpty);
  });

  group('shuffle', () {
    test(
      'keeps all 20 songs exactly once, with the current song first',
      () async {
        await startPlaylist();
        final before = queueIds();

        await handler.setShuffleMode(AudioServiceShuffleMode.all);

        final after = queueIds();
        expect(after, hasLength(20));
        expect(after.toSet(), allIds.toSet());
        expect(after.first, songId(0));
        expect(handler.currentQueueIndex, 0);
        expect(handler.currentSong?['ytid'], songId(0));
        // 1 in 19! chance of the same order by luck.
        expect(after, isNot(equals(before)));
        final entryIds = handler.currentQueue.map((s) => s['queueEntryId']);
        expect(entryIds.toSet(), hasLength(20));
      },
    );

    test(
      'started from the middle of a playlist keeps that song current',
      () async {
        await startPlaylist(startIndex: 7);
        expect(handler.played, [songId(7)]);

        await handler.setShuffleMode(AudioServiceShuffleMode.all);

        expect(queueIds().first, songId(7));
        expect(queueIds().toSet(), allIds.toSet());
        expect(queueIds(), hasLength(20));
      },
    );

    test('keeps a "play next" song right after the current one', () async {
      await startPlaylist();
      final extra = {...buildSongs(21).last, 'title': 'Queued next'};
      await handler.addToQueue(extra, playNext: true);

      await handler.setShuffleMode(AudioServiceShuffleMode.all);

      expect(queueIds(), hasLength(21));
      expect(queueIds().toSet(), {...allIds, songId(20)});
      expect(queueIds()[0], songId(0));
      expect(queueIds()[1], songId(20));
    });

    test(
      'turning shuffle off restores the original order and keeps the current song',
      () async {
        await startPlaylist();
        await handler.setShuffleMode(AudioServiceShuffleMode.all);
        for (var i = 0; i < 5; i++) {
          await handler.finishCurrentTrack();
        }
        final current = handler.currentSong!['ytid'] as String;

        await handler.setShuffleMode(AudioServiceShuffleMode.none);

        expect(queueIds(), allIds);
        expect(handler.currentSong?['ytid'], current);
        expect(handler.currentQueueIndex, allIds.indexOf(current));
      },
    );
  });

  group('shuffle then repeat all', () {
    test(
      'songs ending on their own play each song once per pass, then wrap',
      () async {
        await startPlaylist();
        await enableShuffleThenRepeat(AudioServiceRepeatMode.all);
        final shuffledOrder = queueIds();

        for (var i = 0; i < 19; i++) {
          await handler.finishCurrentTrack();
        }
        expect(handler.played, shuffledOrder, reason: 'first pass');

        // End of queue: repeat all goes back to the top of the same order.
        await handler.finishCurrentTrack();
        expect(handler.currentQueueIndex, 0);
        for (var i = 0; i < 19; i++) {
          await handler.finishCurrentTrack();
        }

        expect(handler.played, [...shuffledOrder, ...shuffledOrder]);
        // Every load the handler started was a successful, intended play: no
        // double loads from overlapping completion events.
        expect(handler.attempts, handler.played);
        expect(
          queueIds(),
          shuffledOrder,
          reason: 'queue is not reshuffled on wrap',
        );
      },
    );

    test('pressing next plays each song once per pass, then wraps', () async {
      await startPlaylist();
      await enableShuffleThenRepeat(AudioServiceRepeatMode.all);
      final shuffledOrder = queueIds();

      for (var i = 0; i < 39; i++) {
        await handler.skipToNext();
        await settle();
      }

      expect(handler.played, [...shuffledOrder, ...shuffledOrder]);
      expect(handler.attempts, handler.played);
    });

    test('ended songs are recorded in history in play order', () async {
      await startPlaylist();
      await enableShuffleThenRepeat(AudioServiceRepeatMode.all);
      final shuffledOrder = queueIds();

      for (var i = 0; i < 20; i++) {
        await handler.finishCurrentTrack();
      }

      final history = [for (final s in handler.playHistory) s['ytid']];
      expect(history, shuffledOrder.reversed.toList());
    });
  });

  group('shuffle then other repeat modes', () {
    test('repeat off stops after the last song instead of wrapping', () async {
      await startPlaylist();
      await enableShuffleThenRepeat(AudioServiceRepeatMode.none);
      final shuffledOrder = queueIds();

      for (var i = 0; i < 19; i++) {
        await handler.finishCurrentTrack();
      }
      await handler.finishCurrentTrack();

      expect(handler.played, shuffledOrder);
      expect(handler.currentQueueIndex, 19);
    });

    test(
      'repeat one replays only the current song; next still advances',
      () async {
        await startPlaylist();
        await enableShuffleThenRepeat(AudioServiceRepeatMode.one);
        final shuffledOrder = queueIds();

        for (var i = 0; i < 3; i++) {
          await handler.finishCurrentTrack();
        }
        expect(handler.played, List.filled(4, songId(0)));
        expect(handler.currentQueueIndex, 0);

        await handler.skipToNext();
        await settle();
        expect(handler.played.last, shuffledOrder[1]);
      },
    );
  });
}
