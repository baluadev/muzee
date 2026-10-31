import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';

/// Shown when online content fails to load: a plain-language [message] and,
/// when [onRetry] is given, a Retry button.
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({super.key, this.message, this.onRetry});

  /// Defaults to the generic "couldn't load" message.
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.cloud_off_24_regular,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? l10n.loadFailed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(FluentIcons.arrow_clockwise_20_regular),
                label: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
