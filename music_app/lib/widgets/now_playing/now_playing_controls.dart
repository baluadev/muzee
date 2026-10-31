import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/settings_manager.dart';

import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/widgets/playback_icon_button.dart';
import 'package:muzee/widgets/position_slider.dart';

class NowPlayingControls extends StatelessWidget {
  const NowPlayingControls({
    super.key,
    required this.size,
    required this.audioId,
    required this.adjustedIconSize,
    required this.adjustedMiniIconSize,
    required this.metadata,
  });

  final Size size;
  final dynamic audioId;
  final double adjustedIconSize;
  final double adjustedMiniIconSize;
  final MediaItem metadata;

  @override
  Widget build(BuildContext context) {
    final isDesktop = size.width > 800;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isCompact = availableHeight < 280;
        final isVeryCompact = availableHeight < 200;

        final spacing = isVeryCompact
            ? 2.0
            : isCompact
            ? 4.0
            : 8.0;
        final iconScale = isVeryCompact
            ? 0.65
            : isCompact
            ? 0.75
            : 1.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompact) const Spacer(),
            if (!isCompact) const Spacer(),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 400 : constraints.maxWidth,
              ),
              child: const PositionSlider(),
            ),
            SizedBox(height: spacing),
            PlayerControlButtons(
              metadata: metadata,
              iconSize: adjustedIconSize * iconScale,
              miniIconSize: adjustedMiniIconSize * iconScale,
            ),
            if (!isCompact) const Spacer(),
          ],
        );
      },
    );
  }
}

/// Shuffle · previous · play/pause · next · repeat. Shuffle and repeat show
/// their state with a filled icon and a dot underneath, never color alone.
class PlayerControlButtons extends StatelessWidget {
  const PlayerControlButtons({
    super.key,
    required this.metadata,
    required this.iconSize,
    required this.miniIconSize,
  });
  final MediaItem metadata;
  final double iconSize;
  final double miniIconSize;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    final l10n = context.l10n!;
    final skipSize = iconSize * 0.8;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: StreamBuilder<List<MediaItem>>(
        stream: audioHandler.queue,
        builder: (context, snapshot) {
          final queue = snapshot.data ?? const [];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ValueListenableBuilder<bool>(
                valueListenable: shuffleNotifier,
                builder: (_, on, __) => _ModeButton(
                  active: on,
                  icon: on
                      ? FluentIcons.arrow_shuffle_24_filled
                      : FluentIcons.arrow_shuffle_24_regular,
                  size: miniIconSize,
                  tooltip: on ? l10n.shuffleOn : l10n.shuffleOff,
                  onPressed: () => audioHandler.setShuffleMode(
                    on
                        ? AudioServiceShuffleMode.none
                        : AudioServiceShuffleMode.all,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.skipToPrevious,
                iconSize: skipSize,
                color: neo.onSurface,
                disabledColor: neo.onSurfaceSubtle,
                icon: const Icon(FluentIcons.previous_24_filled),
                onPressed: audioHandler.hasPrevious
                    ? audioHandler.skipToPrevious
                    : null,
              ),
              PlaybackIconButton(
                iconColor: neo.onAccent,
                backgroundColor: neo.accent,
                iconSize: iconSize,
                padding: EdgeInsets.all(iconSize * 0.4),
              ),
              IconButton(
                tooltip: l10n.skipToNext,
                iconSize: skipSize,
                color: neo.onSurface,
                icon: const Icon(FluentIcons.next_24_filled),
                onPressed: () =>
                    repeatNotifier.value == AudioServiceRepeatMode.one
                    ? audioHandler.playAgain()
                    : audioHandler.skipToNext(),
              ),
              ValueListenableBuilder<AudioServiceRepeatMode>(
                valueListenable: repeatNotifier,
                builder: (_, mode, __) => _ModeButton(
                  active: mode != AudioServiceRepeatMode.none,
                  icon: switch (mode) {
                    AudioServiceRepeatMode.one =>
                      FluentIcons.arrow_repeat_1_24_filled,
                    AudioServiceRepeatMode.none =>
                      FluentIcons.arrow_repeat_all_24_regular,
                    _ => FluentIcons.arrow_repeat_all_24_filled,
                  },
                  size: miniIconSize,
                  tooltip: switch (mode) {
                    AudioServiceRepeatMode.one => l10n.repeatOne,
                    AudioServiceRepeatMode.none => l10n.repeatOff,
                    _ => l10n.repeatAll,
                  },
                  onPressed: () {
                    // Off → all (one for a single song) → one → off.
                    final next = switch (mode) {
                      AudioServiceRepeatMode.none =>
                        queue.length <= 1
                            ? AudioServiceRepeatMode.one
                            : AudioServiceRepeatMode.all,
                      AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
                      _ => AudioServiceRepeatMode.none,
                    };
                    repeatNotifier.value = next;
                    audioHandler.setRepeatMode(next);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.active,
    required this.icon,
    required this.size,
    required this.tooltip,
    required this.onPressed,
  });

  final bool active;
  final IconData icon;
  final double size;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    return Semantics(
      toggled: active,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            tooltip: tooltip,
            iconSize: size,
            color: active ? neo.onSurface : neo.onSurfaceMuted,
            icon: Icon(icon),
            onPressed: onPressed,
          ),
          Positioned(
            bottom: 2,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: neo.onSurface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
