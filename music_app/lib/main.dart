import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/services/admob/appopen_admanager.dart';
import 'package:muzee/services/database/db_service.dart';
import 'package:muzee/services/database/local_store.dart';
import 'package:muzee/services/firebase/firebase_services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'app.dart';
import 'player_service.dart';
import 'services/admob/interstitial_admanager.dart';
import 'services/notification/notification_service.dart';

late PlayerService myPlayerService;
const FlutterSecureStorage secureStorage = FlutterSecureStorage();
final ReceivePort port = ReceivePort();
Future<String?> getAccessToken() async {
  return secureStorage.read(key: 'accessToken');
}

Future<String?> getRefreshToken() async {
  return secureStorage.read(key: 'refreshToken');
}

const String isolateName = 'isolate';

Future backgroundFetchHeadlessTask(String taskId) async {
  final uiSendPort = IsolateNameServer.lookupPortByName(isolateName);
  uiSendPort?.send(taskId);
  BackgroundFetch.finish(taskId);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await FirebaseServices.init();
  await NotificationService.initializeLocalNotifications();
  await NotificationService.startListeningNotificationEvents();

  MobileAds.instance.initialize();
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(testDeviceIds: [
      '884E8256F3D194B8607F1CCB0CE33130',
      '9A680E352F405999A071E13CDDCE08EA',
      '24995A27F22D9AAF986C5486E38150E4',
    ]),
  );

  AppOpenAdManager.inst.loadAd(); // preload từ đầu
  InterstitialAdManager.inst.loadAd();

  final dir = await getApplicationDocumentsDirectory();
  await LocalStore.inst.init();
  await DBService.inst.openDB(dir.path);
  if (Platform.isAndroid) {
    IsolateNameServer.registerPortWithName(port.sendPort, isolateName);
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  myPlayerService = await AudioService.init(
    builder: () => PlayerService()..init(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'up.nexstudio.muzee.channel.audio',
      androidNotificationChannelName: 'Muzee',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_stat_ic_launcher',
      preloadArtwork: true,
    ),
  );
  runApp(const MyApp());
  WidgetsBinding.instance.addObserver(_Handler());
}

//
class _Handler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // final isPlaying = myPlayerService.isPlaying;
    debugPrint('AppLifecycleState  $state ');
    switch (state) {
      case AppLifecycleState.inactive:
        // checkPlayer(isPlaying);
        WakelockPlus.disable();
        break;
      case AppLifecycleState.resumed:
        // Adjust.onResume();
        // checkPlayer(isPlaying);
        WakelockPlus.enable();
        break;
      case AppLifecycleState.paused:
        // Adjust.onPause();
        // checkPlayer(isPlaying);
        break;
      case AppLifecycleState.detached:
        // if (isPlaying) {
        //   myPlayerService.stop();
        // }
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void checkPlayer(bool isPlaying) {
    // if (isPlaying) {
    //   Future.delayed(const Duration(seconds: 1, milliseconds: 300), () {
    //     myPlayerService.play();
    //   });
    // }
  }
}
