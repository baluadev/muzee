import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/pip_service.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/utilities/playlist_dialogs.dart';
import 'package:muzee/widgets/queue_list_view.dart';
import 'package:tuber_playback/tuber_playback.dart';

class BottomActionsRow extends StatefulWidget {
  const BottomActionsRow({
    super.key,
    required this.audioId,
    required this.metadata,
    required this.iconSize,
    required this.isLargeScreen,
    required this.lyricsController,
  });
  final dynamic audioId;
  final MediaItem metadata;
  final double iconSize;
  final bool isLargeScreen;
  final dynamic lyricsController;

  @override
  State<BottomActionsRow> createState() => _BottomActionsRowState();
}

class _BottomActionsRowState extends State<BottomActionsRow> {
  late final ValueNotifier<bool> _songLikeStatus;

  @override
  void initState() {
    super.initState();
    _songLikeStatus = ValueNotifier<bool>(isSongAlreadyLiked(widget.audioId));
  }

  @override
  void didUpdateWidget(BottomActionsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioId != widget.audioId) {
      _songLikeStatus.value = isSongAlreadyLiked(widget.audioId);
    }
  }

  @override
  void dispose() {
    _songLikeStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n!;
    final isVideo = widget.metadata.extras?['isVideo'] == true;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final responsiveIconSize = screenWidth < 360
        ? widget.iconSize * 0.85
        : widget.iconSize;

    return StreamBuilder<List<Map>>(
      stream: audioHandler.queueAsMapStream,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? [];

        final actions = <Widget>[
          _buildSimpleActionButton(
            context: context,
            icon: FluentIcons.window_multiple_16_regular,
            colorScheme: colorScheme,
            size: responsiveIconSize,
            onPressed: () => _enterPip(context, isVideo: isVideo),
            tooltip: l10n.floatingVideo,
          ),
          _buildSleepTimerButton(context, colorScheme, responsiveIconSize),
          _buildSimpleActionButton(
            context: context,
            icon: FluentIcons.album_add_24_regular,
            colorScheme: colorScheme,
            size: responsiveIconSize,
            onPressed: () => showAddToPlaylistDialog(
              context,
              song: mediaItemToMap(widget.metadata),
            ),
            tooltip: l10n.addToPlaylist,
          ),
          if (queue.isNotEmpty && !widget.isLargeScreen)
            _buildSimpleActionButton(
              context: context,
              icon: FluentIcons.apps_list_24_filled,
              colorScheme: colorScheme,
              size: responsiveIconSize,
              onPressed: () => _showQueueSheet(context),
              tooltip: l10n.queue,
            ),
          ...[
            _buildSimpleActionButton(
              context: context,
              icon: FluentIcons.text_quote_24_regular,
              colorScheme: colorScheme,
              size: responsiveIconSize,
              onPressed: widget.lyricsController.flipcard,
              tooltip: l10n.lyrics,
            ),
            _buildActionButton(
              context: context,
              icon: FluentIcons.heart_24_regular,
              activeIcon: FluentIcons.heart_24_filled,
              colorScheme: colorScheme,
              size: responsiveIconSize,
              statusNotifier: _songLikeStatus,
              activeColor: context.neo.accent,
              onPressed: () {
                updateSongLikeStatus(widget.audioId, !_songLikeStatus.value);
                _songLikeStatus.value = !_songLikeStatus.value;
              },
              tooltip: l10n.likedSongs,
            ),
          ],
        ];

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: actions,
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required ColorScheme colorScheme,
    required double size,
    required ValueNotifier<bool> statusNotifier,
    required VoidCallback? onPressed,
    Color? activeColor,
    String? tooltip,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: statusNotifier,
      builder: (_, isActive, __) {
        return IconButton(
          icon: Icon(
            isActive ? activeIcon : icon,
            color: isActive
                ? (activeColor ?? colorScheme.primary)
                : colorScheme.onSurfaceVariant,
          ),
          iconSize: size,
          tooltip: tooltip,
          style: IconButton.styleFrom(
            backgroundColor: isActive
                ? (activeColor ?? colorScheme.primary).withValues(alpha: 0.15)
                : Colors.transparent,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
        );
      },
    );
  }

  Widget _buildSimpleActionButton({
    required BuildContext context,
    required IconData icon,
    required ColorScheme colorScheme,
    required double size,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, color: colorScheme.onSurfaceVariant),
      iconSize: size,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildSleepTimerButton(
    BuildContext context,
    ColorScheme colorScheme,
    double size,
  ) {
    return ValueListenableBuilder<Duration?>(
      valueListenable: sleepTimerNotifier,
      builder: (_, value, __) {
        final isActive = value != null;
        return IconButton(
          icon: Icon(
            isActive
                ? FluentIcons.timer_24_filled
                : FluentIcons.timer_24_regular,
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          iconSize: size,
          tooltip: context.l10n!.sleepTimer,
          style: IconButton.styleFrom(
            backgroundColor: isActive
                ? colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (isActive) {
              audioHandler.cancelSleepTimer();
              sleepTimerNotifier.value = null;
              showToast(
                context,
                context.l10n!.sleepTimerCancelled,
                duration: const Duration(seconds: 1, milliseconds: 500),
              );
            } else {
              _showSleepTimerDialog(context);
            }
          },
        );
      },
    );
  }

  Future<void> _enterPip(BuildContext context, {required bool isVideo}) async {
    if (!isVideo) {
      showToast(context, context.l10n!.floatingVideoVideoOnly);
      return;
    }

    final entered = await PipService.enterImmediatePip();
    if (!entered && context.mounted) {
      showToast(context, context.l10n!.floatingVideoUnsupported);
    }
  }
}

/// The queue as a modal sheet: drag it up to see more, down to close.
void _showQueueSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.neo.surface,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => QueueWidget(
        isBottomSheet: true,
        sheetScrollController: scrollController,
      ),
    ),
  );
}

