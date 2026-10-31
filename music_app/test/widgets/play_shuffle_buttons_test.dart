import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/theme/neo/neo_theme.dart';
import 'package:muzee/widgets/playlist_page/play_shuffle_buttons.dart';

void main() {
  Future<AppLocalizations> pump(
    WidgetTester tester, {
    required NeoThemeVariant variant,
    Locale locale = const Locale('en'),
    double width = 400,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNeoTheme(variant),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: PlayShuffleButtons(onPlay: () {}, onShuffle: () {}),
            ),
          ),
        ),
      ),
    );
    return lookupAppLocalizations(locale);
  }

  Color? drawnColor(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

  for (final variant in [NeoThemeVariant.dark, NeoThemeVariant.light]) {
    testWidgets('${variant.name}: labels are drawn in the buttons\' colors', (
      tester,
    ) async {
      final l10n = await pump(tester, variant: variant);
      final c = variant.colors;

      // Regression: a text-theme style on the label drew "Play" in
      // onSurface, white on the white button in the dark theme.
      expect(drawnColor(tester, l10n.play), c.onAccent);
      expect(drawnColor(tester, l10n.shufflePlay), c.onSurface);
    });
  }

  testWidgets('"Phát ngẫu nhiên" stays on one line on a narrow phone', (
    tester,
  ) async {
    final l10n = await pump(
      tester,
      variant: NeoThemeVariant.dark,
      locale: const Locale('vi'),
      width: 312,
    );
    expect(tester.takeException(), isNull);
    final label = tester.renderObject<RenderParagraph>(
      find.text(l10n.shufflePlay),
    );
    // One line: the paragraph is no taller than a single line of its text.
    expect(label.size.height, lessThan(label.text.style!.fontSize! * 2));
  });
}
