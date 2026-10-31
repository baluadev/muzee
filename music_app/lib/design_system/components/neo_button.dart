import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_layout.dart';
import 'package:muzee/theme/neo/neo_motion.dart';

enum NeoButtonVariant {
  /// Lime pill. One per screen.
  primary,

  /// Raised neutral pill.
  secondary,

  /// Transparent pill with a meaningful outline.
  outline,

  /// Text-only accent action.
  ghost,

  /// Destructive action.
  danger,
}

enum NeoButtonSize { medium, large }

/// Pill button. While [isLoading] the label stays in the tree (invisible) so
/// width does not jump and screen readers still announce it.
class NeoButton extends StatelessWidget {
  const NeoButton({
    required this.label,
    required this.onPressed,
    this.variant = NeoButtonVariant.primary,
    this.size = NeoButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final NeoButtonVariant variant;
  final NeoButtonSize size;
  final IconData? icon;
  final bool isLoading;

  /// Stretch to the parent's width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final text = Theme.of(context).textTheme;
    final isLarge = size == NeoButtonSize.large;

    final (background, foreground, side) = switch (variant) {
      NeoButtonVariant.primary => (c.accent, c.onAccent, BorderSide.none),
      NeoButtonVariant.secondary => (
        c.surfaceRaised,
        c.onSurface,
        BorderSide.none,
      ),
      NeoButtonVariant.outline => (
        Colors.transparent,
        c.onSurface,
        BorderSide(color: c.outline, width: layout.hairlineWidth),
      ),
      NeoButtonVariant.ghost => (Colors.transparent, c.accent, BorderSide.none),
      NeoButtonVariant.danger => (
        c.dangerSoft,
        c.onDangerSoft,
        BorderSide.none,
      ),
    };
    final hasFill = background != Colors.transparent;
    final enabled = onPressed != null && !isLoading;

    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled) && !isLoading && hasFill) {
          return c.surfaceRaised;
        }
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled) && !isLoading) {
          return c.onSurfaceSubtle;
        }
        return foreground;
      }),
      overlayColor: WidgetStatePropertyAll(c.pressedOverlay),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: WidgetStatePropertyAll(
        Size(
          expand ? double.infinity : 0,
          isLarge ? layout.controlHeightLarge : layout.controlHeight,
        ),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: isLarge ? layout.space32 : layout.space24,
        ),
      ),
      shape: WidgetStatePropertyAll(StadiumBorder(side: side)),
      textStyle: WidgetStatePropertyAll(
        isLarge ? text.titleMedium : text.labelLarge,
      ),
      iconSize: WidgetStatePropertyAll(layout.iconMedium),
      animationDuration: resolveMotion(context, NeoMotion.of(context).quick),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon), SizedBox(width: layout.space8)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final button = TextButton(
      onPressed: enabled ? onPressed : null,
      style: style,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Visibility.maintain(visible: !isLoading, child: content),
          if (isLoading)
            SizedBox.square(
              dimension: layout.iconMedium,
              child: CircularProgressIndicator(
                strokeWidth: layout.focusWidth,
                color: foreground,
              ),
            ),
        ],
      ),
    );

    if (variant != NeoButtonVariant.primary || !isLarge || !enabled) {
      return button;
    }
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        shadows: NeoEffects.of(context).accentGlow,
      ),
      child: button,
    );
  }
}
