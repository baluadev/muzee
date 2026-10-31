import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:muzee/firebase_options.dart';
import 'package:muzee/main.dart' show logger;
import 'package:muzee/services/firebase/analytics_service.dart';
import 'package:muzee/services/firebase/push_service.dart';
import 'package:muzee/services/firebase/remote_config_service.dart';

/// Muzee's Firebase project: Remote Config, push notifications and
/// Analytics. Cloud backup (Firestore) is in cloud_backup_service.dart.
class FirebaseService {
  FirebaseService._();

  static bool _ready = false;

  /// Whether Firebase started; everything built on it checks this first.
  static bool get isReady => _ready;

  /// Starts Firebase. Never throws: the app works without it.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _ready = true;
    } catch (e, stackTrace) {
      logger.log('Firebase init failed', error: e, stackTrace: stackTrace);
      return;
    }
    // Remote Config fetches over the network; don't hold up the first frame.
    unawaited(RemoteConfigService.instance.init());
    await PushService.instance.init();
    unawaited(AnalyticsService.logEvent('openApp'));
  }
}
