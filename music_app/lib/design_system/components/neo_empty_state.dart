import 'package:flutter/material.dart';
import 'package:muzee/design_system/components/neo_button.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_layout.dart';

/// Empty, offline or error screen: an invitation with one action.
class NeoEmptyState extends StatelessWidget {
  const NeoEmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction go together.',
       );

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(layout.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: ShapeDecoration(
                color: c.accentSoft,
                shape: const CircleBorder(),
              ),
              child: SizedBox.square(
                dimension: layout.playButtonLarge,
                child: Icon(
                  icon,
                  color: c.onAccentSoft,
                  size: layout.iconLarge,
                ),
              ),
            ),
            SizedBox(height: layout.space16),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            if (message != null) ...[
              SizedBox(height: layout.space8),
              Text(
                message!,
                style: text.bodyMedium!.copyWith(color: c.onSurfaceMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null) ...[
              SizedBox(height: layout.space24),
              NeoButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: NeoButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