void _showSleepTimerDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      final duration = sleepTimerNotifier.value ?? Duration.zero;
      var totalMinutes = duration.inMinutes;
      if (totalMinutes == 0) totalMinutes = 45;

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: context.neo.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.neo.hairline),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n!.sleepTimer,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: context.neo.onSurface,
                          height: 28 / 18,
                        ),
                      ),
                      Icon(
                        FluentIcons.timer_24_regular,
                        color: context.neo.onSurface,
                        size: 21,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (totalMinutes > 5) {
                              setState(() => totalMinutes -= 5);
                            } else {
                              setState(() => totalMinutes = 0);
                            }
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: context.neo.surfaceRaised,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                FluentIcons.line_horizontal_1_24_regular,
                                color: context.neo.onSurface,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        Column(
                          children: [
                            Text(
                              '$totalMinutes',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 48,
                                    color: context.neo.accent,
                                    height: 1,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n!.minutes,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    color: context.neo.onSurfaceMuted,
                                    letterSpacing: 1,
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 32),
                        GestureDetector(
                          onTap: () {
                            setState(() => totalMinutes += 5);
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: context.neo.surfaceRaised,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                FluentIcons.add_24_regular,
                                color: context.neo.onSurface,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [15, 30, 45, 60].map((mins) {
                      final isSelected = totalMinutes == mins;
                      return GestureDetector(
                        onTap: () {
                          setState(() => totalMinutes = mins);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.neo.accent
                                : context.neo.surfaceRaised,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${mins}m',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                  color: isSelected
                                      ? context.neo.onAccent
                                      : context.neo.onSurface,
                                  height: 20 / 14,
                                ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: context.neo.surfaceRaised,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              context.l10n!.cancel,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: context.neo.onSurface,
                                    height: 24 / 16,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final duration = Duration(minutes: totalMinutes);
                            if (duration.inSeconds > 0) {
                              audioHandler.setSleepTimer(duration);
                              showToast(
                                context,
                                context.l10n!.sleepTimerSet,
                                duration: const Duration(
                                  seconds: 1,
                                  milliseconds: 500,
                                ),
                              );
                            }
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: context.neo.accent,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              context.l10n!.setTimer,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: context.neo.onAccent,
                                    height: 24 / 16,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
