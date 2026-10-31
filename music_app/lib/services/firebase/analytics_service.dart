import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:muzee/main.dart' show logger;
import 'package:muzee/services/firebase/firebase_service.dart';

/// Firebase Analytics, with the event names Muzee 1.x used (`openApp`,
/// `search_input`) so the reports stay comparable.
class AnalyticsService {
  AnalyticsService._();

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!FirebaseService.isReady) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      logger.log('Analytics event "$name" failed', error: e);
    }
  }

  static Future<void> logScreen(String path) async {
    if (!FirebaseService.isReady) return;
    try {
      await FirebaseAnalytics.instance.logScreenView(screenName: path);
    } catch (e) {
      logger.log('Analytics screen "$path" failed', error: e);
    }
  }

  /// Logs a screen view each time [router] lands on a new path.
  static void trackScreens(GoRouter router) {
    String? last;
    router.routerDelegate.addListener(() {
      final path = router.routerDelegate.currentConfiguration.uri.path;
      if (path == last) return;
      last = path;
      unawaited(logScreen(path));
    });
  }

  static Future<void> logSearch(String keyword) =>
      logEvent('search_input', parameters: {'keyword': keyword});
}
