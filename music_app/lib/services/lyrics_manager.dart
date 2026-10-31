import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:muzee/utilities/formatter.dart';

/// Finds plain lyrics for a song, trying in order:
///
/// 1. YouTube Music's lyrics for the video being played (licensed from
///    LyricFind). Looked up by video id, so it needs no title matching.
/// 2. LRCLIB (lrclib.net), an open, community-built lyrics database.
/// 3. lyrics.ovh.
///
/// 2 and 3 match on artist and title, cleaned of YouTube noise first
/// ([lyricsQuery]). The text ends with a "© source" line.
class LyricsManager {
  LyricsManager({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  /// LRCLIB asks clients to identify themselves.
  static const _userAgent = 'Muzee (https://github.com/baluadev/muzee)';

  /// The YouTube Music web client the lyrics requests pretend to be.
  static const _ytmContext = {
    'client': {'clientName': 'WEB_REMIX', 'clientVersion': '1.20241023.01.00'},
  };

  Future<String?> fetchLyrics({
    String? videoId,
    required String? artist,
    required String title,
    Duration? duration,
  }) async {
    if (videoId != null && videoId.isNotEmpty) {
      final ytm = await _fromYouTubeMusic(videoId);
      if (ytm != null) return ytm;
    }

    final query = lyricsQuery(artist: artist, title: title);
    if (query == null) return null;

    return await _fromLrclib(query.artist, query.title, duration) ??
        await _fromLyricsOvh(query.artist, query.title);
  }

  // --- YouTube Music ---------------------------------------------------------

  Future<String?> _fromYouTubeMusic(String videoId) async {
    try {
      final next = await _ytmPost('next', {'videoId': videoId});
      String? browseId;
      for (final tab in _findAll(next, 'tabRenderer')) {
        final id = _path(tab, ['endpoint', 'browseEndpoint', 'browseId']);
        if (id is String && id.startsWith('MPLY')) browseId = id;
      }
      if (browseId == null) return null;

      final browse = await _ytmPost('browse', {'browseId': browseId});
      final shelf = _findAll(
        browse,
        'musicDescriptionShelfRenderer',
      ).firstOrNull;
      final text = _runsText(_path(shelf, ['description']));
      if (text == null || text.trim().isEmpty) return null;
      // "Source: LyricFind" (in the request's language): keep the name.
      final source = _runsText(
        _path(shelf, ['footer']),
      )?.replaceFirst(RegExp(r'^[^:]*:\s*'), '').trim();
      return _withSource(
        text,
        source == null || source.isEmpty ? 'YouTube Music' : source,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Object?> _ytmPost(String endpoint, Map<String, Object> body) async {
    final response = await _client
        .post(
          Uri.https('music.youtube.com', '/youtubei/v1/$endpoint', {
            'prettyPrint': 'false',
          }),
          headers: const {
            'Content-Type': 'application/json',
            'Origin': 'https://music.youtube.com',
            'User-Agent': 'Mozilla/5.0',
          },
          body: jsonEncode({'context': _ytmContext, ...body}),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) throw http.ClientException(endpoint);
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  // --- LRCLIB ----------------------------------------------------------------

  Future<String?> _fromLrclib(
    String artist,
    String title,
    Duration? duration,
  ) async {
    try {
      final exact = await _lrclibGet('/api/get', {
        'artist_name': artist,
        'track_name': title,
        if (duration != null && duration > Duration.zero)
          'duration': '${duration.inSeconds}',
      });
      final found = exact is Map ? _lrclibText(exact) : null;
      if (found != null) return found;

      final results = await _lrclibGet('/api/search', {
        'artist_name': artist,
        'track_name': title,
      });
      if (results is! List) return null;
      for (final item in results) {
        final text = item is Map ? _lrclibText(item) : null;
        if (text != null) return text;
      }
    } catch (_) {
      // Next source.
    }
    return null;
  }

  Future<Object?> _lrclibGet(String path, Map<String, String> query) async {
    final response = await _client
        .get(
          Uri.https('lrclib.net', path, query),
          headers: const {'User-Agent': _userAgent},
        )
        .timeout(_timeout);
    if (response.statusCode != 200) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  String? _lrclibText(Map item) {
    if (item['instrumental'] == true) return null;
    var text = item['plainLyrics'] as String?;
    if (text == null || text.trim().isEmpty) {
      // Only timed lyrics: drop the [mm:ss.xx] stamps.
      final synced = item['syncedLyrics'] as String?;
      text = synced?.replaceAll(RegExp(r'^\[[^\]]*\]\s?', multiLine: true), '');
    }
    if (text == null || text.trim().isEmpty) return null;
    return _withSource(text, 'LRCLIB');
  }

  // --- lyrics.ovh ------------------------------------------------------------

  Future<String?> _fromLyricsOvh(String artist, String title) async {
    try {
      final response = await _client
          .get(
            // Path segments keep accents and other non-ASCII letters intact.
            Uri(
              scheme: 'https',
              host: 'api.lyrics.ovh',
              pathSegments: ['v1', artist, title],
            ),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final text = json is Map ? json['lyrics'] as String? : null;
      if (text == null || text.trim().isEmpty) return null;
      return _withSource(text, 'lyrics.ovh');
    } catch (_) {
      return null;
    }
  }

  // --- helpers ---------------------------------------------------------------

  static String _withSource(String lyrics, String source) {
    final text = lyrics
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return '$text\n\n© $source';
  }

  static Iterable<Object?> _findAll(Object? node, String key) sync* {
    if (node is Map) {
      if (node.containsKey(key)) yield node[key];
      for (final value in node.values) {
        yield* _findAll(value, key);
      }
    } else if (node is List) {
      for (final value in node) {
        yield* _findAll(value, key);
      }
    }
  }

  static Object? _path(Object? node, List<String> keys) {
    var current = node;
    for (final key in keys) {
      if (current is! Map) return null;
      current = current[key];
    }
    return current;
  }

  static String? _runsText(Object? node) {
    final runs = node is Map ? node['runs'] : null;
    if (runs is! List) return null;
    return runs.map((r) => r is Map ? r['text'] ?? '' : '').join();
  }
}

/// Artist and title to search lyrics by.
typedef LyricsQuery = ({String artist, String title});

/// Turns a YouTube-style artist and title into a lyrics search, or null if
/// nothing usable is left.
///
/// "Như Một Người Rưng - Chủ Tịch Mai x Giám Đốc Hà | Official M/V" by "OSAD"
/// becomes "Như Một Người Rưng" by "OSAD"; "Hozier - Swan Upon Leda (Official
/// Video)" by "HozierVEVO" becomes "Swan Upon Leda" by "Hozier".
LyricsQuery? lyricsQuery({required String? artist, required String title}) {
  var a = (artist ?? '').trim();
  a = a.replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '');
  a = a.replaceAll(RegExp(r'VEVO$'), '').trim();
  // The main artist only.
  a = a.split(RegExp(r',|&|\s+x\s+|\s+feat\.?\s+|\s+ft\.?\s+')).first.trim();

  // Everything after a pipe is channel or series noise.
  var t = title.split('|').first;
  t = formatSongTitle(t);
  t = t.replaceAll(RegExp(r'\b(?:M/V|MV)\b', caseSensitive: false), '');

  final dash = RegExp(r'\s+[-–—]\s+').firstMatch(t);
  if (dash != null) {
    final left = t.substring(0, dash.start).trim();
    final right = t.substring(dash.end).trim();
    final leftIsArtist =
        a.isNotEmpty && left.toLowerCase().contains(a.toLowerCase());
    if (leftIsArtist) {
      t = right;
    } else if (a.isEmpty) {
      // "Artist - Title" with no artist given.
      a = left;
      t = right;
    } else {
      // "Title - Credits", common for Vietnamese releases.
      t = left;
    }
  }

  // Featured artists don't belong in the title.
  t = t.replaceAll(
    RegExp(r'\s*[\(\[]?\b(?:feat|ft)\.?\s.*$', caseSensitive: false),
    '',
  );
  t = t.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  t = t.replaceAll(RegExp(r'^[-–—\s]+|[-–—\s]+$'), '');

  if (a.isEmpty || t.isEmpty) return null;
  return (artist: a, title: t);
}
