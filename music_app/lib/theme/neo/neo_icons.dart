/*
 * Neon Tube — icon vocabulary. Components ask for a meaning (`NeoIcons.play`),
 * so swapping the icon family is one edit here.
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/widgets.dart';

abstract final class NeoIcons {
  static const IconData play = FluentIcons.play_24_filled;
  static const IconData pause = FluentIcons.pause_24_filled;
  static const IconData next = FluentIcons.next_24_filled;
  static const IconData previous = FluentIcons.previous_24_filled;
  static const IconData shuffle = FluentIcons.arrow_shuffle_24_regular;
  static const IconData repeat = FluentIcons.arrow_repeat_all_24_regular;
  static const IconData sleepTimer = FluentIcons.timer_24_regular;
  static const IconData nowPlaying = FluentIcons.data_bar_vertical_24_filled;

  static const IconData like = FluentIcons.heart_24_regular;
  static const IconData liked = FluentIcons.heart_24_filled;
  static const IconData more = FluentIcons.more_vertical_24_regular;
  static const IconData add = FluentIcons.add_24_regular;
  static const IconData check = FluentIcons.checkmark_24_regular;

  static const IconData search = FluentIcons.search_24_regular;
  static const IconData clear = FluentIcons.dismiss_circle_24_filled;
  static const IconData close = FluentIcons.dismiss_24_regular;
  static const IconData chevronRight = FluentIcons.chevron_right_24_regular;
  static const IconData arrowRight = FluentIcons.arrow_right_24_regular;

  static const IconData song = FluentIcons.music_note_2_24_regular;
  static const IconData folder = FluentIcons.folder_24_regular;
  static const IconData artist = FluentIcons.person_24_regular;
  static const IconData premium = FluentIcons.diamond_24_regular;
  static const IconData settings = FluentIcons.settings_24_regular;
}
