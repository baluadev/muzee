import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/screens/home/home_controller.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_theme.dart';
import 'package:muzee/widgets/moods.dart';
import 'package:muzee/widgets/playlist_page/playlist_header.dart';

Map<String, dynamic> moodItem({
  String? title = 'Chill',
  String? params = 'ggMPOg1uX1JOQWZFeDByc2Jm',
  String? stripe = '4283658079',
}) => {
  'musicNavigationButtonRenderer': {
    'buttonText': {
      'runs': [
        if (title != null) {'text': title},
      ],
    },
    'clickCommand': {
      'browseEndpoint': {'params': ?params},
    },
    'solid': {'leftStripeColor': ?stripe},
  },
};

void main() {
  group('a mood from YouTube Music', () {
    test('keeps its title, the params to open it and its color', () {
      final mood = MoodCategory.fromItem(moodItem())!;
      expect(mood.title, 'Chill');
      expect(mood.params, 'ggMPOg1uX1JOQWZFeDByc2Jm');
      expect(mood.color, isNotNull);
      expect(mood.color!.a, 1.0, reason: 'used as an opaque stripe');
    });

    test('without a color still works', () {
      expect(MoodCategory.fromItem(moodItem(stripe: null))!.color, isNull);
    });

    test('that cannot be opened or named is skipped', () {
      expect(MoodCategory.fromItem(moodItem(params: null)), isNull);
      expect(MoodCategory.fromItem(moodItem(title: null)), isNull);
      expect(MoodCategory.fromItem({'somethingElse': {}}), isNull);
      expect(MoodCategory.fromItem('not a map'), isNull);
    });

    testWidgets('card text uses the theme, so it reads in light mode', (
      tester,
    ) async {
      final mood = MoodCategory.fromItem(moodItem())!;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildNeoTheme(NeoThemeVariant.light),
          home: Scaffold(
            body: SizedBox(width: 200, height: 56, child: MoodCard(mood)),
          ),
        ),
      );
      final text = find.text('Chill');
      final style = DefaultTextStyle.of(
        tester.element(text),
      ).style.merge(tester.widget<Text>(text).style);
      expect(style.color, NeoColors.light.onSurface);
    });
  });

  group('Home greeting', () {
    GreetingPart at(int hour, [int minute = 0]) =>
        HomeController.greetingFor(DateTime(2026, 10, 31, hour, minute));

    test('morning from 5:00 until noon', () {
      expect(at(4, 59), GreetingPart.evening);
      expect(at(5), GreetingPart.morning);
      expect(at(11, 59), GreetingPart.morning);
    });

    test('afternoon from noon until 18:00, then evening', () {
      expect(at(12), GreetingPart.afternoon);
      expect(at(17, 59), GreetingPart.afternoon);
      expect(at(18), GreetingPart.evening);
      expect(at(0), GreetingPart.evening);
    });
  });

  group('playlist header', () {
    Future<void> pump(WidgetTester tester, {String? owner}) =>
        tester.pumpWidget(
          MaterialApp(
            theme: buildNeoTheme(NeoThemeVariant.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: PlaylistHeader(
                  const SizedBox.square(dimension: 100),
                  'Mix',
                  12,
                  owner: owner,
                ),
              ),
            ),
          ),
        );

    testWidgets('names who made the playlist', (tester) async {
      await pump(tester, owner: 'YouTube');
      expect(find.text('YouTube · 12 songs'), findsOneWidget);
    });

    testWidgets('an empty owner shows only the song count', (tester) async {
      await pump(tester, owner: '');
      expect(find.text('12 songs'), findsOneWidget);
    });
  });
}
