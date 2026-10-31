// The full player's route: it opens and closes by itself, and follows a
// finger both ways, finishing the move past half way or on a fling and
// springing back otherwise.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/main.dart' show audioHandler;
import 'package:muzee/screens/now_playing_route.dart';
import 'package:muzee/widgets/now_playing/now_playing_drag_opener.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/neo/neo_theme.dart';

import '../helpers/audio_test_harness.dart';
import '../helpers/fake_youtube_http.dart';

void main() {
  late Directory storage;
  late TestAudioHandler handler;
  final navKey = GlobalKey<NavigatorState>();
  Widget fakePage(BuildContext _) => const _FakePlayer();

  setUpAll(() async {
    storage = await setUpTestStorage();
    HttpOverrides.global = FakeYouTubeHttp();
    offlineMode.value = true;
    handler = TestAudioHandler.create();
    audioHandler = handler;
  });

  tearDownAll(() async {
    handler.retire();
    await tearDownTestStorage(storage);
  });

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      navigatorKey: navKey,
      theme: buildNeoTheme(NeoThemeVariant.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('home')),
    ),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  double pageTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(_FakePlayer)).dy;

  testWidgets('opens and closes on its own', (tester) async {
    await pumpApp(tester);
    navKey.currentState!.push(NowPlayingRoute(pageBuilder: fakePage));
    await settle(tester);
    expect(pageTop(tester), 0);

    navKey.currentState!.pop();
    await settle(tester);
    expect(find.byType(_FakePlayer), findsNothing);
  });

  testWidgets('a slow, short drag down springs back', (tester) async {
    await pumpApp(tester);
    navKey.currentState!.push(NowPlayingRoute(pageBuilder: fakePage));
    await settle(tester);

    await tester.timedDrag(
      find.byType(_FakePlayer),
      const Offset(0, 120),
      const Duration(seconds: 1),
    );
    await settle(tester);
    expect(pageTop(tester), 0);
  });

  testWidgets('the page follows the finger while dragging down', (
    tester,
  ) async {
    await pumpApp(tester);
    navKey.currentState!.push(NowPlayingRoute(pageBuilder: fakePage));
    await settle(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, 40));
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();
    expect(pageTop(tester), closeTo(200, 1)); // 1:1 with the finger
    await gesture.up();
    await settle(tester);
  });

  testWidgets('dragging past half way closes it', (tester) async {
    await pumpApp(tester);
    navKey.currentState!.push(NowPlayingRoute(pageBuilder: fakePage));
    await settle(tester);

    final height =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    await tester.timedDrag(
      find.byType(_FakePlayer),
      Offset(0, height * 0.6),
      const Duration(seconds: 2),
    );
    await settle(tester);
    expect(find.byType(_FakePlayer), findsNothing);
  });

  testWidgets('a quick fling down closes it', (tester) async {
    await pumpApp(tester);
    navKey.currentState!.push(NowPlayingRoute(pageBuilder: fakePage));
    await settle(tester);

    await tester.fling(find.byType(_FakePlayer), const Offset(0, 150), 2000);
    await settle(tester);
    expect(find.byType(_FakePlayer), findsNothing);
  });

  testWidgets('taking over from a drag, it carries on from there', (
    tester,
  ) async {
    await pumpApp(tester);
    navKey.currentState!.push(
      NowPlayingRoute(initialValue: 0.7, pageBuilder: fakePage),
    );
    await tester.pump();
    await tester.pump();
    final height =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    // Starts where the preview was (30% of the page still below), no jump.
    expect(pageTop(tester), closeTo(height * 0.3, height * 0.05));
    await settle(tester);
    expect(pageTop(tester), 0);
    expect(navKey.currentState!.userGestureInProgress, isFalse);
  });

  group('drag up on the mini player', () {
    Future<void> pumpOpener(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        theme: buildNeoTheme(NeoThemeVariant.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: _OpenerHost(pageBuilder: fakePage),
          ),
        ),
      ),
    );

    testWidgets('the preview follows the finger, then the player opens', (
      tester,
    ) async {
      await pumpOpener(tester);
      final height =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final start = tester.getCenter(find.byKey(_OpenerHost.handle));

      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, -40));
      await gesture.moveBy(Offset(0, -height * 0.4));
      await tester.pump();
      final previewTop = tester.getTopLeft(find.byKey(_previewKey)).dy;
      expect(previewTop, closeTo(height * 0.6 - 40, 2));

      await gesture.moveBy(Offset(0, -height * 0.2));
      await gesture.up();
      await settle(tester);

      expect(find.byKey(_previewKey), findsNothing);
      expect(pageTop(tester), 0);
      expect(navKey.currentState!.userGestureInProgress, isFalse);
    });

    testWidgets('a short drag lets the preview fall back, opening nothing', (
      tester,
    ) async {
      await pumpOpener(tester);
      final start = tester.getCenter(find.byKey(_OpenerHost.handle));
      await tester.timedDragFrom(
        start,
        const Offset(0, -120),
        const Duration(seconds: 1),
      );
      await settle(tester);

      expect(find.byKey(_previewKey), findsNothing);
      expect(find.byType(_FakePlayer), findsNothing);
    });

    testWidgets('a quick flick up opens it', (tester) async {
      await pumpOpener(tester);
      final start = tester.getCenter(find.byKey(_OpenerHost.handle));
      await tester.flingFrom(start, const Offset(0, -120), 2000);
      await settle(tester);

      expect(find.byKey(_previewKey), findsNothing);
      expect(pageTop(tester), 0);
    });
  });
}

class _FakePlayer extends StatelessWidget {
  const _FakePlayer({super.key});

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: Colors.black, child: SizedBox.expand());
}

const _previewKey = ValueKey('preview');

/// A stand-in mini player: a bar that drives a [NowPlayingDragOpener].
class _OpenerHost extends StatefulWidget {
  const _OpenerHost({required this.pageBuilder});

  static const handle = ValueKey('handle');
  final WidgetBuilder pageBuilder;

  @override
  State<_OpenerHost> createState() => _OpenerHostState();
}

class _OpenerHostState extends State<_OpenerHost>
    with TickerProviderStateMixin {
  late final _opener = NowPlayingDragOpener(
    vsync: this,
    pageBuilder: widget.pageBuilder,
    preview: const _FakePlayer(key: _previewKey),
  );

  @override
  void dispose() {
    _opener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: _OpenerHost.handle,
    behavior: HitTestBehavior.opaque,
    onVerticalDragStart: (_) => _opener.start(context),
    onVerticalDragUpdate: (d) =>
        _opener.update(d.primaryDelta ?? 0, MediaQuery.sizeOf(context).height),
    onVerticalDragEnd: (d) => _opener.end(context, d.primaryVelocity ?? 0),
    onVerticalDragCancel: () => _opener.end(context, 0),
    child: const SizedBox(height: 64, width: double.infinity),
  );
}
