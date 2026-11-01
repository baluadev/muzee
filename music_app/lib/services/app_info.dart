import 'package:package_info_plus/package_info_plus.dart';

/// The installed app's version, read from the package (pubspec's
/// `version`), so nothing has to be kept in sync by hand.
class AppInfo {
  AppInfo._();

  /// e.g. `2.0.0`. Empty until [load] has run.
  static String version = '';

  /// e.g. `20261101`.
  static String buildNumber = '';

  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      buildNumber = info.buildNumber;
    } catch (_) {
      // Unknown: the update check then never prompts.
    }
  }
}
