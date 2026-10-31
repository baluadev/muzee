// StreamManifestResolver: lookup order, early exit, cooldown after a
// rejection, and no retries where they can't help. testWidgets so
// youtube_explode's retry delays run on the fake clock.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuber_playback/tuber_playback.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../helpers/audio_test_harness.dart';
import '../helpers/fake_youtube_http.dart';

void main() {
  late Directory storage;
  final http = FakeYouTubeHttp();
  late YoutubeExplode yt;
  var now = DateTime(2026, 10, 30, 12);
  var nextVideo = 0;

  String newVideoId() => 'res_${(nextVideo++).toString().padLeft(7, '0')}';

  StreamManifestResolver newResolver() =>
      StreamManifestResolver(() => yt, now: () => now);

  Iterable<String?> playerClients(String id) => http.requests
      .where((r) => r.playerVideoId == id)
      .map((r) => r.playerClientName);

  /// Runs [future] on the fake clock until it completes.
  Future<T> run<T>(WidgetTester tester, Future<T> future) async {
    var done = false;
    late T value;
    Object? error;
    StackTrace? stack;
    future.then(
      (v) {
        value = v;
        done = true;
      },
      onError: (Object e, StackTrace s) {
        error = e;
        stack = s;
        done = true;
      },
    );
    for (var i = 0; i < 120 && !done; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    if (error != null) Error.throwWithStackTrace(error!, stack!);
    expect(done, isTrue);
    return value;
  }

  setUpAll(() async {
    storage = await setUpTestStorage();
    HttpOverrides.global = http;
  });

  tearDownAll(() => tearDownTestStorage(storage));

  setUp(() {
    http.requests.clear();
    yt = YoutubeExplode();
  });

  tearDown(() => yt.close());

  testWidgets('stops at the first lookup that works', (tester) async {
    final id = newVideoId();
    http.responder = youtubeResponder(player: playerOkReply);

    final result = await run(tester, newResolver().resolve(id));

    expect(result.lookup.name, 'android');
    expect(playerClients(id), ['ANDROID'], reason: 'no other client queried');
    expect(http.requests.where((r) => r.url.path == '/watch'), isEmpty);
  });

  testWidgets(
    'a rejected lookup goes last for the cooldown, then first again',
    (tester) async {
      final healthy = youtubeResponder(player: playerOkReply);
      http.responder = (r) =>
          r.playerClientName == 'ANDROID' && !r.body.contains('playbackContext')
          ? playerUnplayableReply(
              'LOGIN_REQUIRED',
              "Sign in to confirm you're not a bot",
            )
          : healthy(r);
      final resolver = newResolver();

      final first = newVideoId();
      final firstResult = await run(tester, resolver.resolve(first));
      expect(firstResult.lookup.name, 'android_vr+watch');
      expect(playerClients(first), ['ANDROID', 'ANDROID_VR']);
      expect(resolver.order.map((l) => l.name), [
        'android_vr+watch',
        'android+watch',
        'android',
      ]);

      final second = newVideoId();
      await run(tester, resolver.resolve(second));
      expect(
        playerClients(second).first,
        'ANDROID_VR',
        reason: 'skips the rejected fast lookup',
      );

      now = now.add(const Duration(minutes: 31));
      expect(resolver.order.first.name, 'android', reason: 'cooldown over');
    },
  );

  testWidgets(
    'a 403 on the stream probe moves on without retrying that lookup',
    (tester) async {
      final id = newVideoId();
      final blockedUrl =
          'https://rr1---sn-blocked.googlevideo.com/videoplayback?id=$id';
      final healthy = youtubeResponder(player: playerOkReply);
      http.responder = (r) {
        if (r.method == 'HEAD' && r.url.toString() == blockedUrl) {
          return FakeReply.status(403);
        }
        if (r.playerClientName == 'ANDROID')
          return playerOkReply(id, url: blockedUrl);
        return healthy(r);
      };

      final result = await run(tester, newResolver().resolve(id));

      expect(result.lookup.name, 'android_vr+watch');
      expect(
        http.requests.where(
          (r) => r.method == 'HEAD' && r.url.toString() == blockedUrl,
        ),
        hasLength(1),
        reason: 'not retried 5 times',
      );
      expect(playerClients(id).where((c) => c == 'ANDROID'), hasLength(1));
    },
  );

  testWidgets('a network failure stops the search', (tester) async {
    final id = newVideoId();
    http.responder = (_) => const FakeReply.socketError();

    Object? error;
    try {
      await run(tester, newResolver().resolve(id));
    } catch (e) {
      error = e;
    }
    expect(error, isA<Exception>());

    expect(playerClients(id).toSet(), {
      'ANDROID',
    }, reason: 'no other lookup tried');
    expect(http.requests.where((r) => r.url.path == '/watch'), isEmpty);
  });

  testWidgets('rate limiting stops the search', (tester) async {
    final id = newVideoId();
    http.responder = (_) => FakeReply.status(429);

    Object? error;
    try {
      await run(tester, newResolver().resolve(id));
    } catch (e) {
      error = e;
    }
    expect(error, isA<RequestLimitExceededException>());

    expect(playerClients(id).toSet(), {'ANDROID'});
  });

  testWidgets('when every lookup is rejected, the last error is thrown', (
    tester,
  ) async {
    final id = newVideoId();
    http.responder = youtubeResponder(
      player: (_) =>
          playerUnplayableReply('UNPLAYABLE', 'Not available in your country'),
    );

    Object? error;
    try {
      await run(tester, newResolver().resolve(id));
    } catch (e) {
      error = e;
    }
    expect(error, isA<VideoUnplayableException>());

    expect(playerClients(id), ['ANDROID', 'ANDROID_VR', 'ANDROID']);
  });
}
