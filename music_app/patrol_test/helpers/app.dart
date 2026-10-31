import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:muzee/main.dart';
import 'package:patrol/patrol.dart';

/// Boots the real app the way `main()` does, then waits for the home shell.
///
/// Phone layout shows a bottom [NavigationBar]; on a tablet-size emulator the
/// shell uses a side rail instead, so these tests target phone-size devices.
///
/// Each test starts with cleared app data, so Muzee shows its first-launch
/// intro (about 2 s) and then asks for notification permission (Android 13+).
/// The permission is denied so the dialog doesn't cover the app.
Future<void> launchApp(PatrolIntegrationTester $) async {
  MediaKit.ensureInitialized();
  await initialisation();
  await $.pumpWidget(const Musify());
  await $(NavigationBar).waitUntilVisible(timeout: const Duration(seconds: 60));
  final mobile = $.platform.mobile;
  if (await mobile.isPermissionDialogVisible(
    timeout: const Duration(seconds: 5),
  )) {
    await mobile.denyPermission();
  }
}
