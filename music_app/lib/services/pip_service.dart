import 'package:floating/floating.dart';
import 'package:flutter/foundation.dart';

class PipService {
  PipService._();

  static final Floating _floating = Floating();

  static Future<bool> isSupported() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    return _floating.isPipAvailable;
  }

  static Future<bool> isInPip() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final status = await _floating.pipStatus;
    return status == PiPStatus.enabled;
  }

  static Future<bool> enterImmediatePip({
    Rational aspectRatio = const Rational.landscape(),
  }) async {
    if (!await isSupported()) {
      return false;
    }

    final status = await _floating.enable(
      ImmediatePiP(aspectRatio: aspectRatio),
    );
    return status == PiPStatus.enabled || status == PiPStatus.automatic;
  }
}
