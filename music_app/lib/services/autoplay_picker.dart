import 'dart:math';

import 'package:muzee/services/taste_profile.dart';
import 'package:muzee/services/youtube_music_api.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Shortest and longest video autoplay treats as a song.
const autoplayMinLength = Duration(seconds: 60);
const autoplayMaxLength = Duration(minutes: 10);

/// Titles that mark a video as something other than a song: reactions,
/// episodes, podcasts, trailers, interviews, vlogs, long mixes…
final _notASongTitle = RegExp(
  r'\b(?:reaction|reacts?|react to|episode|ep\.?\s?\d+|t[aậ]p\s?\d+|podcast|'
  'trailer|teaser|interview|phỏng vấn|behind the scenes|vlog|livestream|'
  'live stream|full album|playlist|compilation|review|'
  r'\d+\s?(?:hours?|hrs?|giờ))\b',
  caseSensitive: false,
);

/// Whether a video titled [title] and [duration] long should be autoplayed
/// as a song. An unknown length counts as a song.
bool isLikelySong({required String title, Duration? duration}) {
  if (duration != null &&
      (duration < autoplayMinLength || duration > autoplayMaxLength)) {
    return false;
  }
  return !_notASongTitle.hasMatch(title);
}

/// Picks the next song to autoplay after a video.
///
/// Muzee's own pick ([fromRelated]) takes YouTube's related videos, keeps
/// the ones that look like songs and haven't been heard recently. With
/// external recommendations on, [fromYouTubeMusicRadio] asks YouTube Music
/// for its radio (song-only, from its own recommender) instead.
///
/// Either way the candidates are ranked by how close they are to the song
/// (the source's order) plus how much the listener likes them
/// ([TasteSnapshot.score]), and the pick is one of the top few.
class AutoplayPicker {
  AutoplayPicker({YouTubeMusicApi? ytm, Random? random})
    : _ytm = ytm ?? YouTubeMusicApi(),
      _random = random ?? Random();

  final YouTubeMusicApi _ytm;
  final Random _random;

  /// How many of the best candidates the pick is drawn from, so the same
  /// song doesn't always follow the same song.
  static const pickFrom = 3;

  /// How many suitable candidates are ranked.
  static const poolSize = 15;

  /// Weight of closeness to the current song against taste: the closest
  /// candidate gets this much, the farthest almost nothing.
  static const relevanceWeight = 1.5;

  /// The song to play from [pool] (source order, closest first), ranked by
  /// closeness and [taste].
  Map<String, dynamic>? _pick(
    List<({Map<String, dynamic> song, List<String?> artists})> pool,
    TasteSnapshot taste,
  ) {
    if (pool.isEmpty) return null;
    final scored = [
      for (var i = 0; i < pool.length; i++)
        (
          song: pool[i].song,
          score:
              relevanceWeight * (1 - i / pool.length) +
              taste.score(
                ytid: '${pool[i].song['ytid']}',
                artists: pool[i].artists,
              ),
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));
    final top = scored.take(pickFrom).toList();
    return top[_random.nextInt(top.length)].song;
  }

  /// [related] videos as songs, minus [exclude] (ytids), best first.
  Map<String, dynamic>? fromRelated(
    String currentId,
    Iterable<Video> related,
    Set<String> exclude,
    Map<String, dynamic> Function(Video) toSong, {
    TasteSnapshot? taste,
  }) {
    final pool = related
        .where(
          (v) =>
              !v.isLive &&
              v.id.value != currentId &&
              !exclude.contains(v.id.value) &&
              isLikelySong(title: v.title, duration: v.duration),
        )
        .take(poolSize)
        .map((v) {
          final song = toSong(v);
          // The channel often names the artist better than the title split.
          return (
            song: song,
            artists: <String?>[song['artist']?.toString(), v.author],
          );
        })
        .toList();
    return _pick(pool, taste ?? TasteSnapshot.empty);
  }

  /// A song from YouTube Music's radio for [videoId], or null.
  Future<Map<String, dynamic>?> fromYouTubeMusicRadio(
    String videoId,
    Set<String> exclude, {
    TasteSnapshot? taste,
  }) async {
    final response = await _ytm.post('next', {
      'videoId': videoId,
      'playlistId': 'RDAMVM$videoId',
    });
    final pool = <({Map<String, dynamic> song, List<String?> artists})>[];
    for (final item in YouTubeMusicApi.findAll(
      response,
      'playlistPanelVideoRenderer',
    )) {
      if (item is! Map) continue;
      final id = item['videoId'];
      if (id is! String || id == videoId || exclude.contains(id)) continue;
      final title = YouTubeMusicApi.runsText(item['title']) ?? '';
      final duration = _parseLength(
        YouTubeMusicApi.runsText(item['lengthText']),
      );
      if (title.isEmpty || !isLikelySong(title: title, duration: duration)) {
        continue;
      }
      // "Artist • Album • 2019": the first run is the artist.
      final byline = YouTubeMusicApi.path(item, ['longBylineText', 'runs']);
      final artist = byline is List && byline.isNotEmpty
          ? (byline.first as Map)['text']?.toString()
          : null;
      pool.add((song: _song(id, title, artist, duration), artists: [artist]));
      if (pool.length == poolSize) break;
    }
    return _pick(pool, taste ?? TasteSnapshot.empty);
  }

  static Map<String, dynamic> _song(
    String id,
    String title,
    String? artist,
    Duration? duration,
  ) => {
    'id': 0,
    'ytid': id,
    'title': title,
    'artist': artist ?? '',
    'image': 'https://i.ytimg.com/vi/$id/sddefault.jpg',
    'lowResImage': 'https://i.ytimg.com/vi/$id/default.jpg',
    'highResImage': 'https://i.ytimg.com/vi/$id/maxresdefault.jpg',
    'duration': duration?.inSeconds,
    'isLive': false,
  };

  /// "3:45" or "1:02:03" as a duration.
  static Duration? _parseLength(String? text) {
    if (text == null || text.isEmpty) return null;
    final parts = text.split(':').map(int.tryParse).toList();
    if (parts.any((p) => p == null)) return null;
    var seconds = 0;
    for (final p in parts) {
      seconds = seconds * 60 + p!;
    }
    return Duration(seconds: seconds);
  }
}
