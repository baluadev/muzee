import 'dart:math';

class PlaylistUtils {
  static bool isFolder(Map data) => data.containsKey('playlists');

  static bool isCustomPlaylist(Map playlist) {
    final source = playlist['source']?.toString();
    final playlistId = playlist['ytid']?.toString();
    return source == 'user-created' ||
        (playlistId != null && playlistId.startsWith('customId-'));
  }

  static String generateCustomPlaylistId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = Random().nextInt(0x7fffffff);
    return 'customId-$timestamp-$randomSuffix';
  }

  /// Find the index of a song in a playlist by its ytid.
  /// Returns the index if found, -1 if not found.
  static int findSongIndexByYtid(Map playlist, String songYtid) {
    final list = playlist['list'] as List<dynamic>? ?? [];
    return list.indexWhere((s) => s is Map && s['ytid'] == songYtid);
  }
}
