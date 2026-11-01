// The update prompt: which versions count as newer, and that it only
// appears on a browsing screen, never over the player, a video or an ad.

import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/services/firebase/remote_config_service.dart';
import 'package:muzee/services/router_service.dart';

void main() {
  group('isNewerVersion', () {
    test('compares part by part', () {
      expect(isNewerVersion('2.0.0', '2.0.1'), isTrue);
      expect(isNewerVersion('2.0.0', '2.1'), isTrue);
      expect(isNewerVersion('1.9.9', '2.0.0'), isTrue);
      expect(isNewerVersion('2.0.10', '2.0.9'), isFalse);
      expect(isNewerVersion('2.0.0', '2.0.0'), isFalse);
      expect(isNewerVersion('2.0', '2.0.0'), isFalse);
    });

    test('empty or odd versions never prompt', () {
      expect(isNewerVersion('2.0.0', ''), isFalse);
      expect(isNewerVersion('', '9.9.9'), isFalse);
      expect(isNewerVersion('2.0.0', '2.1-beta'), isFalse);
    });
  });

  group('when the prompt may show', () {
    bool can({
      String path = NavigationManager.homePath,
      bool playerOpen = false,
      bool video = false,
      bool ad = false,
      bool front = true,
    }) => canShowUpdatePrompt(
      path: path,
      playerOpen: playerOpen,
      videoFullscreen: video,
      adShowing: ad,
      appInFront: front,
    );

    test('on Home, Search and Library', () {
      expect(can(), isTrue);
      expect(can(path: NavigationManager.explorePath), isTrue);
      expect(can(path: NavigationManager.libraryPath), isTrue);
    });

    test('not deeper in, on the player, over a video or an ad', () {
      expect(can(path: NavigationManager.settingsPath), isFalse);
      expect(can(path: '${NavigationManager.homePath}/playlist/x'), isFalse);
      expect(can(playerOpen: true), isFalse);
      expect(can(video: true), isFalse);
      expect(can(ad: true), isFalse);
      expect(can(front: false), isFalse);
    });
  });
}
