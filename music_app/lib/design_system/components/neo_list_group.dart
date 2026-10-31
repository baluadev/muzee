import 'package:flutter/material.dart';
import 'package:muzee/design_system/components/neo_directional_icon.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_icons.dart';
import 'package:muzee/theme/neo/neo_layout.dart';

/// Rows grouped on one surface card with inset dividers (settings, library).
class NeoListGroup extends StatelessWidget {
  const NeoListGroup({required this.children, this.title, super.key});

  final List<Widget> children;

  /// Small label above the card.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final shapes = NeoShapes.of(context);
    final text = Theme.of(context).textTheme;
    final dividerIndent = layout.space16 + layout.iconLarge + layout.space16;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: layout.space4,
                bottom: layout.space8,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  title!,
                  style: text.labelMedium!.copyWith(color: c.onSurfaceMuted),
                ),
              ),
            ),
          Material(
            color: c.surface,
            shape: shapes.cardShape(),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) Divider(indent: dividerIndent),
                  child,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum NeoListRowTone { normal, danger }

/// One row inside a [NeoListGroup].
class NeoListRow extends StatelessWidget {
  const NeoListRow({
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.tone = NeoListRowTone.normal,
    super.key,
  });

  /// Row with a switch; tapping anywhere on the row flips it.
  NeoListRow.toggle({
    required this.title,
    required bool value,
    required ValueChanged<bool>? onChanged,
    this.subtitle,
    this.leadingIcon,
    super.key,
  }) : trailing = Switch(value: value, onChanged: onChanged),
       onTap = onChanged == null ? null : (() => onChanged(!value)),
       tone = NeoListRowTone.normal;

  /// Row that opens another page.
  const NeoListRow.navigation({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leadingIcon,
    super.key,
  }) : trailing = const _Chevron(),
       tone = NeoListRowTone.normal;

  /// Row showing the current value of a setting, opening a picker on tap.
  NeoListRow.value({
    required this.title,
    required String value,
    required this.onTap,
    this.subtitle,
    this.leadingIcon,
    super.key,
  }) : trailing = _ValueTrailing(value),
       tone = NeoListRowTone.normal;

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final NeoListRowTone tone;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final text = Theme.of(context).textTheme;
    final isDanger = tone == NeoListRowTone.danger;

    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: layout.listRowMinHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: layout.space16,
              vertical: layout.space12,
            ),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: layout.iconLarge,
                    color: isDanger ? c.danger : c.onSurfaceMuted,
                  ),
                  SizedBox(width: layout.space16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: text.bodyLarge!.copyWith(
                          color: isDanger ? c.danger : c.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: layout.space2),
                        Text(
                          subtitle!,
                          style: text.bodySmall!.copyWith(
                            color: c.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: layout.space12),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return NeoDirectionalIcon(
      NeoIcons.chevronRight,
      size: NeoLayout.of(context).iconMedium,
      color: NeoColors.of(context).onSurfaceSubtle,
    );
  }
}

class _ValueTrailing extends StatelessWidget {
  const _ValueTrailing(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final layout = NeoLayout.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: NeoColors.of(context).onSurfaceMuted,
          ),
        ),
        SizedBox(width: layout.space4),
        const _Chevron(),
      ],
    );
  }
}
