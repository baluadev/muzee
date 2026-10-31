import 'package:flutter/material.dart';
import 'package:muzee/design_system/components/neo_directional_icon.dart';
import 'package:muzee/theme/neo/neo_icons.dart';
import 'package:muzee/theme/neo/neo_layout.dart';
import 'package:muzee/theme/neo/neo_typography.dart';

/// Section title with an optional eyebrow and a trailing "See all" action.
class NeoSectionHeader extends StatelessWidget {
  const NeoSectionHeader({
    required this.title,
    this.eyebrow,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction go together.',
       );

  final String title;
  final String? eyebrow;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final layout = NeoLayout.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.gutter),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (eyebrow != null) ...[
                    Text(eyebrow!, style: NeoTypeExtras.of(context).eyebrow),
                    SizedBox(height: layout.space4),
                  ],
                  Text(
                    title,
                    style: text.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  SizedBox(width: layout.space4),
                  NeoDirectionalIcon(
                    NeoIcons.chevronRight,
                    size: layout.iconSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
