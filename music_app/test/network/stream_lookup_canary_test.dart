// Canary against real YouTube: does stream lookup still work, and is the
// fast path still the one that works? Skipped in normal runs (see
// dart_test.yaml); .github/workflows/stream-canary.yml runs it daily with
//   flutter test --tags network --run-skipped
//
// Note: CI runners use datacenter IPs, which YouTube sometimes treats as
// bots. A failure here is a signal to check on a phone, not proof that
// users are affected.
@Tags(['network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tuber_playback/tuber_playback.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Long-lived, widely available videos.
const _videos = {
  'dQw4w9WgXcQ': 'Never Gonna Give You Up',
  'kJQP7kiw5Fk': 'Despacito',
  '9bZkp7q19f0': 'Gangnam Style',
};

void main() {
  late YoutubeExplode yt;

  setUp(() => yt = YoutubeExplode());
  tearDown(() => yt.close());

  for (final entry in _videos.entries) {
    test(
      '${entry.value}: a lookup resolves playable streams',
      () async {
        final resolver = StreamManifestResolver(() => yt);
        final sw = Stopwatch()..start();

        final result = await resolver.resolve(entry.key);

        // ignore: avoid_print
        print(
          '${entry.value}: "${result.lookup}" in ${sw.elapsedMilliseconds} ms',
        );
        expect(
          result.manifest.muxed.isNotEmpty ||
              result.manifest.audioOnly.isNotEmpty,
          isTrue,
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      '${entry.value}: the fast lookup still works',
      () async {
        final resolver = StreamManifestResolver(
          () => yt,
          lookups: [defaultStreamLookups.first],
        );
        final sw = Stopwatch()..start();

        final result = await resolver.resolve(entry.key);

        expect(result.lookup.name, 'android');
        expect(
          sw.elapsed,
          lessThan(const Duration(seconds: 5)),
          reason: 'fast path got slow',
        );
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  }
}
