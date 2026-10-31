import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_layout.dart';

enum NeoBadgeTone { accent, secondary, neutral, danger }

/// Small pill label (Premium, Offline, New). Always carries text, so the tone
/// color is never the only signal.
class NeoBadge extends StatelessWidget {
  const NeoBadge({
    required this.label,
    this.tone = NeoBadgeTone.accent,
    this.icon,
    super.key,
  });

  final String label;
  final NeoBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);

    final (background, foreground) = switch (tone) {
      NeoBadgeTone.accent => (c.accentSoft, c.onAccentSoft),
      NeoBadgeTone.secondary => (c.secondarySoft, c.onSecondarySoft),
      NeoBadgeTone.neutral => (c.surfaceRaised, c.onSurfaceMuted),
      NeoBadgeTone.danger => (c.dangerSoft, c.onDangerSoft),
    };

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: layout.space8,
          vertical: layout.space2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: layout.iconSmall, color: foreground),
              SizedBox(width: layout.space4),
            ],
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall!.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
