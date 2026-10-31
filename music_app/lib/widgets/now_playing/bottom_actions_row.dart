import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/widgets/queue_list_view.dart';

/// Lyrics · sleep timer · queue, each with a visible label. The queue is left
/// out on large screens, where it sits beside the player.
class BottomActionsRow extends StatelessWidget {
  const BottomActionsRow({
    super.key,
    required this.isLargeScreen,
    required this.lyricsController,
  });
  final bool isLargeScreen;
  final FlipCardController lyricsController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;

    return StreamBuilder<List<Map>>(
      stream: audioHandler.queueAsMapStream,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? const [];
        return Row(
          children: [
            Expanded(
              child: _LabeledAction(
                icon: FluentIcons.text_quote_24_regular,
                label: l10n.lyrics,
                onPressed: offlineMode.value ? null : lyricsController.flipcard,
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<Duration?>(
                valueListenable: sleepTimerNotifier,
                builder: (context, value, _) => _LabeledAction(
                  icon: FluentIcons.timer_24_regular,
                  activeIcon: FluentIcons.timer_24_filled,
                  label: l10n.sleepTimer,
                  isActive: value != null,
                  onPressed: () => _onSleepTimerPressed(context, value),
                ),
              ),
            ),
            if (!isLargeScreen)
              Expanded(
                child: _LabeledAction(
                  icon: FluentIcons.apps_list_24_regular,
                  label: l10n.queue,
                  onPressed: queue.isEmpty
                      ? null
                      : () => _showQueueSheet(context),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onSleepTimerPressed(BuildContext context, Duration? current) {
    if (current == null) {
      _showSleepTimerDialog(context);
      return;
    }
    audioHandler.cancelSleepTimer();
    sleepTimerNotifier.value = null;
    showToast(
      context,
      context.l10n!.sleepTimerCancelled,
      duration: const Duration(seconds: 1, milliseconds: 500),
    );
  }
}

/// Icon over a short label. "On" is shown by the filled glyph, the accent
/// color and the toggled semantics, never color alone.
class _LabeledAction extends StatelessWidget {
  const _LabeledAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.activeIcon,
    this.isActive,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final VoidCallback? onPressed;

  /// Null for a plain action, true/false for a toggle.
  final bool? isActive;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    final active = isActive ?? false;
    final color = onPressed == null
        ? neo.onSurfaceSubtle
        : active
        ? neo.accent
        : neo.onSurfaceMuted;

    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        toggled: isActive,
        enabled: onPressed != null,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(active ? (activeIcon ?? icon) : icon, color: color),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
