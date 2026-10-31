// Moving the Muzee 1.x library (Isar + SharedPreferences) into 2.x (Hive).
//
// The end-to-end test writes a real 1.x database with 1.x's schemas and
// needs the Isar core library for this machine; it is downloaded once into
// the system temp dir, and the test skips when that isn't possible.
//
// No TestWidgetsFlutterBinding here: it would block that download.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:isar_community/isar.dart';
import 'package:muzee/services/legacy/isar/artist_model.dart';
import 'package:muzee/services/legacy/isar/playlist_model.dart';
import 'package:muzee/services/legacy/isar/related_video_cache.dart';
import 'package:muzee/services/legacy/isar/search_history_model.dart';
import 'package:muzee/services/legacy/isar/song_model.dart';
import 'package:muzee/services/legacy/legacy_library.dart';
import 'package:muzee/services/legacy/legacy_migration.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

SongModel song(
  String id, {
  String? title,
  int duration = 200,
  int plays = 0,
  DateTime? lastPlayed,
}) =>
    SongModel(
        songId: id,
        title: title ?? 'Song $id',
        artist: 'Artist $id',
        thumbnailUrl: 'https://img.test/$id.jpg',
        duration: duration,
      )
      ..playCount = plays
      ..lastPlayedAt = lastPlayed;

PlaylistModel playlist(
  String title, {
  String? playlistId,
  bool isYoutube = false,
}) =>
    PlaylistModel(title: title, playlistId: playlistId, isYoutube: isYoutube)
      ..createdAt = DateTime(2025, 6, 1);

SearchHistoryModel search(String keyword, DateTime at) =>
    SearchHistoryModel.withParams(
      keyword: keyword,
      type: 'song',
      createdAt: at,
    );

