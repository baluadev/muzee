import 'package:muzee/services/legacy/isar/playlist_model.dart';
import 'package:muzee/services/legacy/isar/search_history_model.dart';
import 'package:muzee/services/legacy/isar/song_model.dart';
import 'package:muzee/utilities/playlist_utils.dart';

/// Names Muzee 1.x gave its built-in playlists.
const legacyLikedPlaylistName = 'likedSong';
const legacyRecentlyPlayedPlaylistName = 'searchRecentlyPlayed';

/// The 2.x keeps at most this many recently played songs (see
/// `recentlyPlayedSongsLimit`) and search history entries.
const _recentlyPlayedLimit = 250;
const _searchHistoryLimit = 50;

/// A Muzee 1.x playlist with its songs (Isar links, loaded).
typedef LegacyPlaylist = ({PlaylistModel playlist, List<SongModel> songs});

/// The Muzee 1.x library in 2.x's formats (the `user` box values).
class LegacyLibrary {
  const LegacyLibrary({
    required this.likedSongs,
    required this.recentlyPlayed,
    required this.customPlaylists,
    required this.youtubePlaylistIds,
    required this.searchHistory,
  });

  final List<Map<String, dynamic>> likedSongs;
  final List<Map<String, dynamic>> recentlyPlayed;
  final List<Map<String, dynamic>> customPlaylists;
  final List<String> youtubePlaylistIds;
  final List<String> searchHistory;

  bool get isEmpty =>
      likedSongs.isEmpty &&
      recentlyPlayed.isEmpty &&
      customPlaylists.isEmpty &&
      youtubePlaylistIds.isEmpty &&
      searchHistory.isEmpty;
}

/// Converts what Muzee 1.x stored into the 2.x library:
///
/// - the `likedSong` playlist becomes the liked songs;
/// - the `searchRecentlyPlayed` playlist becomes recently played, newest
///   first, with 1.x's play counts;
/// - YouTube playlists (imported by link) become saved YouTube playlists;
/// - every other playlist becomes a playlist of the user's own;
/// - search history keeps its newest distinct keywords.
///
/// Followed artists have no 2.x equivalent and are not converted.
LegacyLibrary convertLegacyLibrary({
  required List<LegacyPlaylist> playlists,
  required List<SearchHistoryModel> searches,
}) {
  final liked = <Map<String, dynamic>>[];
  final recent = <SongModel>[];
  final custom = <Map<String, dynamic>>[];
  final youtubeIds = <String>[];

  for (final (:playlist, :songs) in playlists) {
    final title = playlist.title;
    if (title == legacyLikedPlaylistName) {
      for (final song in _distinct(songs)) {
        liked.add(legacySongToMap(song, index: liked.length));
      }
    } else if (title == legacyRecentlyPlayedPlaylistName) {
      recent.addAll(_distinct(songs));
    } else if (_youtubeId(playlist, songs) case final id?) {
      if (!youtubeIds.contains(id)) youtubeIds.add(id);
    } else {
      final distinct = _distinct(songs).toList();
      custom.add({
        'ytid': PlaylistUtils.generateCustomPlaylistId(),
        'title': (title == null || title.trim().isEmpty) ? 'Playlist' : title,
        'source': 'user-created',
        if (playlist.thumbnailUrl != null) 'image': playlist.thumbnailUrl,
        'list': [
          for (var i = 0; i < distinct.length; i++)
            legacySongToMap(distinct[i], index: i),
        ],
        'createdAt': playlist.createdAt.millisecondsSinceEpoch,
      });
    }
  }

  recent.sort(
    (a, b) => (b.lastPlayedAt ?? DateTime(1970)).compareTo(
      a.lastPlayedAt ?? DateTime(1970),
    ),
  );
  final recentlyPlayed = [
    for (final song in recent.take(_recentlyPlayedLimit))
      {
        ...legacySongToMap(song),
        'listeningCount': song.playCount,
        if (song.lastPlayedAt != null) 'lastPlayed': song.lastPlayedAt,
      },
  ];

  final sortedSearches = [...searches]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final history = <String>[];
  for (final search in sortedSearches) {
    final keyword = search.keyword.trim();
    if (keyword.isEmpty || history.contains(keyword)) continue;
    history.add(keyword);
    if (history.length == _searchHistoryLimit) break;
  }

  return LegacyLibrary(
    likedSongs: liked,
    recentlyPlayed: recentlyPlayed,
    customPlaylists: custom,
    youtubePlaylistIds: youtubeIds,
    searchHistory: history,
  );
}

/// A Muzee 1.x song as a 2.x song map (the shape `returnSongLayout` makes).
Map<String, dynamic> legacySongToMap(SongModel song, {int index = 0}) {
  final ytid = song.songId;
  final thumbnail = song.thumbnailUrl;
  var seconds = song.duration ?? 0;
  // 1.x stored seconds; anything over a day must have been milliseconds.
  if (seconds > const Duration(days: 1).inSeconds) seconds ~/= 1000;
  return {
    'id': index,
    'ytid': ytid,
    'title': song.title ?? '',
    'artist': song.artist ?? '',
    'image': thumbnail ?? 'https://i.ytimg.com/vi/$ytid/sddefault.jpg',
    'lowResImage': thumbnail ?? 'https://i.ytimg.com/vi/$ytid/mqdefault.jpg',
    'highResImage':
        thumbnail ?? 'https://i.ytimg.com/vi/$ytid/maxresdefault.jpg',
    if (seconds > 0) 'duration': seconds,
    'isLive': false,
  };
}

/// The YouTube playlist [playlist] mirrors, if it is one: imported by link
/// (`isYoutube`), or saved from Browse without songs of its own.
String? _youtubeId(PlaylistModel playlist, List<SongModel> songs) {
  final id = playlist.playlistId;
  if (id == null || id.isEmpty) return null;
  if (playlist.isYoutube || songs.isEmpty) return id;
  return null;
}

Iterable<SongModel> _distinct(List<SongModel> songs) {
  final seen = <String>{};
  return songs.where((s) => s.songId.isNotEmpty && seen.add(s.songId));
}
