import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart' show logger;
import 'package:muzee/services/app_info.dart';
import 'package:muzee/services/firebase/firebase_service.dart';
import 'package:muzee/services/monetization/ads_facade.dart';
import 'package:muzee/services/monetization/ui_route_flags.dart';
import 'package:muzee/services/router_service.dart';
import 'package:muzee/utilities/url_launcher.dart';

const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=up.nexstudio.muzee';

/// The top-level screens where an update prompt may appear: the listener is
/// browsing, not watching a video, on the player or in a dialog.
const updatePromptPaths = {
  NavigationManager.homePath,
  NavigationManager.explorePath,
  NavigationManager.libraryPath,
};

/// Whether the update prompt may show right now.
@visibleForTesting
bool canShowUpdatePrompt({
  required String path,
  required bool playerOpen,
  required bool videoFullscreen,
  required bool adShowing,
  required bool appInFront,
}) =>
    appInFront &&
    !playerOpen &&
    !videoFullscreen &&
    !adShowing &&
    updatePromptPaths.contains(path);

/// Muzee's Remote Config keys (the same ones Muzee 1.x read):
///
/// - `android_version`: the latest release's version name; an older app
///   asks to update.
/// - `force_update`: the prompt can't be dismissed, and comes back every
///   time the app returns to the front until it's updated.
/// - `update_url_android`: where "Update" goes when Google Play's in-app
///   update isn't available (default: the Play listing).
/// - `login_google`: show Google sign-in (and cloud backup) in Settings.
class RemoteConfigService with WidgetsBindingObserver {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  final loginGoogleEnabled = ValueNotifier<bool>(kDebugMode);

  FirebaseRemoteConfig get _rc => FirebaseRemoteConfig.instance;

  String get _latestVersion => _rc.getString('android_version');
  bool get _forceUpdate => _rc.getBool('force_update');
  String get _updateUrl {
    final url = _rc.getString('update_url_android');
    return url.isEmpty ? _playStoreUrl : url;
  }

  /// This install is older than [_latestVersion].
  bool _outdated = false;
  bool _dialogOpen = false;

  /// A prompt is due (once per launch, or again on resume when forced).
  bool _due = false;
  Timer? _waiting;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  /// Waited after launch before the first prompt, so the home screen
  /// settles first.
  static const _firstDelay = Duration(seconds: 6);
  static const _pollEvery = Duration(seconds: 2);

  Future<void> init() async {
    if (!FirebaseService.isReady) return;
    try {
      await _rc.setDefaults(const {
        'android_version': '',
        'force_update': false,
        'update_url_android': '',
        'login_google': false,
      });
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await _rc.fetchAndActivate();
    } catch (e, stackTrace) {
      // Offline or throttled: the last activated (or default) values apply.
      logger.log(
        'Remote Config fetch failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    loginGoogleEnabled.value = kDebugMode || _rc.getBool('login_google');

    _outdated = isNewerVersion(AppInfo.version, _latestVersion);
    if (kDebugMode || !_outdated) return;
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(_firstDelay, _schedulePrompt);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    // A forced update comes back until it's done.
    if (state == AppLifecycleState.resumed && _forceUpdate) _schedulePrompt();
  }

  /// Shows the prompt as soon as the listener is on a browsing screen.
  void _schedulePrompt() {
    if (!_outdated || _dialogOpen) return;
    _due = true;
    _waiting ??= Timer.periodic(_pollEvery, (_) => _tryShow());
    _tryShow();
  }

  void _tryShow() {
    if (!_due || _dialogOpen) return;
    final ready = canShowUpdatePrompt(
      path: NavigationManager.router.routeInformationProvider.value.uri.path,
      playerOpen: UiRouteFlags.nowPlayingVisible.value,
      videoFullscreen: UiRouteFlags.videoFullscreenVisible.value,
      adShowing: AdsFacade.instance.isShowingFullScreen,
      appInFront: _lifecycle == AppLifecycleState.resumed,
    );
    if (!ready) return;
    _due = false;
    _waiting?.cancel();
    _waiting = null;
    unawaited(_showPrompt());
  }

  Future<void> _showPrompt() async {
    final context = NavigationManager().context;
    if (!context.mounted) return;
    final force = _forceUpdate;
    final latest = _latestVersion;
    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: !force,
      builder: (dialogContext) => PopScope(
        canPop: !force,
        child: AlertDialog(
          title: Text(dialogContext.l10n!.updateAvailable),
          content: Text(dialogContext.l10n!.updateAvailableDescription(latest)),
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(dialogContext.l10n!.later),
              ),
            FilledButton(
              onPressed: () async {
                final updated = await _startUpdate();
                if (updated && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(dialogContext.l10n!.updateNow),
            ),
          ],
        ),
      ),
    );
    _dialogOpen = false;
  }

  /// Updates inside the app through Google Play when it can (installs from
  /// Play), otherwise opens [_updateUrl]. Returns whether Play's update
  /// went ahead.
  Future<bool> _startUpdate() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable &&
            info.immediateUpdateAllowed) {
          final result = await InAppUpdate.performImmediateUpdate();
          if (result == AppUpdateResult.success) return true;
          if (result == AppUpdateResult.userDeniedUpdate) return false;
        }
      } catch (e) {
        // Not installed from Play, or Play can't tell yet: use the link.
        logger.log('In-app update unavailable', error: e);
      }
    }
    await launchURL(Uri.parse(_updateUrl));
    return false;
  }
}

/// Whether [latest] (e.g. `2.1.0`) is a higher version than [current].
/// Empty or unparsable versions are never newer.
bool isNewerVersion(String current, String latest) {
  List<int>? parse(String v) {
    final parts = v.trim().split('.');
    if (v.trim().isEmpty) return null;
    final numbers = parts.map(int.tryParse).toList();
    return numbers.contains(null) ? null : numbers.cast<int>();
  }

  final a = parse(current);
  final b = parse(latest);
  if (a == null || b == null) return false;
  for (var i = 0; i < a.length || i < b.length; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return y > x;
  }
  return false;
}
