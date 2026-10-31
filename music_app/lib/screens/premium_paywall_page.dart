import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/monetization/premium_iap_service.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/widgets/muzee_brand.dart';

/// Muzee Premium: the one-time "remove ads" purchase (see
/// [PremiumIapService.lifetimeProductId]). Shown full screen, without the
/// mini player or navigation bar.
///
/// The copy only promises what the purchase gives: no ads, and library
/// backup to a file. It's a one-time payment, never a subscription.
class PremiumPaywallPage extends StatefulWidget {
  const PremiumPaywallPage({super.key});

  @override
  State<PremiumPaywallPage> createState() => _PremiumPaywallPageState();
}

class _PremiumPaywallPageState extends State<PremiumPaywallPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    await PremiumIapService.instance.loadProducts();
    if (mounted) setState(() {});
  }

  Future<void> _buy(ProductDetails product) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await PremiumIapService.instance.purchase(product);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok && PremiumIapService.instance.storeAvailable.value) {
      showToast(context, context.l10n!.error);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    await PremiumIapService.instance.restorePurchases();
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _busy = false);
    showToast(context, context.l10n!.settingChangedMsg);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final neo = context.neo;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            PremiumIapService.instance.storeAvailable,
            EntitlementService.isPremium,
          ]),
          builder: (context, _) {
            final premium = EntitlementService.isPremium.value;
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(FluentIcons.dismiss_24_regular),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    children: [
                      const Center(child: MuzeeIcon(size: 96)),
                      const SizedBox(height: 24),
                      Text(
                        l10n.musifyPremium,
                        textAlign: TextAlign.center,
                        style: text.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.premiumSlogan,
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: neo.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _Benefit(
                        icon: FluentIcons.prohibited_24_regular,
                        title: l10n.adFreeListening,
                        subtitle: l10n.adFreeDesc,
                      ),
                      const SizedBox(height: 12),
                      _Benefit(
                        icon: FluentIcons.archive_24_regular,
                        title: l10n.dataBackupRestore,
                        subtitle: l10n.dataBackupDesc,
                      ),
                      const SizedBox(height: 32),
                      if (premium)
                        _PremiumActive(l10n.premiumActive)
                      else
                        _purchaseArea(context),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : _restore,
                        child: Text(l10n.restorePurchases),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.premiumTerms,
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(
                          color: neo.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _purchaseArea(BuildContext context) {
    final l10n = context.l10n!;
    final neo = context.neo;
    final available = PremiumIapService.instance.storeAvailable.value;
    final product = PremiumIapService.instance.products
        .where((p) => p.id == PremiumIapService.lifetimeProductId)
        .firstOrNull;

    if (!available) {
      return Text(
        l10n.premiumProductsUnavailable,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: neo.danger),
      );
    }
    if (product == null) {
      return Center(
        child: TextButton.icon(
          onPressed: _busy ? null : _reload,
          icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
          label: Text(l10n.retryLoadProducts),
        ),
      );
    }
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: _busy ? null : () => _buy(product),
        child: _busy
            ? SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: neo.onSurfaceMuted,
                ),
              )
            : Text(
                l10n.buyOncePrice(product.price),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: neo.onAccent),
              ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: neo.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: neo.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: neo.onSurface, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.bodyMedium?.copyWith(color: neo.onSurfaceMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumActive extends StatelessWidget {
  const _PremiumActive(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: neo.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FluentIcons.checkmark_circle_24_filled, color: neo.success),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: neo.onAccentSoft),
            ),
          ),
        ],
      ),
    );
  }
}
