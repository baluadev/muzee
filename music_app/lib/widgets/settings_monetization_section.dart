/*
 *     Copyright (C) 2026 Valeri Gokadze
 */

import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/services/monetization/ad_free_wallet_service.dart';
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/monetization/ad_unit_ids.dart';
import 'package:muzee/services/monetization/ads_facade.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/monetization/monetization_remote_config.dart';
import 'package:muzee/services/monetization/monetization_telemetry.dart';
import 'package:muzee/services/router_service.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/flutter_toast.dart';

import 'package:muzee/widgets/tubify_components.dart';

class SettingsMonetizationSection extends StatefulWidget {
  const SettingsMonetizationSection({
    super.key,
    this.additionalTiles = const [],
  });
  final List<Widget> additionalTiles;

  @override
  State<SettingsMonetizationSection> createState() =>
      _SettingsMonetizationSectionState();
}

class _SettingsMonetizationSectionState
    extends State<SettingsMonetizationSection> {
  bool _rewardLoading = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    EntitlementService.isPremium.addListener(_onEntitlementChanged);
    AdFreeWalletService.revision.addListener(_onWalletChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AdsFacade.instance.preloadRewarded());
    });
    _scheduleTicker();
  }

  void _scheduleTicker() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (AdFreeWalletService.isRewardCooldownActive ||
          AdFreeWalletService.isAdFreeActive) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    EntitlementService.isPremium.removeListener(_onEntitlementChanged);
    AdFreeWalletService.revision.removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onEntitlementChanged() {
    if (mounted) setState(() {});
  }

  void _onWalletChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _grantRewardMinutes(int minutes) async {
    await AdFreeWalletService.grant(Duration(minutes: minutes));
    await AdFreeWalletService.markRewardCompleted();
    MonetizationTelemetry.rewardCompleted();
    MonetizationTelemetry.walletGranted(minutes);
  }

  Future<void> _watchAd(BuildContext context) async {
    final l10n = context.l10n!;
    if (_rewardLoading ||
        EntitlementService.isPremium.value ||
        AdFreeWalletService.isRewardCooldownActive) {
      return;
    }

    if (!await AdPlacementGate.canShowRewarded()) {
      if (context.mounted) showToast(context, l10n.rewardedUnavailable);
      return;
    }

    setState(() => _rewardLoading = true);
    MonetizationTelemetry.rewardStarted();

    final minutes = MonetizationRemoteConfig.rewardGrantMinutes;
    final result = await AdsFacade.instance.showRewardedIfAllowed(
      gate: AdPlacementGate.canShowRewarded,
      onUserEarned: (_, _) {
        unawaited(_grantRewardMinutes(minutes));
      },
    );

    if (!mounted) return;
    setState(() => _rewardLoading = false);

    if (result == RewardedShowResult.shown) {
      showToast(context, l10n.rewardedCompletedToast);
    } else {
      showToast(context, l10n.rewardedUnavailable);
    }
  }

  String? _walletSubtitle(BuildContext context) {
    final l10n = context.l10n!;
    if (AdFreeWalletService.isRewardCooldownActive) {
      final left = AdFreeWalletService.timeUntilCooldownEnds();
      final sec = left?.inSeconds ?? 0;
      return l10n.rewardCooldownWait(sec.clamp(0, 9999));
    }
    if (AdFreeWalletService.isAdFreeActive) {
      final end = AdFreeWalletService.adFreeUntil;
      if (end == null) return null;
      final mins = end.difference(DateTime.now()).inMinutes.clamp(1, 24 * 60);
      return l10n.adFreeTimeRemaining(mins);
    }
    return l10n.watchAdEarnAdFree;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final premium = EntitlementService.isPremium.value;

    return TubifySettingsSection(
      title: l10n.supportAndPremium,
      children: [
        TubifySettingsTile(
          title: l10n.musifyPremium,
          icon: FluentIcons.star_24_filled,
          iconColor: context.neo.accent,
          trailingText: premium ? l10n.premiumMemberThanks : null,
          onTap: () => NavigationManager.router.push('/settings/premium'),
        ),
        if (!premium && AdUnitIds.hasRewarded)
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap:
                  (_rewardLoading || AdFreeWalletService.isRewardCooldownActive)
                  ? null
                  : () => _watchAd(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: context.neo.surface,
                  border: Border.all(color: context.neo.accent),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.neo.accent,
                        shape: BoxShape.circle,
                      ),
                      child: _rewardLoading
                          ? Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.neo.onAccent,
                                  ),
                                ),
                              ),
                            )
                          : Icon(
                              FluentIcons.play_24_filled,
                              color: context.neo.onAccent,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.watchAdButton,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.neo.onSurface,
                                ),
                          ),
                          if (_walletSubtitle(context) != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _walletSubtitle(context)!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 12,
                                    color: context.neo.accent,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      FluentIcons.chevron_right_24_regular,
                      color: context.neo.accent,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ...widget.additionalTiles,
      ],
    );
  }
}
