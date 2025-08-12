import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:muzee/core/utils.dart';
import 'package:muzee/views/dialogs/dialog_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RMConfigService {
  static final RMConfigService inst = RMConfigService._internal();
  RMConfigService._internal();

  final remoteConfig = FirebaseRemoteConfig.instance;
  bool isSetup = false;

  Future<void> setup() async {
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    await remoteConfig.fetchAndActivate();
    isSetup = true;
    checkForUpdate();
  }

  void checkForUpdate() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final latestVersion = RMConfigService.inst.androidVersion;
    final forceUpdate = RMConfigService.inst.forceUpdate;
    final updateUrl = RMConfigService.inst.updateUrlAndroid;

    if (!kDebugMode && Utils.isNewerVersion(currentVersion, latestVersion)) {
      Future.delayed(const Duration(seconds: 10), () {
        DialogHelper.showUpdateDialog(forceUpdate, latestVersion, updateUrl);
      });
    }
  }

  String get androidVersion => remoteConfig.getString('android_version');
  String get apiKey => remoteConfig.getString('api_key');
  bool get forceUpdate => remoteConfig.getBool('force_update');
  String get updateUrlAndroid => remoteConfig.getString('update_url_android');
  int get adFrequency => remoteConfig.getInt('adFrequency');
  bool get loginGoogle => remoteConfig.getBool('login_google');
  bool get enableGame => remoteConfig.getBool('enable_game');
}
