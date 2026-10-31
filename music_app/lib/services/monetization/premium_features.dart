import 'package:muzee/services/monetization/entitlement_service.dart';

/// Premium-only capabilities — extend as product gates appear.
class PremiumFeatures {
  PremiumFeatures._();

  static bool get hasPremiumExperience => EntitlementService.isPremium.value;
}
