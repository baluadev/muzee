// Autoplay picks songs, not reactions or episodes, and skips what was just
// heard; YouTube Music's radio is read from its "next" answer.

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muzee/services/autoplay_picker.dart';
import 'package:muzee/services/taste_profile.dart';
import 'package:muzee/services/youtube_music_api.dart';

void main() {
  group('isLikelySong', () {
    test('keeps ordinary songs', () {
      expect(
        isLikelySong(
          title: 'Too Cute To Be Lonely',
          duration: const Duration(minutes: 4),
        ),
        isTrue,
      );
      expect(isLikelySong(title: 'Nàng Thơ (Remix)'), isTrue);
    });

    test('drops reactions, episodes and other non-songs', () {
      for (final title in [
        'Chairman Mai x Director Ha | QNT Reaction',
        'HÀ AN HUY ĐI XIN VIỆC EP19',
        'OSAD GOES JOB HUNTING EP22',
        'Rap Việt Tập 5',
        'Hozier interview 2024',
        'Lo-fi beats 3 hours',
        'Official Trailer',
      ]) {
        expect(isLikelySong(title: title), isFalse, reason: title);
      }
    });

    test('drops videos too short or too long for a song', () {
      expect(
        isLikelySong(title: 'Song', duration: const Duration(seconds: 30)),
        isFalse,
      );
      expect(
        isLikelySong(title: 'Song', duration: const Duration(minutes: 37)),
        isFalse,
      );
    });
  });

  group('YouTube Music radio', () {
    Map<String, Object> item(
      String id,
      String title,
      String length, {
      String artist = 'Holly Humberstone',
    }) => {
      'playlistPanelVideoRenderer': {
        'videoId': id,
        'title': {
          'runs': [
            {'text': title},
          ],
        },
        'lengthText': {
          'runs': [
            {'text': length},
          ],
        },
        'longBylineText': {
          'runs': [
            {'text': artist},
            {'text': ' • '},
            {'text': 'Paint My Bedroom Black'},
          ],
        },
      },
    };

    AutoplayPicker picker(List<Map<String, Object>> items, {Random? random}) =>
        AutoplayPicker(
          random: random ?? Random(1),
          ytm: YouTubeMusicApi(
            client: MockClient((request) async {
              expect(request.url.path, '/youtubei/v1/next');
              final body = jsonDecode(request.body) as Map;
              expect(body['playlistId'], 'RDAMVM${body['videoId']}');
              return http.Response.bytes(
                utf8.encode(
                  jsonEncode({
                    'contents': {'playlist': items},
                  }),
                ),
                200,
              );
            }),
          ),
        );

    test('picks a song that is neither playing nor excluded', () async {
      final song = await picker([
        item('current0000', 'Can You Afford To Lose Me?', '4:03'),
        item('heard000000', 'The Walls Are Way Too Thin', '3:21'),
        item('reaction000', 'Holly Humberstone Reaction', '12:40'),
        item('pick0000000', 'Too Cute To Be Lonely', '3:05'),
      ]).fromYouTubeMusicRadio('current0000', {'heard000000'});

      expect(song, isNotNull);
      expect(song!['ytid'], 'pick0000000');
      expect(song['title'], 'Too Cute To Be Lonely');
      expect(song['artist'], 'Holly Humberstone');
      expect(song['duration'], 185);
      expect(song['image'], contains('pick0000000'));
    });

    test('taste lifts a liked artist over closer songs', () async {
      final items = [
        item('close000001', 'Close One', '3:00'),
        item('close000002', 'Close Two', '3:00'),
        item('close000003', 'Close Three', '3:00'),
        item('close000004', 'Close Four', '3:00'),
        item('liked000000', 'Far But Loved', '3:00', artist: 'Luke Combs'),
      ];
      final taste = TasteSnapshot.test(liked: {'lukecombs': 20});

      final ranked = await picker(
        items,
        random: _AlwaysFirst(),
      ).fromYouTubeMusicRadio('current0000', {}, taste: taste);
      expect(ranked!['ytid'], 'liked000000');

      final plain = await picker(
        items,
        random: _AlwaysFirst(),
      ).fromYouTubeMusicRadio('current0000', {});
      expect(plain!['ytid'], 'close000001');
    });

    test('songs the listener skipped before sink', () async {
      final taste = TasteSnapshot.test(skippedSongs: {'close000001': 3});
      final song = await picker(
        [
          item('close000001', 'Close One', '3:00'),
          item('close000002', 'Close Two', '3:00'),
        ],
        random: _AlwaysFirst(),
      ).fromYouTubeMusicRadio('current0000', {}, taste: taste);
      expect(song!['ytid'], 'close000002');
    });

    test('nothing suitable: null', () async {
      final song = await picker([
        item('reaction000', 'Holly Humberstone Reaction', '12:40'),
      ]).fromYouTubeMusicRadio('current0000', {});
      expect(song, isNull);
    });
  });
}

/// Always picks the best-ranked candidate.
class _AlwaysFirst implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
