import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart' show audioHandler, logger;
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/firebase/analytics_service.dart';
import 'package:muzee/services/firebase/firebase_service.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/router_service.dart';
import 'package:muzee/services/settings_manager.dart';

/// Shows in-app banners from anywhere (pushes that arrive while the app is
/// open). Set as the app's `scaffoldMessengerKey`.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// What a push asks for when opened, from its data payload:
/// `songId` plays a song; `playlistId` or `albumId` opens that page.
/// (All are YouTube ids; albums are YouTube playlists.)
@immutable
sealed class PushAction {
  const PushAction();

  static PushAction? fromData(Map<String, dynamic> data) {
    String? id(String key) {
      final value = data[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    final song = id('songId');
    if (song != null) return PlaySong(song);
    final playlist = id('playlistId') ?? id('albumId');
    if (playlist != null) return OpenPlaylist(playlist);
    return null;
  }
}

final class PlaySong extends PushAction {
  const PlaySong(this.songId);
  final String songId;

  @override
  bool operator ==(Object other) => other is PlaySong && other.songId == songId;
  @override
  int get hashCode => songId.hashCode;
}

final class OpenPlaylist extends PushAction {
  const OpenPlaylist(this.playlistId);
  final String playlistId;

  /// The route that shows it.
  String get path => '${NavigationManager.homePath}/playlist/$playlistId';

  @override
  bool operator ==(Object other) =>
      other is OpenPlaylist && other.playlistId == playlistId;
  @override
  int get hashCode => playlistId.hashCode;
}

/// The FCM topics a listener is subscribed to: everyone, their app
/// language, and Premium or not. Campaigns target these from the Firebase
/// console.
@visibleForTesting
Set<String> pushTopicsFor({
  required String languageCode,
  required bool premium,
}) => {
  'all',
  'lang_${languageCode.toLowerCase()}',
  if (premium) 'premium' else 'free',
};

/// Firebase Cloud Messaging.
///
/// - Tapped notifications (app closed or in the background) run their
///   [PushAction].
/// - Pushes that arrive while the app is open would otherwise be dropped
///   (Android shows nothing for an app in front): they show as an in-app
///   banner with the action as its button.
/// - The device keeps its topics ([pushTopicsFor]) in step with the app's
///   language and Premium.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static const _topicsKey = 'push_topics';

  Future<void> init() async {
    if (!FirebaseService.isReady) return;
    try {
      FirebaseMessaging.onMessageOpenedApp.listen(_open);
      FirebaseMessaging.onMessage.listen(_showInApp);
      // Opened from a notification while the app wasn't running.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        // Let the player and router finish starting first.
        Future.delayed(const Duration(seconds: 1), () => _open(initial));
      }
      EntitlementService.isPremium.addListener(_syncTopics);
      unawaited(_syncTopics());
      if (kDebugMode) unawaited(_logTokenForTesting());
    } catch (e, stackTrace) {
      logger.log('Push setup failed', error: e, stackTrace: stackTrace);
    }
  }

  /// Logs the registration token the Firebase console's "Send test
  /// message" asks for. (getToken is deprecated for register(), whose
  /// installation ids need an extra opt-in and aren't what the console
  /// takes yet.)
  Future<void> _logTokenForTesting() async {
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      logger.log('FCM token for test pushes: $token');
    } catch (e) {
      logger.log('Reading the FCM token failed', error: e);
    }
  }

  /// Call when the app language changes.
  Future<void> onLanguageChanged() => _syncTopics();

  /// Subscribes to [pushTopicsFor] the current language and Premium, and
  /// leaves the topics that no longer apply.
  Future<void> _syncTopics() async {
    if (!FirebaseService.isReady) return;
    final box = Hive.box('settings');
    final wanted = pushTopicsFor(
      languageCode: languageSetting.languageCode,
      premium: EntitlementService.isPremium.value,
    );
    final had = Set<String>.from(
      (box.get(_topicsKey) as List?)?.cast<String>() ?? const [],
    );
    try {
      final messaging = FirebaseMessaging.instance;
      for (final topic in had.difference(wanted)) {
        await messaging.unsubscribeFromTopic(topic);
      }
      for (final topic in wanted.difference(had)) {
        await messaging.subscribeToTopic(topic);
      }
      await box.put(_topicsKey, wanted.toList());
    } catch (e) {
      // Offline: tried again on the next start or change.
      logger.log('Updating push topics failed', error: e);
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

  void _showInApp(RemoteMessage message) {
    final messenger = rootScaffoldMessengerKey.currentState;
    final context = rootScaffoldMessengerKey.currentContext;
    final notification = message.notification;
    if (messenger == null || context == null || notification == null) return;
    final action = PushAction.fromData(message.data);
    final l10n = context.l10n!;
    final title = notification.title;
    final body = notification.body;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null && title.isNotEmpty)
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (body != null && body.isNotEmpty)
              Text(body, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ),
        action: action == null
            ? null
            : SnackBarAction(
                label: action is PlaySong ? l10n.play : l10n.open,
                onPressed: () => runAction(action, source: 'push_inapp'),
              ),
      ),
    );
  }

  Future<void> _open(RemoteMessage message) async {
    final action = PushAction.fromData(message.data);
    if (action != null) await runAction(action, source: 'push_open');
  }

  /// Plays the song or opens the page [action] asks for; [source] names
  /// where it came from in Analytics.
  Future<void> runAction(PushAction action, {required String source}) async {
    switch (action) {
      case PlaySong(:final songId):
        unawaited(
          AnalyticsService.logEvent(source, parameters: {'songId': songId}),
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
      case OpenPlaylist(:final playlistId, :final path):
        unawaited(
          AnalyticsService.logEvent(
            source,
            parameters: {'playlistId': playlistId},
          ),
        );
        unawaited(NavigationManager.router.push(path));
    }
  }
}
