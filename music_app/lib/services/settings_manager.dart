import 'dart:ui' show PlatformDispatcher;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:muzee/screens/playlist/playlist_controller.dart';
import 'package:muzee/utilities/language_utils.dart';
import 'package:youtube_charts/youtube_charts.dart';

// Preferences

final playNextSongAutomatically = ValueNotifier<bool>(
  Hive.box('settings').get('playNextSongAutomatically', defaultValue: false),
);

final useSystemColor = ValueNotifier<bool>(
  Hive.box('settings').get('useSystemColor', defaultValue: true),
);

final usePureBlackColor = ValueNotifier<bool>(
  Hive.box('settings').get('usePureBlackColor', defaultValue: false),
);

/// Muzee has no downloads, so it is never in offline-only mode. Kept (always
/// false) for code shared with NeoTuber and the playback host.
final offlineMode = ValueNotifier<bool>(false);

final predictiveBack = ValueNotifier<bool>(
  Hive.box('settings').get('predictiveBack', defaultValue: true),
);

final externalRecommendations = ValueNotifier<bool>(
  Hive.box('settings').get('externalRecommendations', defaultValue: false),
);

final useProxy = ValueNotifier<bool>(
  Hive.box('settings').get('useProxy', defaultValue: false),
);

/// The phone's country when YouTube has charts for it, else the US: the
/// charts shown until the user picks a country in Settings.
String defaultChartsCountryCode([Locale? device]) {
  final code = (device ?? PlatformDispatcher.instance.locale).countryCode
      ?.toLowerCase();
  return YouTubeChartsCountry.values.any((c) => c.name == code) ? code! : 'us';
}

final youtubeChartsCountryNotifier = ValueNotifier<YouTubeChartsCountry>(
  YouTubeChartsCountry.values.firstWhere(
    (e) =>
        e.name ==
        Hive.box(
          'settings',
        ).get('youtubeChartsCountry', defaultValue: defaultChartsCountryCode()),
    orElse: () => YouTubeChartsCountry.us,
  ),
);

Locale languageSetting = getLocaleFromLanguageCode(
  Hive.box('settings').get('languageCode', defaultValue: defaultLanguageCode())
      as String,
);

final themeModeSetting =
    Hive.box('settings').get('themeIndex', defaultValue: 0) as int;

String playlistSortSetting = Hive.box(
  'settings',
).get('playlistSortType', defaultValue: PlaylistSortType.default_.name);

Color primaryColorSetting = Color(
  Hive.box('settings').get('accentColor', defaultValue: 0xff91cef4),
);

final shuffleNotifier = ValueNotifier<bool>(
  Hive.box('settings').get('shuffleEnabled', defaultValue: false),
);

final repeatNotifier = ValueNotifier<AudioServiceRepeatMode>(
  AudioServiceRepeatMode.values[Hive.box(
    'settings',
  ).get('repeatMode', defaultValue: 0)],
);

// Non-storage notifiers

var sleepTimerNotifier = ValueNotifier<Duration?>(null);

// Server-Notifiers

final announcementURL = ValueNotifier<String?>(null);
