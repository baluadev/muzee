import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/services/sleep_timer.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/flutter_toast.dart';

/// Preset lengths, in minutes.
const sleepTimerPresets = [5, 10, 15, 30, 45, 60, 90];

/// Opens the sleep timer: one tap on a length starts it (and closes the
/// sheet); while one runs, it counts down at the top with a "Turn off".
Future<void> showSleepTimerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.neo.surface,
    builder: (_) => const SleepTimerSheet(),
  );
}

class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final neo = context.neo;
    final text = Theme.of(context).textTheme;
    final timer = SleepTimer.instance;

    void done(String message) {
      Navigator.pop(context);
      showToast(context, message);
    }

    String stopsAt(Duration duration) {
      final at = TimeOfDay.fromDateTime(DateTime.now().add(duration));
      return l10n.sleepTimerStopsAt(
        MaterialLocalizations.of(context).formatTimeOfDay(
          at,
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        ),
      );
    }

    Future<void> pickTime() async {
      final now = DateTime.now();
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          now.add(const Duration(minutes: 30)),
        ),
      );
      if (picked == null || !context.mounted) return;
      var end = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      // A time already passed today means tomorrow.
      if (!end.isAfter(now)) end = end.add(const Duration(days: 1));
      final duration = end.difference(now);
      timer.start(duration);
      done(stopsAt(duration));
    }

    return ListenableBuilder(
      listenable: timer.changes,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(l10n.sleepTimer, style: text.titleLarge),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l10n.sleepTimerHint,
                style: text.bodyMedium?.copyWith(color: neo.onSurfaceMuted),
              ),
            ),
            if (timer.isActive) ...[
              const SizedBox(height: 16),
              _ActiveTimerCard(
                onTurnOff: () {
                  timer.turnOff();
                  done(l10n.sleepTimerCancelled);
                },
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in sleepTimerPresets)
                  _Choice(
                    label: l10n.sleepTimerMinutes(minutes),
                    onTap: () {
                      final duration = Duration(minutes: minutes);
                      timer.start(duration);
                      done(stopsAt(duration));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _Row(
              icon: FluentIcons.music_note_2_24_regular,
              label: l10n.sleepTimerEndOfSong,
              selected: timer.afterThisSong.value,
              onTap: () {
                timer.stopAfterThisSong();
                done(l10n.sleepTimerStopsAfterSong);
              },
            ),
            _Row(
              icon: FluentIcons.clock_24_regular,
              label: l10n.sleepTimerPickTime,
              onTap: pickTime,
            ),
          ],
        ),
      ),
    );
  }
}

/// The running timer: time left (ticking) or "after this song", and a way
/// to turn it off.
class _ActiveTimerCard extends StatefulWidget {
  const _ActiveTimerCard({required this.onTurnOff});
  final VoidCallback onTurnOff;

  @override
  State<_ActiveTimerCard> createState() => _ActiveTimerCardState();
}

class _ActiveTimerCardState extends State<_ActiveTimerCard> {
  late final Timer _tick = Timer.periodic(
    const Duration(seconds: 1),
    (_) => setState(() {}),
  );

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final neo = context.neo;
    final text = Theme.of(context).textTheme;
    final timer = SleepTimer.instance;
    final left = timer.remaining();
    final headline = left == null
        ? l10n.sleepTimerStopsAfterSong
        : l10n.sleepTimerRemaining(formatCountdown(left));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: neo.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(FluentIcons.timer_24_filled, color: neo.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              headline,
              style: text.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onTurnOff,
            child: Text(l10n.sleepTimerTurnOff),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    return Material(
      color: neo.surfaceRaised,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              widthFactor: 1,
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: selected ? neo.accent : neo.onSurfaceMuted),
      title: Text(label),
      trailing: selected
          ? Icon(FluentIcons.checkmark_24_regular, color: neo.accent)
          : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
