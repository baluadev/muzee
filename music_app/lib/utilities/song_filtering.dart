List<dynamic> filterSongsByQuery(List<dynamic> songsList, String searchQuery) {
  if (searchQuery.isEmpty) return songsList;

  final q = searchQuery.toLowerCase();
  return songsList.where((s) {
    final title = (s['title'] ?? '').toString().toLowerCase();
    final artist = (s['artist'] ?? '').toString().toLowerCase();
    return title.contains(q) || artist.contains(q);
  }).toList();
}

/// Longest video the Songs search tab treats as a single song. Mixes and
/// "best of" compilations seen in results run 27 minutes and up; 20 leaves
/// room for long tracks (extended mixes, progressive rock).
const maxSongLength = Duration(minutes: 20);

/// Whether a video of [duration] should be listed as a song. Unknown
/// durations are kept.
bool looksLikeSong(Duration? duration) =>
    duration == null || duration <= maxSongLength;
