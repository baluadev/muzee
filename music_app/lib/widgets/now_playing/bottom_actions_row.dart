import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/services/sleep_timer.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/widgets/now_playing/sleep_timer_sheet.dart';
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
            const Expanded(child: _SleepTimerAction()),
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

/// Sleep timer in the action row: shows the time left while it runs, and
/// opens the sleep timer sheet.
class _SleepTimerAction extends StatefulWidget {
  const _SleepTimerAction();

  @override
  State<_SleepTimerAction> createState() => _SleepTimerActionState();
}

class _SleepTimerActionState extends State<_SleepTimerAction> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    SleepTimer.instance.changes.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    SleepTimer.instance.changes.removeListener(_sync);
    _tick?.cancel();
    super.dispose();
  }

  /// Ticks once a second only while a timed timer runs.
  void _sync() {
    final counting = SleepTimer.instance.endsAt.value != null;
    if (counting && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!counting) {
      _tick?.cancel();
      _tick = null;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final timer = SleepTimer.instance;
    final left = timer.remaining();
    return _LabeledAction(
      icon: FluentIcons.timer_24_regular,
      activeIcon: FluentIcons.timer_24_filled,
      label: left != null
          ? formatCountdown(left)
          : timer.afterThisSong.value
          ? l10n.sleepTimerEndOfSong
          : l10n.sleepTimer,
      isActive: timer.isActive,
      onPressed: () => showSleepTimerSheet(context),
    );
  }
}
