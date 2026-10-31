import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/utilities/formatter.dart';
import 'package:muzee/utilities/song_filtering.dart';
import 'package:muzee/utilities/sort_utils.dart';
import 'package:tuber_playback/tuber_playback.dart';

void main() {
  group('formatSongTitle', () {
    test('removes bracketed noise terms', () {
      expect(formatSongTitle('Song (Official Video)'), 'Song');
      expect(formatSongTitle('Song [Official Audio]'), 'Song');
    });

    test('removes trailing unbracketed noise', () {
      expect(formatSongTitle('Song - Official Audio'), 'Song');
    });

    test('decodes common HTML entities', () {
      expect(formatSongTitle('Tom &amp; Jerry'), 'Tom & Jerry');
    });

    test('collapses repeated whitespace', () {
      expect(formatSongTitle('Hello   World'), 'Hello World');
    });

    test('keeps ordinary titles unchanged', () {
      expect(formatSongTitle('Yesterday'), 'Yesterday');
    });
  });

  group('formatDuration', () {
    test('formats seconds as mm:ss', () {
      expect(formatDuration(0), '00:00');
      expect(formatDuration(65), '01:05');
    });

    test('includes hours only when needed', () {
      expect(formatDuration(3661), '01:01:01');
    });
  });

  group('sortSongsByKey', () {
    test('sorts case-insensitively', () {
      final songs = <dynamic>[
        {'title': 'banana'},
        {'title': 'Apple'},
        {'title': 'cherry'},
      ];
      sortSongsByKey(songs, 'title');
      expect(songs.map((s) => s['title']), ['Apple', 'banana', 'cherry']);
    });

    test('treats a missing key as an empty string', () {
      final songs = <dynamic>[
        {'title': 'b'},
        <String, dynamic>{},
      ];
      sortSongsByKey(songs, 'title');
      expect(songs.first.containsKey('title'), isFalse);
    });
  });

  group('filterSongsByQuery', () {
    final songs = <dynamic>[
      {'title': 'Yesterday', 'artist': 'The Beatles'},
      {'title': 'Hello', 'artist': 'Adele'},
    ];

    test('returns the original list for an empty query', () {
      expect(identical(filterSongsByQuery(songs, ''), songs), isTrue);
    });

    test('matches title or artist, ignoring case', () {
      expect(filterSongsByQuery(songs, 'YESTER').length, 1);
      expect(filterSongsByQuery(songs, 'adele').length, 1);
    });

    test('returns an empty list when nothing matches', () {
      expect(filterSongsByQuery(songs, 'zzz'), isEmpty);
    });
  });

  group('looksLikeSong', () {
    test('keeps normal and long tracks', () {
      expect(looksLikeSong(const Duration(minutes: 3, seconds: 55)), isTrue);
      expect(looksLikeSong(const Duration(minutes: 17)), isTrue);
      expect(looksLikeSong(maxSongLength), isTrue);
    });

    test('drops mixes and compilations', () {
      expect(looksLikeSong(const Duration(minutes: 27, seconds: 7)), isFalse);
      expect(looksLikeSong(const Duration(hours: 1, minutes: 22)), isFalse);
    });

    test('keeps videos with an unknown length', () {
      expect(looksLikeSong(null), isTrue);
    });
  });

  group('QueueEntryIdManager', () {
    test('nextId produces unique ids', () {
      final manager = QueueEntryIdManager();
      final ids = {for (var i = 0; i < 100; i++) manager.nextId()};
      expect(ids.length, 100);
      expect(ids.every((id) => id.startsWith('queue-')), isTrue);
    });

    test('ensureId keeps an existing id', () {
      final manager = QueueEntryIdManager();
      final song = {'queueEntryId': 'abc'};
      expect(manager.ensureId(song), 'abc');
      expect(song['queueEntryId'], 'abc');
    });

    test('ensureId assigns an id once and is idempotent', () {
      final manager = QueueEntryIdManager();
      final song = <String, dynamic>{'title': 'x'};
      final first = manager.ensureId(song);
      expect(manager.ensureId(song), first);
    });

    test('createSong copies the song without mutating the original', () {
      final manager = QueueEntryIdManager();
      final original = <String, dynamic>{'title': 'x'};
      final copy = manager.createSong(original);
      expect(copy['title'], 'x');
      expect(copy['queueEntryId'], isNotNull);
      expect(original.containsKey('queueEntryId'), isFalse);
    });
  });
}
