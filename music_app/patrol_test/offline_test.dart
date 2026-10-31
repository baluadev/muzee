import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:patrol/patrol.dart';

import 'helpers/app.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  Future<void> setNetwork(PatrolIntegrationTester $, {required bool on}) async {
    final mobile = $.platform.mobile;
    if (on) {
      await mobile.enableWifi();
      await mobile.enableCellular();
    } else {
      await mobile.disableWifi();
      await mobile.disableCellular();
    }
  }

  // Home "For you" cards (private widget in home_mobile_view.dart).
  final playlistCard = find.byWidgetPredicate(
    (w) => w.runtimeType.toString() == '_PlaylistCard',
  );

  patrolTest(
    'OFF-001: mo playlist khi mat mang bao loi de hieu, Retry tai lai khi co mang',
    ($) async {
      await launchApp($);
      try {
        await $(
          playlistCard,
        ).first.waitUntilVisible(timeout: const Duration(seconds: 60));

        await setNetwork($, on: false);
        await $.pump(const Duration(seconds: 2));
        await $(playlistCard).first.tap();

        await $(
          en.loadFailed,
        ).waitUntilVisible(timeout: const Duration(seconds: 60));
        expect($(en.noSongsInPlaylist).exists, isFalse);

        await setNetwork($, on: true);
        await $.pump(const Duration(seconds: 8));
        await $(en.retry).tap();

        // "Created by Muzee · 24 songs"
        await $(
          RegExp(r'\b[1-9]\d* songs$'),
        ).waitUntilVisible(timeout: const Duration(seconds: 60));
        expect($(en.loadFailed).exists, isFalse);
      } finally {
        await setNetwork($, on: true);
      }
    },
  );
}
