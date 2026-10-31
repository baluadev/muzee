import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/theme/neo/neo_colors.dart';

/// Play and Shuffle, side by side under a playlist or song list header.
///
/// Labels take the buttons' own text color (never a text theme style, whose
/// color would win over it), and shrink rather than wrap when a language's
/// words are long ("Phát ngẫu nhiên").
class PlayShuffleButtons extends StatelessWidget {
  const PlayShuffleButtons({
    super.key,
    required this.onPlay,
    required this.onShuffle,
  });

  final VoidCallback onPlay;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final neo = context.neo;
    final textStyle = Theme.of(context).textTheme.titleMedium;
    const padding = EdgeInsets.symmetric(horizontal: 16);

    Widget label(String text) =>
        FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(FluentIcons.play_24_filled),
              label: label(l10n.play),
              style: FilledButton.styleFrom(
                backgroundColor: neo.accent,
                foregroundColor: neo.onAccent,
                textStyle: textStyle,
                padding: padding,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton.tonalIcon(
              onPressed: onShuffle,
              icon: const Icon(FluentIcons.arrow_shuffle_24_regular),
              label: label(l10n.shufflePlay),
              style: FilledButton.styleFrom(
                backgroundColor: neo.surfaceRaised,
                foregroundColor: neo.onSurface,
                textStyle: textStyle,
                padding: padding,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