List<String> ytids(List list) => [for (final s in list) s['ytid'] as String];

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('muzee_migration_');
    Hive.init(dir.path);
    await Hive.openBox('settings');
    await Hive.openBox('user');
    await Hive.openBox('monetization');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  group('converting the 1.x library', () {
    test('liked songs keep their order and become 2.x song maps', () {
      final library = convertLegacyLibrary(
        playlists: [
          (
            playlist: playlist(legacyLikedPlaylistName),
            songs: [song('aaaaaaaaaaa'), song('bbbbbbbbbbb')],
          ),
        ],
        searches: const [],
      );

      expect(ytids(library.likedSongs), ['aaaaaaaaaaa', 'bbbbbbbbbbb']);
      expect(library.likedSongs.first, {
        'id': 0,
        'ytid': 'aaaaaaaaaaa',
        'title': 'Song aaaaaaaaaaa',
        'artist': 'Artist aaaaaaaaaaa',
        'image': 'https://img.test/aaaaaaaaaaa.jpg',
        'lowResImage': 'https://img.test/aaaaaaaaaaa.jpg',
        'highResImage': 'https://img.test/aaaaaaaaaaa.jpg',
        'duration': 200,
        'isLive': false,
      });
    });

    test('recently played is newest first and keeps play counts', () {
      final library = convertLegacyLibrary(
        playlists: [
          (
            playlist: playlist(legacyRecentlyPlayedPlaylistName),
            songs: [
              song('old00000000', plays: 7, lastPlayed: DateTime(2025, 1, 1)),
              song('new00000000', plays: 2, lastPlayed: DateTime(2025, 8, 1)),
            ],
          ),
        ],
        searches: const [],
      );

      expect(ytids(library.recentlyPlayed), ['new00000000', 'old00000000']);
      expect(library.recentlyPlayed.last['listeningCount'], 7);
      expect(library.recentlyPlayed.last['lastPlayed'], DateTime(2025, 1, 1));
    });

    test(
      'YouTube playlists are saved by id, own playlists keep their songs',
      () {
        final library = convertLegacyLibrary(
          playlists: [
            (
              playlist: playlist(
                'From a link',
                playlistId: 'PLimported',
                isYoutube: true,
              ),
              songs: const [],
            ),
            // Saved from Browse: a YouTube id and no songs of its own.
            (
              playlist: playlist('Chill mood', playlistId: 'RDbrowse'),
              songs: const [],
            ),
            (
              playlist: playlist('Gym'),
              songs: [
                song('aaaaaaaaaaa'),
                song('aaaaaaaaaaa'),
                song('ccccccccccc'),
              ],
            ),
          ],
          searches: const [],
        );

        expect(library.youtubePlaylistIds, ['PLimported', 'RDbrowse']);
        expect(library.customPlaylists, hasLength(1));
        final gym = library.customPlaylists.single;
        expect(gym['title'], 'Gym');
        expect(gym['source'], 'user-created');
        expect(gym['ytid'], startsWith('customId-'));
        expect(ytids(gym['list'] as List), ['aaaaaaaaaaa', 'ccccccccccc']);
        expect(gym['createdAt'], DateTime(2025, 6, 1).millisecondsSinceEpoch);
      },
    );

    test('search history keeps the newest distinct keywords', () {
      final library = convertLegacyLibrary(
        playlists: const [],
        searches: [
          search('den vau', DateTime(2025, 1, 1)),
          search('lofi', DateTime(2025, 3, 1)),
          search('den vau', DateTime(2025, 2, 1)),
          search('  ', DateTime(2025, 4, 1)),
        ],
      );

      expect(library.searchHistory, ['lofi', 'den vau']);
    });

    test('durations stored in milliseconds become seconds', () {
      final map = legacySongToMap(song('aaaaaaaaaaa', duration: 245000000));
      expect(map['duration'], 245000);
      expect(
        legacySongToMap(song('aaaaaaaaaaa', duration: 0)),
        isNot(contains('duration')),
      );
    });
  });

  group('writing it into 2.x', () {
    test('adds to what is there and does not duplicate on a retry', () async {
      final user = Hive.box('user');
      await user.put('likedSongs', [
        {'ytid': 'zzzzzzzzzzz', 'title': 'Liked in 2.x'},
      ]);
      final library = convertLegacyLibrary(
        playlists: [
          (
            playlist: playlist(legacyLikedPlaylistName),
            songs: [song('aaaaaaaaaaa'), song('zzzzzzzzzzz')],
          ),
          (playlist: playlist('Gym'), songs: [song('ccccccccccc')]),
          (
            playlist: playlist('Mix', playlistId: 'PL1', isYoutube: true),
            songs: const [],
          ),
        ],
        searches: [search('lofi', DateTime(2025))],
      );

      await writeLegacyLibrary(library);
      await writeLegacyLibrary(library);

      expect(ytids(user.get('likedSongs')), ['zzzzzzzzzzz', 'aaaaaaaaaaa']);
      expect(user.get('customPlaylists'), hasLength(1));
      expect(user.get('playlists'), ['PL1']);
      expect(user.get('searchHistory'), ['lofi']);
    });
  });

  group('1.x preferences', () {
    test('the "ads removed" purchase becomes lifetime Premium', () async {
      SharedPreferences.setMockInitialValues({'is_ads_removed': true});
      await EntitlementService.loadFromStorage();
      expect(EntitlementService.isPremium.value, isFalse);

      await migrateMuzee1Preferences(Hive.box('settings'));

      expect(EntitlementService.isPremium.value, isTrue);
    });

    test('language and country carry over unless 2.x has its own', () async {
      SharedPreferences.setMockInitialValues({
        'languageCode': 'vi',
        'countryCode': 'VN',
      });
      final settings = Hive.box('settings');

      await migrateMuzee1Preferences(settings);
      expect(settings.get('languageCode'), 'vi');
      expect(settings.get('youtubeChartsCountry'), 'vn');

      await settings.put('languageCode', 'fr');
      await migrateMuzee1Preferences(settings);
      expect(settings.get('languageCode'), 'fr');
    });
  });

  group('a real 1.x database', () {
    var coreLoaded = false;

    setUpAll(() async {
      final core = File(
        '${Directory.systemTemp.path}/isar_core_${Isar.version}_${Abi.current()}',
      );
      try {
        await Isar.initializeIsarCore(
          libraries: {Abi.current(): core.path},
          download: true,
        );
        coreLoaded = true;
      } catch (e) {
        // ignore: avoid_print
        print('Isar core unavailable ($e); skipping the database test');
      }
    });

    test('is read and moved into the 2.x library', () async {
      if (!coreLoaded) {
        markTestSkipped('Isar core library unavailable');
        return;
      }
      final isar = await Isar.open(
        [
          PlaylistModelSchema,
          SongModelSchema,
          SearchHistoryModelSchema,
          ArtistModelSchema,
          RelatedVideoCacheSchema,
        ],
        directory: dir.path,
        inspector: false,
      );
      await isar.writeTxn(() async {
        final liked = song('aaaaaaaaaaa', title: 'Liked one');
        final played = song(
          'bbbbbbbbbbb',
          plays: 4,
          lastPlayed: DateTime(2025, 8),
        );
        final both = song('ccccccccccc');
        await isar.songModels.putAll([liked, played, both]);

        final likedList = playlist(legacyLikedPlaylistName);
        final recent = playlist(legacyRecentlyPlayedPlaylistName);
        final gym = playlist('Gym');
        final yt = playlist('Mix', playlistId: 'PLmix', isYoutube: true);
        await isar.playlistModels.putAll([likedList, recent, gym, yt]);
        likedList.songs.addAll([liked, both]);
        recent.songs.add(played);
        gym.songs.add(both);
        await likedList.songs.save();
        await recent.songs.save();
        await gym.songs.save();

        await isar.searchHistoryModels.put(search('den vau', DateTime(2025)));
        await isar.artistModels.put(ArtistModel(name: 'Đen', channelId: 'UC1'));
      });
      await isar.close();

      await migrateMuzee1Library(dir.path);

      final user = Hive.box('user');
      expect(ytids(user.get('likedSongs')).toSet(), {
        'aaaaaaaaaaa',
        'ccccccccccc',
      });
      final recent = user.get('recentlyPlayedSongs') as List;
      expect(ytids(recent), ['bbbbbbbbbbb']);
      expect(recent.single['listeningCount'], 4);
      final custom = user.get('customPlaylists') as List;
      expect(custom.single['title'], 'Gym');
      expect(ytids(custom.single['list'] as List), ['ccccccccccc']);
      expect(user.get('playlists'), ['PLmix']);
      expect(user.get('searchHistory'), ['den vau']);
      // The 1.x database stays where it was.
      expect(File('${dir.path}/default.isar').existsSync(), isTrue);
    });
  });
}
