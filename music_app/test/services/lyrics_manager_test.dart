// Lyrics: YouTube Music by video id first, then LRCLIB, then lyrics.ovh, each
// searched with a title cleaned of YouTube noise.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muzee/services/lyrics_manager.dart';

void main() {
  group('lyricsQuery', () {
    test('drops "Official M/V", credits after the title and the pipe', () {
      expect(
        lyricsQuery(
          artist: 'OSAD',
          title:
              'Như Một Người Rưng - Chủ Tịch Mai x Giám Đốc Hà | Official M/V',
        ),
        (artist: 'OSAD', title: 'Như Một Người Rưng'),
      );
    });

    test('drops a leading "Artist - " and the VEVO channel suffix', () {
      expect(
        lyricsQuery(
          artist: 'HozierVEVO',
          title: 'Hozier - Swan Upon Leda (Official Video)',
        ),
        (artist: 'Hozier', title: 'Swan Upon Leda'),
      );
    });

    test('takes the artist from the title when none is given', () {
      expect(lyricsQuery(artist: null, title: 'Queen - We Will Rock You'), (
        artist: 'Queen',
        title: 'We Will Rock You',
      ));
    });

    test('keeps the main artist and drops featured ones', () {
      expect(
        lyricsQuery(artist: 'Đen, MIN', title: 'Bài Này Chill Phết (ft. MIN)'),
        (artist: 'Đen', title: 'Bài Này Chill Phết'),
      );
      expect(lyricsQuery(artist: 'Joy Crookes - Topic', title: 'Forever'), (
        artist: 'Joy Crookes',
        title: 'Forever',
      ));
    });

    test('gives up when nothing usable is left', () {
      expect(lyricsQuery(artist: '', title: 'Official Video'), isNull);
    });
  });

  group('sources', () {
    late List<http.Request> requests;

    LyricsManager manager(
      Map<String, http.Response Function(http.Request)> on,
    ) {
      requests = [];
      return LyricsManager(
        client: MockClient((request) async {
          requests.add(request);
          for (final entry in on.entries) {
            if (request.url.toString().contains(entry.key)) {
              return entry.value(request);
            }
          }
          return http.Response('', 404);
        }),
      );
    }

    http.Response json(Object body) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

    final ytmNext = {
      'contents': {
        'tabs': [
          {
            'tabRenderer': {
              'endpoint': {
                'browseEndpoint': {'browseId': 'MPLYt_abc'},
              },
            },
          },
        ],
      },
    };
    final ytmBrowse = {
      'contents': {
        'sectionListRenderer': {
          'contents': [
            {
              'musicDescriptionShelfRenderer': {
                'description': {
                  'runs': [
                    {'text': 'Mùa thu mang giấc mơ quay về\nVẫn nguyên vẹn'},
                  ],
                },
                'footer': {
                  'runs': [
                    {'text': 'Source: LyricFind'},
                  ],
                },
              },
            },
          ],
        },
      },
    };

    test('YouTube Music answers first, by video id', () async {
      final lyrics = await manager({
        '/youtubei/v1/next': (_) => json(ytmNext),
        '/youtubei/v1/browse': (_) => json(ytmBrowse),
      }).fetchLyrics(videoId: 'abc', artist: 'Sơn Tùng M-TP', title: 'X');

      expect(lyrics, startsWith('Mùa thu mang giấc mơ quay về\n'));
      expect(lyrics, endsWith('© LyricFind'));
      final next = requests.first;
      expect((jsonDecode(next.body) as Map)['videoId'], 'abc');
      expect(requests.any((r) => r.url.host == 'lrclib.net'), isFalse);
    });

    test('without YouTube Music lyrics, LRCLIB is asked by name', () async {
      final lyrics =
          await manager({
            '/youtubei/v1/next': (_) => json({'contents': {}}),
            'lrclib.net/api/get': (_) => json({
              'plainLyrics': 'A husband waits outside',
              'syncedLyrics': '[00:12.00] A husband waits outside',
            }),
          }).fetchLyrics(
            videoId: 'abc',
            artist: 'HozierVEVO',
            title: 'Hozier - Swan Upon Leda (Official Video)',
            duration: const Duration(minutes: 3, seconds: 42),
          );

      expect(lyrics, 'A husband waits outside\n\n© LRCLIB');
      final get = requests.firstWhere((r) => r.url.path == '/api/get');
      expect(get.url.queryParameters, {
        'artist_name': 'Hozier',
        'track_name': 'Swan Upon Leda',
        'duration': '222',
      });
      expect(get.headers['User-Agent'], contains('Muzee'));
    });

    test(
      'LRCLIB search is the fallback; timed-only lyrics lose stamps',
      () async {
        final lyrics = await manager({
          'lrclib.net/api/search': (_) => json([
            {'instrumental': true},
            {'syncedLyrics': '[00:01.00] Line one\n[00:02.50] Line two'},
          ]),
        }).fetchLyrics(artist: 'Queen', title: 'We Will Rock You');

        expect(lyrics, 'Line one\nLine two\n\n© LRCLIB');
      },
    );

    test('lyrics.ovh is last, with accents kept in the URL', () async {
      final lyrics = await manager({
        'api.lyrics.ovh': (_) => json({'lyrics': 'Em ngày em đánh rơi'}),
      }).fetchLyrics(artist: 'Hoàng Dũng', title: 'Nàng Thơ');

      expect(lyrics, 'Em ngày em đánh rơi\n\n© lyrics.ovh');
      final ovh = requests.firstWhere((r) => r.url.host == 'api.lyrics.ovh');
      expect(ovh.url.pathSegments, ['v1', 'Hoàng Dũng', 'Nàng Thơ']);
    });

    test('a failing source is skipped, not fatal', () async {
      final lyrics = await manager({
        '/youtubei/v1/next': (_) => throw http.ClientException('offline'),
        'lrclib.net': (_) => http.Response('error code: 502', 502),
        'api.lyrics.ovh': (_) => json({'lyrics': 'Found it'}),
      }).fetchLyrics(videoId: 'abc', artist: 'Joy Crookes', title: 'Forever');

      expect(lyrics, 'Found it\n\n© lyrics.ovh');
    });

    test('no source has them: null', () async {
      final lyrics = await manager({}).fetchLyrics(
        videoId: 'abc',
        artist: 'OSAD',
        title: 'Như Một Người Rưng',
      );
      expect(lyrics, isNull);
    });
  });
}
