import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/services/audio_service.dart';
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/firebase/analytics_service.dart';
import 'package:muzee/services/firebase/firebase_service.dart';
import 'package:muzee/services/firebase/push_service.dart';
import 'package:muzee/services/google_account_service.dart';
import 'package:muzee/services/io_service.dart';
import 'package:muzee/services/legacy/legacy_migration.dart';
import 'package:muzee/services/logger_service.dart';
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/monetization/ads_facade.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/monetization/monetization_lifecycle_observer.dart';
import 'package:muzee/services/monetization/monetization_remote_config.dart';
import 'package:muzee/services/monetization/premium_iap_service.dart';
import 'package:muzee/services/playlist_sharing.dart';
import 'package:muzee/services/playlists_manager.dart';
import 'package:muzee/services/router_service.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/services/youtube_taste_sync.dart';
import 'package:muzee/theme/app_themes.dart';
import 'package:muzee/theme/neo/neo_theme.dart';
import 'package:muzee/theme/neo/neo_typography.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/utilities/language_utils.dart';
import 'package:muzee/utilities/playlist_utils.dart';
import 'package:muzee/utilities/sharing_intent.dart';
import 'package:muzee/widgets/muzee_artwork.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

late MusifyAudioHandler audioHandler;
late StreamSubscription<String?> sharingIntentSubscription;

final logger = Logger();
final appLinks = AppLinks();

class Musify extends StatefulWidget {
  const Musify({super.key});

  static Future<void> updateAppState(
    BuildContext context, {
    ThemeMode? newThemeMode,
    Locale? newLocale,
    Color? newAccentColor,
    bool? useSystemColor,
  }) async {
    context.findAncestorStateOfType<_MusifyState>()!.changeSettings(
      newThemeMode: newThemeMode,
      newLocale: newLocale,
      newAccentColor: newAccentColor,
      systemColorStatus: useSystemColor,
    );
  }

  @override
  _MusifyState createState() => _MusifyState();
}

class _MusifyState extends State<Musify> {
  final MonetizationLifecycleObserver _monetizationLifecycle =
      MonetizationLifecycleObserver();

