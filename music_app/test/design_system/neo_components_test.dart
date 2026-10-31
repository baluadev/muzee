import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/design_system/neo_design_system.dart';

Widget _host(
  Widget child, {
  NeoThemeVariant variant = NeoThemeVariant.dark,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: buildNeoTheme(variant),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: disableAnimations),
      child: app!,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('every component builds in every variant', (tester) async {
    for (final variant in NeoThemeVariant.values) {
      await tester.pumpWidget(
        _host(
          variant: variant,
          SingleChildScrollView(
            child: Column(
              children: [
                NeoButton(label: 'Play', onPressed: () {}),
                NeoIconButton(
                  icon: NeoIcons.more,
                  tooltip: 'More',
                  onPressed: () {},
                ),
                NeoPlayButton(
                  isPlaying: false,
                  onPressed: () {},
                  playLabel: 'Play',
                  pauseLabel: 'Pause',
                ),
                NeoChip(label: 'Chill', selected: true, onSelected: (_) {}),
                NeoSearchField(
                  controller: TextEditingController(),
                  hintText: 'Search',
                  clearLabel: 'Clear',
                ),
                const NeoSectionHeader(title: 'Trending'),
                const NeoMediaCard(title: 'Playlist'),
                const NeoSongTile(title: 'Song', subtitle: 'Artist'),
                const NeoListGroup(children: [NeoListRow(title: 'Row')]),
                const NeoBadge(label: 'Premium'),
                const NeoEmptyState(icon: NeoIcons.folder, title: 'Empty'),
                NeoMiniPlayer(
                  title: 'Song',
                  subtitle: 'Artist',
                  isPlaying: true,
                  onPlayPause: () {},
                  playLabel: 'Play',
                  pauseLabel: 'Pause',
                  progress: 0.5,
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: variant.name);
    }
  });

  testWidgets('current song is marked selected with its label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const NeoSongTile(
          title: 'Song',
          subtitle: 'Artist',
          playbackState: NeoPlaybackState.paused,
          currentLabel: 'Now playing',
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(NeoSongTile)),
      containsSemantics(isSelected: true, value: 'Now playing'),
    );
    handle.dispose();
  });

  testWidgets('chip exposes selected and toggles', (tester) async {
    final handle = tester.ensureSemantics();
    var selected = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => NeoChip(
            label: 'Focus',
            selected: selected,
            onSelected: (v) => setState(() => selected = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Focus'));
    await tester.pump();
    expect(selected, isTrue);
    expect(find.byIcon(NeoIcons.check), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(NeoChip)),
      containsSemantics(isSelected: true, isButton: true),
    );
    handle.dispose();
  });

  testWidgets('chip hit area reaches the minimum touch target', (tester) async {
    await tester.pumpWidget(
      _host(NeoChip(label: 'Gym', selected: false, onSelected: (_) {})),
    );
    final size = tester.getSize(find.byType(NeoChip));
    expect(
      size.height,
      greaterThanOrEqualTo(NeoLayout.standard.minTouchTarget),
    );
  });

  testWidgets('loading button keeps its label for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(NeoButton(label: 'Saving', isLoading: true, onPressed: () {})),
    );
    expect(find.bySemanticsLabel('Saving'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    handle.dispose();
  });

  testWidgets('toggle icon button swaps glyph when selected', (tester) async {
    await tester.pumpWidget(
      _host(
        NeoIconButton(
          icon: NeoIcons.like,
          selectedIcon: NeoIcons.liked,
          tooltip: 'Like',
          isSelected: true,
          onPressed: () {},
        ),
      ),
    );
    expect(find.byIcon(NeoIcons.liked), findsOneWidget);
    expect(find.byIcon(NeoIcons.like), findsNothing);
  });

  testWidgets('play button announces the action it will take', (tester) async {
    await tester.pumpWidget(
      _host(
        NeoPlayButton(
          isPlaying: true,
          onPressed: () {},
          playLabel: 'Play',
          pauseLabel: 'Pause',
        ),
      ),
    );
    expect(find.byTooltip('Pause'), findsOneWidget);
  });

  testWidgets('now-playing bars stop under reduced motion', (tester) async {
    await tester.pumpWidget(
      _host(const NeoNowPlayingBars(isActive: true), disableAnimations: true),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('now-playing bars animate when allowed', (tester) async {
    await tester.pumpWidget(_host(const NeoNowPlayingBars(isActive: true)));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('search field shows clear only with text', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      _host(
        NeoSearchField(
          controller: controller,
          hintText: 'Search',
          clearLabel: 'Clear',
        ),
      ),
    );
    expect(find.byTooltip('Clear'), findsNothing);
    await tester.enterText(find.byType(TextField), 'lofi');
    await tester.pump();
    expect(find.byTooltip('Clear'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  testWidgets('toggle row flips from anywhere on the row', (tester) async {
    var value = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => NeoListGroup(
            children: [
              NeoListRow.toggle(
                title: 'Notifications',
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Notifications'));
    await tester.pump();
    expect(value, isTrue);
  });

  testWidgets('chevrons mirror in RTL', (tester) async {
    await tester.pumpWidget(
      _host(
        Directionality(
          textDirection: TextDirection.rtl,
          child: NeoListGroup(
            children: [NeoListRow.navigation(title: 'Next', onTap: () {})],
          ),
        ),
      ),
    );
    // The outermost Transform under the icon is the mirror.
    final flip = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(NeoDirectionalIcon),
            matching: find.byType(Transform),
          ),
        )
        .first;
    expect(flip.transform.storage.first, -1);
  });
}
