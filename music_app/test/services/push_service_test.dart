// What a push opens, read from its data, and the topics a device follows.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/services/firebase/push_service.dart';

import '../helpers/audio_test_harness.dart';

void main() {
  late Directory storage;
  setUpAll(() async => storage = await setUpTestStorage());
  tearDownAll(() => tearDownTestStorage(storage));

  group('push action', () {
    test('a songId plays that song', () {
      expect(
        PushAction.fromData({'songId': 'dQw4w9WgXcQ'}),
        const PlaySong('dQw4w9WgXcQ'),
      );
    });

    test('a playlistId or albumId opens its page', () {
      final playlist = PushAction.fromData({'playlistId': 'PLabc'});
      expect(playlist, const OpenPlaylist('PLabc'));
      expect((playlist! as OpenPlaylist).path, '/home/playlist/PLabc');
      expect(
        PushAction.fromData({'albumId': 'OLAK5uy_x'}),
        const OpenPlaylist('OLAK5uy_x'),
      );
    });

    test('a song wins over a playlist; blanks and nothing are ignored', () {
      expect(
        PushAction.fromData({'songId': 'abc', 'playlistId': 'PLx'}),
        const PlaySong('abc'),
      );
      expect(PushAction.fromData({'songId': '  '}), isNull);
      expect(PushAction.fromData({}), isNull);
    });
  });

  group('topics', () {
    test('everyone, the app language, and Premium or free', () {
      expect(pushTopicsFor(languageCode: 'vi', premium: false), {
        'all',
        'lang_vi',
        'free',
      });
      expect(pushTopicsFor(languageCode: 'EN', premium: true), {
        'all',
        'lang_en',
        'premium',
      });
    });
  });
}
