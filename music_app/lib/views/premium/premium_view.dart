import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/core/widget_extension.dart';
import 'package:muzee/services/inapp/inapp_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: const Icon(FlutterRemix.close_line, size: 24)
            .attachGestureDetector(onTap: () => Navigator.pop(context)),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder(
          future: InAppService.inst.init(),
          builder: (context, snapshot) {
            final productDetails = InAppService.inst.removeAdsProduct;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      locale.titlePremium,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      locale.subTitlePremium,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    BenefitTile(icon: Icons.block, title: locale.benefit1),
                    BenefitTile(
                        icon: Icons.star_border, title: locale.benefit2),
                    BenefitTile(icon: Icons.lock_open, title: locale.benefit3),
                    const Spacer(),
                    if (productDetails != null)
                      ElevatedButton(
                        onPressed: () {
                          InAppService.inst.buyRemoveAds();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          locale.premiumButton(productDetails.price),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    TextButton(
                      onPressed: () async {
                        await InAppService.inst.restorePurchases();
                        setState(() {});
                      },
                      child: Text(
                        locale.restorePurchase,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      locale.premiumPolicyNote,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}

class BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const BenefitTile({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
