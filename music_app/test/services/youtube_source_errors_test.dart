// API-001: the YouTube source returns an error, times out, or hits quota.
// Expected: a friendly message, a retry, no crash.
//
// The fake network (test/helpers/fake_youtube_http.dart) stands in for
// YouTube. These are testWidgets so youtube_explode's retry delays and the
// app's 30 s manifest timeout run on the fake clock.

import 'dart:async';
import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/screens/playlist_page.dart';
import 'package:muzee/screens/search/search_controller.dart' as search;
import 'package:muzee/screens/search/search_mobile_view.dart';
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/neo/neo_theme.dart';
import 'package:muzee/utilities/async_loader.dart';
import 'package:muzee/widgets/load_error_view.dart';
import 'package:muzee/widgets/moods.dart';
import 'package:tuber_playback/tuber_playback.dart';

import '../helpers/audio_test_harness.dart';
import '../helpers/fake_youtube_http.dart';

void main() {
  late Directory storage;
  final http = FakeYouTubeHttp();
  final en = lookupAppLocalizations(const Locale('en'));
  var nextVideo = 0;

  /// A fresh 11-character video id, so cached stream URLs never leak
  /// between tests.
  String newVideoId() => 'api_${(nextVideo++).toString().padLeft(7, '0')}';

  /// Advances the fake clock in 1 s steps until [future] completes or
  /// [limit] passes. Returns the value and the fake time it took.
  Future<({T value, Duration elapsed})> resolve<T>(
    WidgetTester tester,
    Future<T> future, {
    Duration limit = const Duration(minutes: 3),
  }) async {
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
    var elapsed = Duration.zero;
    while (!done && elapsed < limit) {
      await tester.pump(const Duration(seconds: 1));
      elapsed += const Duration(seconds: 1);
    }
    if (error != null) Error.throwWithStackTrace(error!, stack!);
    expect(done, isTrue, reason: 'still running after $limit');
    return (value: value, elapsed: elapsed);
  }

  /// Lets background work (retries, recently-played lookups) finish so no
  /// fake timers are left pending when the test ends.
  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  /// A tappable control labelled retry / try again (text alone, like the
  /// generic "...or try again." error string, does not count).
  Finder retryButton() => find.ancestor(
    of: find.textContaining(RegExp('retry|try again', caseSensitive: false)),
    matching: find.byWidgetPredicate(
      (w) => w is ButtonStyleButton || w is IconButton,
    ),
  );

  Widget app(Widget home) => MaterialApp(
    theme: buildNeoTheme(NeoThemeVariant.dark),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  setUpAll(() async {
    storage = await setUpTestStorage();
    HttpOverrides.global = http;
  });

  tearDownAll(() => tearDownTestStorage(storage));

  setUp(() {
    http
      ..requests.clear()
      ..responder = (_) => const FakeReply.socketError();
    streamManifestResolver.clearRejections();
  });

  group('stream lookup', () {
    testWidgets('network down: resolves to no stream, no exception', (
      tester,
    ) async {
      http.responder = (_) => const FakeReply.socketError();

      final result = await resolve(
        tester,
        fetchSongStreamInfo(newVideoId(), false),
      );

      expect(result.value, isNull);
      expect(http.requests.length, greaterThan(2), reason: 'retried');
      expect(
        http.requests.length,
        lessThan(100),
        reason: 'retries are bounded',
      );
      expect(
        result.elapsed,
        lessThan(const Duration(seconds: 10)),
        reason: 'fails fast',
      );
      expect(
        http.requests.where((r) => r.url.path == '/watch'),
        isEmpty,
        reason: 'no slow full lookup on top of a network failure',
      );
      await drain(tester);
    });

    testWidgets(
      'quota exceeded (HTTP 429): resolves to no stream, no exception',
      (tester) async {
        http.responder = (_) => FakeReply.status(429, 'quota exceeded');

        final result = await resolve(
          tester,
          fetchSongStreamInfo(newVideoId(), false),
        );

        expect(result.value, isNull);
        expect(http.requests.length, greaterThan(2), reason: 'retried');
        expect(
          http.requests.length,
          lessThan(100),
          reason: 'retries are bounded',
        );
        await drain(tester);
      },
    );

    testWidgets(
      'server error (HTTP 503): resolves to no stream, no exception',
      (tester) async {
        http.responder = (_) => FakeReply.status(503);

        final result = await resolve(
          tester,
          fetchSongStreamInfo(newVideoId(), false),
        );

        expect(result.value, isNull);
        await drain(tester);
      },
    );

    testWidgets('no response: gives up after the 15 s timeout with no stream', (
      tester,
    ) async {
      http.responder = (_) => const FakeReply.hang();
      var done = false;
      StreamPlaybackInfo? info;
      unawaited(
        fetchSongStreamInfo(newVideoId(), false).then((v) {
          info = v;
          done = true;
        }),
      );

      await tester.pump(const Duration(seconds: 14));
      expect(done, isFalse, reason: 'still waiting before the timeout');

      // A timeout means the network is the problem; the slow full lookup is
      // not tried on top of it.
      await tester.pump(const Duration(seconds: 2));
      expect(done, isTrue);
      expect(info, isNull);
    });

    testWidgets(
      'a one-off server error is retried and the song still resolves',
      (tester) async {
        final id = newVideoId();
        final healthy = youtubeResponder(player: playerOkReply);
        var failedOnce = false;
        http.responder = (request) {
          if (!failedOnce && request.playerVideoId != null) {
            failedOnce = true;
            return FakeReply.status(503);
          }
          return healthy(request);
        };

        final result = await resolve(tester, fetchSongStreamInfo(id, false));

        expect(failedOnce, isTrue);
        expect(result.value?.url, streamUrlFor(id));
        await drain(tester);
      },
    );

    testWidgets(
      'after a failure, trying again succeeds once YouTube recovers',
      (tester) async {
        final id = newVideoId();
        http.responder = (_) => FakeReply.status(429);
        final failed = await resolve(tester, fetchSongStreamInfo(id, false));
        expect(failed.value, isNull);

        http.responder = youtubeResponder(player: playerOkReply);
        final retried = await resolve(tester, fetchSongStreamInfo(id, false));

        expect(
          retried.value?.url,
          streamUrlFor(id),
          reason: 'the failure was not cached',
        );
        expect(retried.value?.isVideo, isTrue);
        await drain(tester);
      },
    );
  });

  group('fast stream lookup', () {
    testWidgets(
      'resolves with one ANDROID player request, without the watch page',
      (tester) async {
        final id = newVideoId();
        http.responder = youtubeResponder(player: playerOkReply);

        final result = await resolve(tester, fetchSongStreamInfo(id, false));

        expect(result.value?.url, streamUrlFor(id));
        // After success the app looks up song details in the background (watch
        // page); the stream lookup itself must come first and be one request.
        final forThisSong = http.requests
            .where(
              (r) => r.playerVideoId == id || r.url.queryParameters['v'] == id,
            )
            .toList();
        expect(forThisSong.first.playerClientName, 'ANDROID');
        expect(forThisSong.first.url.path, '/youtubei/v1/player');
        await drain(tester);
      },
    );

    testWidgets(
      'falls back to the full lookup when YouTube rejects the fast one',
      (tester) async {
        final id = newVideoId();
        final healthy = youtubeResponder(player: playerOkReply);
        http.responder = (request) => request.playerClientName == 'ANDROID'
            ? playerUnplayableReply(
                'LOGIN_REQUIRED',
                "Sign in to confirm you're not a bot",
              )
            : healthy(request);

        final result = await resolve(tester, fetchSongStreamInfo(id, false));

        expect(
          result.value?.url,
          streamUrlFor(id),
          reason: 'ANDROID_VR via the full lookup',
        );
        expect(
          http.requests
              .where((r) => r.playerVideoId == id)
              .map((r) => r.playerClientName),
          containsAllInOrder(['ANDROID', 'ANDROID_VR']),
        );
        expect(http.requests.where((r) => r.url.path == '/watch'), isNotEmpty);
        await drain(tester);
      },
    );
  });

  group('search', () {
    testWidgets(
      'network down: the song search fails loudly, not as "no results"',
      (tester) async {
        Object? error;
        try {
          await resolve(tester, fetchSongsList('lofi beats'));
        } catch (e) {
          error = e;
        }

        expect(error, isA<Exception>());
        await drain(tester);
      },
    );

    testWidgets('network down: suggestions are just empty', (tester) async {
      final result = await resolve(tester, getSearchSuggestions('lofi'));

      expect(result.value, isEmpty);
      await drain(tester);
    });

    testWidgets(
      'search page with the network down shows a friendly error with a retry',
      (tester) async {
        final controller = search.SearchController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(app(SearchMobileView(controller: controller)));

        controller.searchBar.text = 'lofi beats';
        await resolve(tester, controller.submitSearch());
        await tester.pumpAndSettle();

        expect(controller.fetchingSongs.value, isFalse);
        expect(controller.searchFailed.value, isTrue);
        expect(find.text(en.searchFailed), findsOneWidget);
        expect(retryButton(), findsOneWidget);
        expect(tester.takeException(), isNull);

        final requestsBefore = http.requests.length;
        await tester.tap(retryButton());
        await tester.pump();
        for (var i = 0; i < 30 && controller.fetchingSongs.value; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        expect(
          http.requests.length,
          greaterThan(requestsBefore),
          reason: 'searched again',
        );
        await drain(tester);
      },
    );

    testWidgets('typing again clears the search error', (tester) async {
      final controller = search.SearchController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(app(SearchMobileView(controller: controller)));
      controller.searchBar.text = 'lofi beats';
      await resolve(tester, controller.submitSearch());
      expect(controller.searchFailed.value, isTrue);

      await tester.enterText(find.byType(TextField), 'lofi');
      await tester.pump();

      expect(controller.searchFailed.value, isFalse);
      expect(find.text(en.searchFailed), findsNothing);
      await drain(tester);
    });

    testWidgets(
      'typing a query with the network down does not raise an unhandled error',
      (tester) async {
        final controller = search.SearchController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(app(SearchMobileView(controller: controller)));

        await tester.enterText(find.byType(TextField), 'lofi');
        await drain(tester); // past the 300 ms suggestions debounce + retries

        expect(tester.takeException(), isNull);
        expect(controller.suggestionsList.value, isEmpty);
      },
    );
  });

  group('search suggestions', () {
    Finder iconInRow(String text, IconData icon) => find.descendant(
      of: find.ancestor(of: find.text(text), matching: find.byType(Row)).first,
      matching: find.byIcon(icon),
    );

    testWidgets('suggestions look like searches, not like removable history', (
      tester,
    ) async {
      search.searchHistoryNotifier.value = ['old query'];
      final controller = search.SearchController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(app(SearchMobileView(controller: controller)));
      await tester.pump();

      expect(
        iconInRow('old query', FluentIcons.history_24_regular),
        findsOneWidget,
      );
      expect(
        iconInRow('old query', FluentIcons.dismiss_24_regular),
        findsOneWidget,
      );

      controller.suggestionsList.value = ['lofi beats'];
      await tester.pump();

      expect(
        iconInRow('lofi beats', FluentIcons.search_24_regular),
        findsOneWidget,
      );
      expect(
        iconInRow('lofi beats', FluentIcons.history_24_regular),
        findsNothing,
      );
      expect(
        iconInRow('lofi beats', FluentIcons.dismiss_24_regular),
        findsNothing,
      );
    });
  });

  group('playlist page', () {
    const playlistId = 'PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx';

    Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
      for (var i = 0; i < 120 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    }

    testWidgets(
      'network down: shows a friendly error with Retry, not an empty playlist',
      (tester) async {
        // A Pixel 7 sized screen (411 x 914 dp).
        tester.view
          ..physicalSize = const Size(1080, 2400)
          ..devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          app(
            const PlaylistPage(
              playlistData: {
                'ytid': playlistId,
                'title': 'Offline mix',
                'image': null,
              },
            ),
          ),
        );
        await pumpUntilFound(tester, find.byType(LoadErrorView));

        expect(find.text(en.loadFailed), findsOneWidget);
        expect(find.text(en.noSongsInPlaylist), findsNothing);
        expect(find.text('Offline mix'), findsWidgets, reason: 'header kept');
        expect(tester.takeException(), isNull);

        final requestsBefore = http.requests.length;
        // On a phone the error sits below the header; scroll to it like a user.
        await tester.ensureVisible(retryButton());
        await tester.pump();
        await tester.tap(retryButton());
        await tester.pump();
        await pumpUntilFound(tester, find.byType(LoadErrorView));

        expect(
          http.requests.length,
          greaterThan(requestsBefore),
          reason: 'fetched again',
        );
        expect(find.text(en.loadFailed), findsOneWidget);
        await drain(tester);
      },
    );
  });

  group('browse screens', () {
    Widget failingSection(
      Completer<List<dynamic>> failing, {
      Future<List<dynamic>> Function()? onRetry,
    }) => app(
      Scaffold(
        body: AsyncLoader<List<dynamic>>(
          future: failing.future,
          onRetry: onRetry,
          builder: (_, items) => Text('loaded ${items.length}'),
        ),
      ),
    );

    testWidgets('a failed section shows a friendly error instead of crashing', (
      tester,
    ) async {
      final failing = Completer<List<dynamic>>();
      await tester.pumpWidget(failingSection(failing));
      failing.completeError(const SocketException('Failed host lookup'));
      await tester.pumpAndSettle();

      expect(find.textContaining('loaded'), findsNothing);
      expect(find.text(en.loadFailed), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);
      expect(retryButton(), findsNothing, reason: 'no onRetry given');
    });

    testWidgets(
      'a failed section with onRetry offers a retry that reloads it',
      (tester) async {
        final failing = Completer<List<dynamic>>();
        var retries = 0;
        await tester.pumpWidget(
          failingSection(
            failing,
            onRetry: () async {
              retries++;
              return ['a', 'b'];
            },
          ),
        );
        failing.completeError(const SocketException('Failed host lookup'));
        await tester.pumpAndSettle();
        expect(retryButton(), findsOneWidget);

        await tester.tap(retryButton());
        await tester.pumpAndSettle();

        expect(retries, 1);
        expect(find.text('loaded 2'), findsOneWidget);
      },
    );

    testWidgets(
      'moods & genres with YouTube over quota shows a friendly error and retries',
      (tester) async {
        http.responder = (_) => FakeReply.status(429, '{"error":{"code":429}}');

        Moods.reset();
        await tester.pumpWidget(
          app(
            const Scaffold(body: CustomScrollView(slivers: [BrowseAllMoods()])),
          ),
        );
        await resolve(tester, Future<void>.delayed(const Duration(seconds: 2)));
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text(en.loadFailed), findsOneWidget);
        expect(find.textContaining('Exception'), findsNothing);
        expect(find.textContaining('429'), findsNothing);
        expect(tester.takeException(), isNull);

        // YouTube recovers; Retry loads the page again.
        http.responder = (_) => FakeReply.ok('{}');
        await tester.tap(retryButton());
        await resolve(tester, Future<void>.delayed(const Duration(seconds: 2)));
        await tester.pumpAndSettle();

        // Nothing to browse: the section just isn't there.
        expect(find.text(en.loadFailed), findsNothing);
        expect(find.text(en.browseAll), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
