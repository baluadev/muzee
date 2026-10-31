import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:muzee/constants/version.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart' show logger;
import 'package:muzee/services/firebase/firebase_service.dart';
import 'package:muzee/services/router_service.dart';
import 'package:muzee/utilities/url_launcher.dart';

const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=up.nexstudio.muzee';

/// Muzee's Remote Config keys (the same ones Muzee 1.x read).
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  /// `login_google`: show Google sign-in (and cloud backup) in Settings.
  final loginGoogleEnabled = ValueNotifier<bool>(kDebugMode);

  FirebaseRemoteConfig get _rc => FirebaseRemoteConfig.instance;

  String get _latestVersion => _rc.getString('android_version');
  bool get _forceUpdate => _rc.getBool('force_update');
  String get _updateUrl {
    final url = _rc.getString('update_url_android');
    return url.isEmpty ? _playStoreUrl : url;
  }

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
    _promptUpdateIfNeeded();
  }

  void _promptUpdateIfNeeded() {
    final latest = _latestVersion;
    if (kDebugMode || !isNewerVersion(appVersion, latest)) return;
    // Give the first screen a moment, as Muzee 1.x did.
    Future.delayed(const Duration(seconds: 10), () {
      final context = NavigationManager().context;
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: !_forceUpdate,
        builder: (context) => PopScope(
          canPop: !_forceUpdate,
          child: AlertDialog(
            title: Text(context.l10n!.updateAvailable),
            content: Text(context.l10n!.updateAvailableDescription(latest)),
            actions: [
              if (!_forceUpdate)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n!.later),
                ),
              FilledButton(
                onPressed: () => launchURL(Uri.parse(_updateUrl)),
                child: Text(context.l10n!.updateNow),
              ),
            ],
          ),
        ),
      );
    });
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
