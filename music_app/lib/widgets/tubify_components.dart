import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';

class PrimaryNeonButton extends StatelessWidget {
  const PrimaryNeonButton({
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(0, 56),
      ),
      child: isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.onPrimary,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 24),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }
}

class TubifySettingsSection extends StatelessWidget {
  const TubifySettingsSection({
    required this.title,
    required this.children,
    super.key,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24), // gap-[24px] between sections
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
            // Sentence case: all caps makes Vietnamese diacritics hard to read.
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.neo.onSurfaceMuted,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.neo.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: children.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                final isLastItem = index == children.length - 1;
                return Column(
                  children: [
                    child,
                    if (!isLastItem)
                      Divider(
                        height: 1,
                        color: context.neo.hairline, // rgba(255,255,255,0.05)
                        indent: 0,
                        endIndent: 0,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class TubifySettingsTile extends StatelessWidget {
  const TubifySettingsTile({
    required this.title,
    required this.icon,
    this.iconColor,
    this.trailing,
    this.trailingText,
    this.subtitle,
    this.onTap,
    super.key,
  });
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;
  final String? trailingText;

  /// One line under the title, e.g. what a switch does.
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? context.neo.onSurfaceMuted,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.neo.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.neo.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailingText != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    trailingText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.neo.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                FluentIcons.chevron_right_24_regular,
                color: context.neo.onSurfaceMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
