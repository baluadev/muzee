/// AdMob unit IDs. Override via `--dart-define=USE_TEST_ADS=false` for release.
class AdUnitIds {
  AdUnitIds._();

  // Set to false in release builds, or use --dart-define=USE_TEST_ADS=false
  static const bool useTestAds = bool.fromEnvironment(
    'USE_TEST_ADS',
    defaultValue: true,
  );

  static String get appOpen => useTestAds
      ? 'ca-app-pub-3940256099942544/9257395921' // Google Test ID
      : 'ca-app-pub-8681872943360035/5669167561'; // Muzee

  /// Muzee has no rewarded unit yet; fill this in once one exists in AdMob.
  static const String _rewardedProd = '';

  /// Whether the "watch an ad for ad-free time" reward can be offered.
  static bool get hasRewarded => useTestAds || _rewardedProd.isNotEmpty;

  static String get rewarded =>
      useTestAds ? 'ca-app-pub-3940256099942544/5224354917' : _rewardedProd;

  static String get banner => useTestAds
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-8681872943360035/2735064222';

  static String get nativeAd => useTestAds
      ? 'ca-app-pub-3940256099942544/2247696110'
      : 'ca-app-pub-8681872943360035/8648083498';

  static String get interstitial => useTestAds
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-8681872943360035/9107248490';
}
