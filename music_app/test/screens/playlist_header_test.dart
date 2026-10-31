import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/theme/neo/neo_theme.dart';
import 'package:muzee/widgets/playlist_page/playlist_header.dart';

void main() {
  Future<void> pumpHeader(WidgetTester tester, {required double textScale}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildNeoTheme(NeoThemeVariant.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 800),
              textScaler: TextScaler.linear(textScale),
            ),
            child: const Scaffold(
              body: SizedBox(
                width: 360,
                child: PlaylistHeader(
                  SizedBox.square(dimension: 200),
                  'A playlist with a fairly long title',
                  1234,
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('the "Created by … • N Songs" row fits a narrow phone', (
    tester,
  ) async {
    await pumpHeader(tester, textScale: 1);

    expect(tester.takeException(), isNull);
    expect(find.text('Created by Muzee · 1234 songs'), findsOneWidget);
  });

  testWidgets('it still fits with large text', (tester) async {
    await pumpHeader(tester, textScale: 1.6);

    expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
  });

  testWidgets('one song is singular', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNeoTheme(NeoThemeVariant.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlaylistHeader(SizedBox.square(dimension: 100), 'One', 1),
          ),
        ),
      ),
    );

    expect(find.text('Created by Muzee · 1 song'), findsOneWidget);
  });
}
