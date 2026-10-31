import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:muzee/main.dart' show audioHandler, logger;
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/firebase/analytics_service.dart';
import 'package:muzee/services/firebase/firebase_service.dart';
import 'package:muzee/services/router_service.dart';

/// Firebase Cloud Messaging. A push whose data has a `songId` (YouTube video
/// id), as Muzee's campaigns send, plays that song when the user taps it.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  Future<void> init() async {
    if (!FirebaseService.isReady) return;
    try {
      FirebaseMessaging.onMessageOpenedApp.listen(_open);
      // Opened from a notification while the app wasn't running.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        // Let the player and router finish starting first.
        Future.delayed(const Duration(seconds: 1), () => _open(initial));
      }
    } catch (e, stackTrace) {
      logger.log('Push setup failed', error: e, stackTrace: stackTrace);
    }
  }

  /// Android 13+ needs the permission for pushes (media notifications are
  /// exempt). Asks once [router] has left the first-launch intro, so the
  /// system dialog doesn't cover it.
  void requestPermissionAfterIntro(GoRouter router) {
    if (!FirebaseService.isReady) return;
    final delegate = router.routerDelegate;
    void check() {
      if (delegate.currentConfiguration.uri.path ==
          NavigationManager.introPath) {
        return;
      }
      delegate.removeListener(check);
      Future.delayed(const Duration(seconds: 2), _requestPermission);
    }

    delegate.addListener(check);
    check();
  }

  Future<void> _requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      logger.log('Notification permission request failed', error: e);
    }
  }

  Future<void> _open(RemoteMessage message) async {
    final songId = message.data['songId']?.toString();
    if (songId == null || songId.isEmpty) return;
    unawaited(
      AnalyticsService.logEvent('push_open', parameters: {'songId': songId}),
    );
    try {
      final song = await getSongDetails(0, songId);
      await audioHandler.addPlaylistToQueue([song], replace: true);
    } catch (e, stackTrace) {
      logger.log(
        'Could not play pushed song $songId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
