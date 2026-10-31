import 'package:flutter/foundation.dart';

/// Tracks overlay routes outside shell routing, for ad placement guards.
class UiRouteFlags {
  UiRouteFlags._();

  static final ValueNotifier<bool> nowPlayingVisible = ValueNotifier(false);
  static final ValueNotifier<bool> videoFullscreenVisible = ValueNotifier(
    false,
  );
}
