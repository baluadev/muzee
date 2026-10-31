import 'dart:io';

import 'package:hive/hive.dart';
import 'package:isar_community/isar.dart';
import 'package:muzee/main.dart' show logger;
import 'package:muzee/services/legacy/isar/artist_model.dart';
import 'package:muzee/services/legacy/isar/playlist_model.dart';
import 'package:muzee/services/legacy/isar/related_video_cache.dart';
import 'package:muzee/services/legacy/isar/search_history_model.dart';
import 'package:muzee/services/legacy/isar/song_model.dart';
import 'package:muzee/services/legacy/legacy_library.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/monetization/premium_iap_service.dart';
import 'package:muzee/utilities/language_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_charts/youtube_charts.dart';

const _doneKey = 'muzee1MigrationDone';
const _attemptsKey = 'muzee1MigrationAttempts';

/// A migration that crashed the app (native Isar code can) is not tried
/// again after this many launches.
const _maxAttempts = 3;

/// Moves the Muzee 1.x library into 2.x, once, on the first launch after the
/// update: liked songs, playlists, recently played and search history from
/// the Isar database, and the "ads removed" purchase, language and country
/// from SharedPreferences.
///
/// Run it after the Hive boxes are open and before anything reads the
/// library. The old database is left in place (read only), so nothing is
/// lost if a later version needs it again.
Future<void> migrateMuzee1IfNeeded() async {
  final settings = Hive.box('settings');
  if (settings.get(_doneKey) == true) return;

  final attempts = (settings.get(_attemptsKey) as int? ?? 0) + 1;
  if (attempts > _maxAttempts) {
    logger.log('Muzee 1.x migration failed $_maxAttempts times; giving up');
    await settings.put(_doneKey, true);
    return;
  }
  // Saved before touching Isar, so a crash there still counts.
  await settings.put(_attemptsKey, attempts);
  await settings.flush();

  try {
    await migrateMuzee1Preferences(settings);
    final dir = await getApplicationDocumentsDirectory();
    if (File('${dir.path}/default.isar').existsSync()) {
      await migrateMuzee1Library(dir.path);
    }
    await settings.put(_doneKey, true);
    logger.log('Muzee 1.x migration done');
  } catch (e, stackTrace) {
    logger.log(
      'Muzee 1.x migration failed (attempt $attempts); retrying next launch',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

/// Copies the library out of the Muzee 1.x Isar database in [directory].
Future<void> migrateMuzee1Library(String directory) async {
  final isar = await Isar.open(
    // Every collection 1.x had, so opening it doesn't drop any.
    [
      PlaylistModelSchema,
      SongModelSchema,
      SearchHistoryModelSchema,
      ArtistModelSchema,
      RelatedVideoCacheSchema,
    ],
    directory: directory,
    inspector: false,
  );
  try {
    final playlists = <LegacyPlaylist>[];
    for (final playlist in await isar.playlistModels.where().findAll()) {
      await playlist.songs.load();
      playlists.add((playlist: playlist, songs: playlist.songs.toList()));
    }
    final searches = await isar.searchHistoryModels.where().findAll();
    final library = convertLegacyLibrary(
      playlists: playlists,
      searches: searches,
    );
    logger.log(
      'Muzee 1.x library: ${library.likedSongs.length} liked, '
      '${library.customPlaylists.length} playlists, '
      '${library.youtubePlaylistIds.length} YouTube playlists, '
      '${library.recentlyPlayed.length} recently played, '
      '${library.searchHistory.length} searches; '
      '${await isar.artistModels.count()} followed artists not carried over',
    );
    await writeLegacyLibrary(library);
  } finally {
    await isar.close();
  }
}

/// Adds [library] to the `user` box, keeping anything already there (so a
/// retried migration doesn't duplicate entries).
Future<void> writeLegacyLibrary(LegacyLibrary library) async {
  final user = Hive.box('user');
  List<Map> maps(String key) =>
      List<Map>.from(user.get(key, defaultValue: []) as List);
  List<String> strings(String key) =>
      List<String>.from(user.get(key, defaultValue: []) as List);

  List<Map> mergeSongs(List<Map> existing, List<Map<String, dynamic>> added) {
    final ids = {for (final s in existing) s['ytid']};
    return [...existing, ...added.where((s) => ids.add(s['ytid']))];
  }

  await user.put(
    'likedSongs',
    mergeSongs(maps('likedSongs'), library.likedSongs),
  );
  await user.put(
    'recentlyPlayedSongs',
    mergeSongs(maps('recentlyPlayedSongs'), library.recentlyPlayed),
  );

  final custom = maps('customPlaylists');
  final titles = {for (final p in custom) p['title']};
  await user.put('customPlaylists', [
    ...custom,
    ...library.customPlaylists.where((p) => titles.add(p['title'])),
  ]);

  final ytIds = strings('playlists');
  await user.put('playlists', [
    ...ytIds,
    ...library.youtubePlaylistIds.where((id) => !ytIds.contains(id)),
  ]);

  final history = strings('searchHistory');
  await user.put('searchHistory', [
    ...history,
    ...library.searchHistory.where((q) => !history.contains(q)),
  ]);
}

/// Carries over 1.x's SharedPreferences: the "ads removed" purchase,
/// language and charts country (unless 2.x already has its own).
Future<void> migrateMuzee1Preferences(Box settings) async {
  final prefs = await SharedPreferences.getInstance();

  // 1.x's one-time "remove ads" purchase is 2.x's lifetime Premium. Restoring
  // purchases confirms it too; this covers starting offline.
  if (prefs.getBool('is_ads_removed') ?? false) {
    await EntitlementService.setPremiumLifetime(
      productId: PremiumIapService.lifetimeProductId,
    );
  }

  final language = prefs.getString('languageCode');
  if (language != null &&
      appLanguages.contains(language) &&
      !settings.containsKey('languageCode')) {
    await settings.put('languageCode', language);
  }

  final country = prefs.getString('countryCode')?.toLowerCase();
  final chartsCountry = YouTubeChartsCountry.values
      .where((c) => c.name == country)
      .firstOrNull;
  if (chartsCountry != null && !settings.containsKey('youtubeChartsCountry')) {
    await settings.put('youtubeChartsCountry', chartsCountry.name);
  }
}
