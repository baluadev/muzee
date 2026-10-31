import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_layout.dart';

enum NeoIconButtonVariant {
  /// No container: toolbar and row actions.
  plain,

  /// Raised circle: the circular action buttons on playlist and player pages.
  tonal,
}

/// Icon button with a required tooltip (it doubles as the screen-reader label).
///
/// Pass [isSelected] to make it a toggle. "On" is carried by three signals:
/// the [selectedIcon] glyph, the accent color, and the toggled semantics.
class NeoIconButton extends StatelessWidget {
  const NeoIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selectedIcon,
    this.isSelected,
    this.variant = NeoIconButtonVariant.plain,
    super.key,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Null for a plain action, true/false for a toggle.
  final bool? isSelected;
  final NeoIconButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final isToggle = isSelected != null;
    final restColor = isToggle ? c.onSurfaceMuted : c.onSurface;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      isSelected: isSelected,
      icon: Icon(icon),
      selectedIcon: selectedIcon == null ? null : Icon(selectedIcon),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return c.onSurfaceSubtle;
          if (states.contains(WidgetState.selected)) return c.accent;
          return restColor;
        }),
        backgroundColor: WidgetStatePropertyAll(
          variant == NeoIconButtonVariant.tonal
              ? c.surfaceRaised
              : Colors.transparent,
        ),
        overlayColor: WidgetStatePropertyAll(c.pressedOverlay),
        minimumSize: WidgetStatePropertyAll(Size.square(layout.minTouchTarget)),
        iconSize: WidgetStatePropertyAll(layout.iconLarge),
        shape: const WidgetStatePropertyAll(CircleBorder()),
      ),
    );
  }
}
