import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService inst =
      FirebaseAnalyticsService._internal();
  FirebaseAnalyticsService._internal();
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  void setup() {
    logEvent('openApp');
  }

  Future<void> logScreenEvent(String screen,
      {Map<String, Object>? data}) async {
    logEvent(screen);
  }

  Future<void> logKeySearchEvent(String keyword) async {
    logEvent('search_input', data: {'keyword': keyword});
  }

  Future<void> logEvent(String name, {Map<String, Object>? data}) async {
    await analytics.logEvent(
      name: name,
      parameters: data,
    );
  }
}
