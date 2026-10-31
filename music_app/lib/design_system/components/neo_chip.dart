import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_icons.dart';
import 'package:muzee/theme/neo/neo_layout.dart';
import 'package:muzee/theme/neo/neo_motion.dart';

/// Filter / category chip.
///
/// Selected is carried by fill (lime), a check glyph, a heavier label and the
/// selected semantics, so it survives a greyscale screen.
class NeoChip extends StatelessWidget {
  const NeoChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  /// Leading icon when not selected; replaced by a check when selected.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final shapes = NeoShapes.of(context);
    final motion = NeoMotion.of(context);
    final labelStyle = Theme.of(context).textTheme.labelMedium!;

    final background = selected ? c.accent : c.surfaceRaised;
    final foreground = selected ? c.onAccent : c.onSurface;
    final leading = selected ? NeoIcons.check : icon;
    final onTap = onSelected == null ? null : () => onSelected!(!selected);

    final chip = AnimatedContainer(
      duration: resolveMotion(context, motion.quick),
      curve: motion.enter,
      constraints: BoxConstraints(minHeight: layout.chipHeight),
      decoration: ShapeDecoration(
        color: background,
        shape: shapes.controlShape(),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: shapes.controlShape(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.space12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  Icon(leading, size: layout.iconSmall, color: foreground),
                  SizedBox(width: layout.space4),
                ],
                Text(
                  label,
                  style: labelStyle.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // The visual chip is shorter than the minimum touch target; the padding
    // band above and below still triggers the same action.
    final verticalSlack = (layout.minTouchTarget - layout.chipHeight) / 2;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        excludeFromSemantics: true,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: verticalSlack > 0 ? verticalSlack : 0,
          ),
          child: chip,
        ),
      ),
    );
  }
}