  void changeSettings({
    ThemeMode? newThemeMode,
    Locale? newLocale,
    Color? newAccentColor,
    bool? systemColorStatus,
  }) {
    setState(() {
      if (newThemeMode != null) {
        themeMode = newThemeMode;
        brightness = getBrightnessFromThemeMode(newThemeMode);
      }
      if (newLocale != null) {
        languageSetting = newLocale;
      }
      if (newAccentColor != null) {
        if (systemColorStatus != null &&
            useSystemColor.value != systemColorStatus) {
          useSystemColor.value = systemColorStatus;
          addOrUpdateData('settings', 'useSystemColor', systemColorStatus);
        }
        primaryColorSetting = newAccentColor;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final platformDispatcher = PlatformDispatcher.instance;

    // This callback is called every time the brightness changes.
    platformDispatcher.onPlatformBrightnessChanged = () {
      if (themeMode == ThemeMode.system) {
        setState(() {
          brightness = platformDispatcher.platformBrightness;
        });
      }
    };

    offlineMode.addListener(_onOfflineModeChanged);

    WidgetsBinding.instance.addObserver(_monetizationLifecycle);

    sharingIntentSubscription = ReceiveSharingIntent.getTextStream().listen(
      (String? value) async {
        await consumeYoutubeSharedTextIntent(
          value,
          audioHandler: audioHandler,
          onError: (error, stackTrace) {
            logger.log(
              'Error while playing shared song:',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
      },
      onError: (err) {
        logger.log('getTextStream error:', error: err);
      },
    );
  }

  @override
  void dispose() {
    offlineMode.removeListener(_onOfflineModeChanged);

    WidgetsBinding.instance.removeObserver(_monetizationLifecycle);

    Hive.close();
    sharingIntentSubscription.cancel();
    super.dispose();
  }

  void _onOfflineModeChanged() {
    // Force rebuild when offline mode changes
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Muzee Mono: dark by default; the light palette is ready for when the
    // theme setting comes back (themeMode in theme/app_themes.dart).
    final darkVariant = NeoThemeVariant.resolve(
      brightness: Brightness.dark,
      pureBlack: usePureBlackColor.value,
    );
    final icons = brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        // With 3-button navigation Android draws a translucent scrim so the
        // buttons stay readable over content scrolling under them (Settings,
        // the queue sheet). Android docs: gesture navigation gets no scrim.
        systemNavigationBarContrastEnforced: true,
        statusBarBrightness: brightness,
        statusBarIconBrightness: icons,
        systemNavigationBarIconBrightness: icons,
      ),
      child: MaterialApp.router(
        themeMode: themeMode,
        darkTheme: buildNeoTheme(
          darkVariant,
          androidTransitions: transitionsBuilder,
          locale: languageSetting,
        ),
        theme: buildNeoTheme(
          NeoThemeVariant.light,
          androidTransitions: transitionsBuilder,
          locale: languageSetting,
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: appSupportedLocales,
        locale: languageSetting,
        routerConfig: NavigationManager.router,
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerNeoFontLicenses();
  MediaKit.ensureInitialized();
  ArtworkRetry.install();
  await initialisation();

  runApp(const Musify());
}

Future<void> initialisation() async {
  try {
    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox('settings'),
      Hive.openBox('user'),
      Hive.openBox('userNoBackup'),
      Hive.openBox('cache'),
      Hive.openBox('monetization'),
    ]);

    // Before anything reads the library: Muzee 1.x data moves in here.
    await migrateMuzee1IfNeeded();

    await MonetizationRemoteConfig.ensureDefaults();
    await EntitlementService.loadFromStorage();

    await FirebaseService.init();
    attachYouTubeTasteSync();
    unawaited(GoogleAccountService.instance.restore());

    audioHandler = await AudioService.init(
      builder: MusifyAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'up.nexstudio.muzee.channel.audio',
        androidNotificationChannelName: 'Muzee',
        androidNotificationIcon: 'mipmap/ic_stat_ic_launcher',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false,
      ),
    );

    AdPlacementGate.playbackPlayingResolver = () =>
        audioHandler.playbackState.value.playing;

    await MobileAds.instance.initialize();
    await PremiumIapService.instance.init();
    unawaited(AdsFacade.instance.preloadRewarded());
    unawaited(AdsFacade.instance.preloadAppOpenIfNeeded());

    // Init router
    NavigationManager.instance;
    AnalyticsService.trackScreens(NavigationManager.router);
    PushService.instance.requestPermissionAfterIntro(NavigationManager.router);

    try {
      // Listen to incoming links while app is running
      appLinks.uriLinkStream.listen(
        handleIncomingLink,
        onError: (err) {
          logger.log('URI link error:', error: err);
        },
      );
    } on PlatformException {
      logger.log('Failed to get initial uri');
    }
  } catch (e, stackTrace) {
    logger.log('Initialization Error', error: e, stackTrace: stackTrace);
  }

  applicationDirPath = (await getApplicationDocumentsDirectory()).path;
  await FilePaths.ensureDirectoriesExist();
}

void handleIncomingLink(Uri? uri) async {
  if (uri != null && uri.scheme == 'muzee' && uri.host == 'playlist') {
    try {
      if (uri.pathSegments[0] == 'custom') {
        final encodedPlaylist = uri.pathSegments[1];

        final playlist = await PlaylistSharingService.decodeAndExpandPlaylist(
          encodedPlaylist,
        );

        if (playlist != null) {
          // Ensure the incoming playlist has a unique id so it can be removed later
          if (playlist['ytid'] == null || playlist['ytid'].toString().isEmpty) {
            playlist['ytid'] = PlaylistUtils.generateCustomPlaylistId();
          }
          // Check for duplicate by title and song ytids
          final incomingYtids = (playlist['list'] as List<dynamic>)
              .map((s) => s['ytid'].toString())
              .toList();

          final exists = userCustomPlaylists.value.any((p) {
            if (p['title'] != playlist['title']) return false;
            final existingList = (p['list'] as List<dynamic>?) ?? [];
            final existingYtids = existingList
                .map((s) => s['ytid']?.toString())
                .where((e) => e != null)
                .toList();
            if (existingYtids.length != incomingYtids.length) return false;
            for (var i = 0; i < incomingYtids.length; i++) {
              if (existingYtids[i] != incomingYtids[i]) return false;
            }
            return true;
          });

          if (exists) {
            showToast(
              NavigationManager().context,
              NavigationManager().context.l10n!.playlistAlreadyExists,
            );
          } else {
            userCustomPlaylists.value = [
              ...userCustomPlaylists.value,
              playlist,
            ];
            unawaited(
              addOrUpdateData(
                'user',
                'customPlaylists',
                userCustomPlaylists.value,
              ),
            );
            showToast(
              NavigationManager().context,
              '${NavigationManager().context.l10n!.addedSuccess}!',
            );
          }
        } else {
          showToast(
            NavigationManager().context,
            NavigationManager().context.l10n!.failedToLoadPlaylist,
          );
        }
      }
    } catch (e) {
      showToast(
        NavigationManager().context,
        NavigationManager().context.l10n!.failedToLoadPlaylist,
      );
    }
  }
}
