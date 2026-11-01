// The taste profile: how plays end, liked songs, listening counts and the
// YouTube likes/subscriptions of a signed-in listener all shape the score
// autoplay ranks suggestions by; YouTube likes and subscriptions are read
// page by page and only artist names are kept.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muzee/services/taste_profile.dart';
import 'package:muzee/services/youtube_taste_sync.dart';

import '../helpers/audio_test_harness.dart';

void main() {
  late Directory storage;
  late List liked;
  late List recent;
  late TasteProfile profile;

  setUpAll(() async => storage = await setUpTestStorage());
  tearDownAll(() => tearDownTestStorage(storage));

  setUp(() async {
    await Hive.box('user').clear();
    await Hive.box('userNoBackup').clear();
    liked = [];
    recent = [];
    profile = TasteProfile(
      userBox: Hive.box('user'),
      deviceBox: Hive.box('userNoBackup'),
      likedSongs: () => liked,
      recentSongs: () => recent,
    );
  });

  Map song(String ytid, String artist) => {'ytid': ytid, 'artist': artist};

  double score(String ytid, String artist, {bool youTube = true}) => profile
      .snapshot(includeYouTube: youTube)
      .score(ytid: ytid, artists: [artist]);

  group('artist keys', () {
    test('drop channel suffixes and case', () {
      expect(artistKey('HozierVEVO'), 'hozier');
      expect(artistKey('Joy Crookes - Topic'), 'joycrookes');
      expect(artistKey('Sơn Tùng M-TP Official'), 'sơntùngm-tp');
    });

    test('split collaborations', () {
      expect(artistKeys('Đen, MIN'), ['đen', 'min']);
      expect(artistKeys('Chủ Tịch Mai x Giám Đốc Hà'), [
        'chủtịchmai',
        'giámđốchà',
      ]);
      expect(artistKeys(null), isEmpty);
    });
  });

  group('play outcome', () {
    const length = Duration(minutes: 4);

    test('to the end, or most of the way, is finished', () {
      expect(
        PlayOutcome.of(
          position: Duration.zero,
          duration: length,
          completed: true,
        ),
        PlayOutcome.finished,
      );
      expect(
        PlayOutcome.of(
          position: const Duration(minutes: 3),
          duration: length,
          completed: false,
        ),
        PlayOutcome.finished,
      );
    });

    test('left within the first seconds is skipped', () {
      expect(
        PlayOutcome.of(
          position: const Duration(seconds: 8),
          duration: length,
          completed: false,
        ),
        PlayOutcome.skipped,
      );
    });

    test('in between says nothing', () {
      expect(
        PlayOutcome.of(
          position: const Duration(minutes: 1),
          duration: length,
          completed: false,
        ),
        PlayOutcome.partial,
      );
    });
  });

  group('score', () {
    test('an unknown artist scores 0', () {
      expect(score('a', 'Nobody'), 0);
    });

    test('artists played to the end rise, skipped ones fall', () async {
      for (var i = 0; i < 3; i++) {
        await profile.recordPlayEnd(
          song('h$i', 'Hozier'),
          position: Duration.zero,
          duration: null,
          completed: true,
        );
        await profile.recordPlayEnd(
          song('q$i', 'Quân A.P'),
          position: const Duration(seconds: 5),
          duration: const Duration(minutes: 3),
          completed: false,
        );
      }
      expect(score('new', 'HozierVEVO'), greaterThan(0));
      expect(score('new', 'Quân A.P'), lessThan(0));
      // The skipped songs themselves fall further.
      expect(score('q0', 'Quân A.P'), lessThan(score('new', 'Quân A.P')));
    });

    test('liked songs and listening counts count for their artists', () {
      liked = [song('l', 'Joy Crookes')];
      recent = [
        {...song('r', 'Vũ.'), 'listeningCount': 4},
      ];
      expect(score('x', 'Joy Crookes'), greaterThan(0));
      expect(score('x', 'Vũ.'), greaterThan(0));
    });

    test('the best artist of a collaboration counts', () {
      liked = [song('l', 'Đen')];
      final snapshot = profile.snapshot();
      expect(
        snapshot.score(ytid: 'x', artists: ['Đen, MIN']),
        snapshot.score(ytid: 'x', artists: ['Đen']),
      );
    });

    test('YouTube likes and subscriptions count, unless turned off', () async {
      await profile.setYouTubeTaste(
        likedArtists: {'lukecombs': 3},
        subscriptions: ['hollyhumberstone'],
        syncedAt: DateTime(2026),
      );
      expect(score('x', 'Luke Combs - Topic'), greaterThan(0));
      expect(score('x', 'Holly Humberstone'), greaterThan(0));
      expect(score('x', 'Luke Combs', youTube: false), 0);

      await profile.clearYouTubeTaste();
      expect(score('x', 'Luke Combs'), 0);
      expect(profile.youTubeSyncedAt, isNull);
    });

    test('listening signals are kept with the user data', () async {
      await profile.recordPlayEnd(
        song('h', 'Hozier'),
        position: Duration.zero,
        duration: null,
        completed: true,
      );
      expect(Hive.box('user').get('tasteSignals'), isNotNull);
      expect(Hive.box('userNoBackup').get('tasteSignals'), isNull);
    });
  });

  group('YouTube sync', () {
    late List<http.Request> requests;

    YouTubeTasteSync sync(Map<String, List<Map>> pages, {String? token}) {
      requests = [];
      return YouTubeTasteSync(
        profile: profile,
        accessToken: () async => token,
        client: MockClient((request) async {
          requests.add(request);
          final resource = request.url.pathSegments.last;
          final page =
              int.tryParse(request.url.queryParameters['pageToken'] ?? '0') ??
              0;
          final list = pages[resource]!;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'items': list[page]['items'],
                if (page + 1 < list.length) 'nextPageToken': '${page + 1}',
              }),
            ),
            200,
          );
        }),
      );
    }

    Map video(String channel, String category) => {
      'snippet': {'channelTitle': channel, 'categoryId': category},
    };

    test('keeps the artists of liked music and of subscriptions', () async {
      final ran = await sync({
        'videos': [
          {
            'items': [
              video('Luke Combs - Topic', '10'),
              video('Some Vlogger', '22'),
            ],
          },
          {
            'items': [video('LukeCombsVEVO', '10')],
          },
        ],
        'subscriptions': [
          {
            'items': [
              {
                'snippet': {'title': 'Holly Humberstone'},
              },
            ],
          },
        ],
      }, token: 'tok').sync();

      expect(ran, isTrue);
      expect(requests.first.headers['Authorization'], 'Bearer tok');
      expect(requests.first.url.queryParameters['myRating'], 'like');
      expect(
        requests.where((r) => r.url.path.endsWith('/videos')),
        hasLength(2),
      );
      final stored =
          Hive.box('userNoBackup').get(TasteProfile.youTubeKey) as Map;
      expect(stored['likedArtists'], {'lukecombs': 2});
      expect(stored['subscriptions'], ['hollyhumberstone']);
    });

    test('a fresh copy is not read again; signed out reads nothing', () async {
      await profile.setYouTubeTaste(
        likedArtists: {},
        subscriptions: [],
        syncedAt: DateTime.now(),
      );
      expect(await sync({}, token: 'tok').sync(), isFalse);
      expect(requests, isEmpty);

      expect(await sync({}).sync(force: true), isFalse);
      expect(requests, isEmpty);
    });
  });
}
