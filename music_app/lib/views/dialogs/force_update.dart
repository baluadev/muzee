import 'package:flutter/material.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateDialog extends StatelessWidget {
  final String newVersion;
  final String updateUrl;
  final bool forceUpdate;

  const ForceUpdateDialog({
    super.key,
    required this.newVersion,
    required this.updateUrl,
    this.forceUpdate = false,
  });

  void _launchUpdateUrl() async {
    final uri = Uri.parse(updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint(locale.canotOpenUpdateLink);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !forceUpdate,
      child: AlertDialog(
        backgroundColor: MyColors.background,
        title: Text(
          locale.updateAppTitle,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        content: Text(
          locale.updateAppMessage(newVersion, forceUpdate ? 'true' : 'false'),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                locale.notNow,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ElevatedButton(
            onPressed: _launchUpdateUrl,
            child: Text(
              locale.update,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: MyColors.black),
            ),
          ),
        ],
      ),
    );
  }
}
