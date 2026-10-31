import 'package:hive/hive.dart';
import 'package:muzee/screens/search/search_controller.dart'
    show searchHistoryNotifier;
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/playlists_manager.dart';

/// Keys of the `user` box that make up the library: what cloud backup saves
/// and the Muzee 1.x migration fills in.
const libraryKeys = [
  'likedSongs',
  'recentlyPlayedSongs',
  'customPlaylists',
  'playlists',
  'likedPlaylists',
  'playlistFolders',
  'pinnedPlaylistIds',
  'searchHistory',
];

/// Re-reads the library from the `user` box into the in-memory lists and
/// notifiers the screens use. Call after writing the box directly (cloud
/// restore); writes made before anything reads the library (the startup
/// migration) don't need it.
void reloadLibraryFromStorage() {
  final box = Hive.box('user');
  List read(String key) => List.from(box.get(key, defaultValue: []) as List);

  userLikedSongsList = read('likedSongs');
  currentLikedSongsLength.value = userLikedSongsList.length;
  userRecentlyPlayed = read('recentlyPlayedSongs');
  currentRecentlyPlayedLength.value = userRecentlyPlayed.length;
  recentlyPlayedVersion.value++;

  userCustomPlaylists.value = List<Map>.from(read('customPlaylists'));
  userPlaylists.value = List<String>.from(read('playlists'));
  userLikedPlaylists = List<Map>.from(read('likedPlaylists'));
  currentLikedPlaylistsLength.value = userLikedPlaylists.length;
  userPlaylistFolders.value = List<Map>.from(read('playlistFolders'));
  pinnedPlaylistIds.value = List<String>.from(read('pinnedPlaylistIds'));
  searchHistoryNotifier.value = read('searchHistory');
}

/// [value] as plain JSON data (String-keyed maps), which Firestore needs;
/// Hive hands maps back as `Map<dynamic, dynamic>`.
Object? toJsonSafe(Object? value) {
  if (value is Map) {
    return {
      for (final e in value.entries) e.key.toString(): toJsonSafe(e.value),
    };
  }
  if (value is Iterable) return [for (final v in value) toJsonSafe(v)];
  if (value is DateTime) return value.millisecondsSinceEpoch;
  return value;
}
