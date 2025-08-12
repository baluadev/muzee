import 'package:firebase_core/firebase_core.dart';
import 'package:muzee/firebase_options.dart';

import 'analytics_service.dart';
import 'messaging_service.dart';
import 'remote_service.dart';

class FirebaseServices {
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await RMConfigService.inst.setup();
    await MessagingService.inst.setup();
    FirebaseAnalyticsService.inst.setup();
  }
}
