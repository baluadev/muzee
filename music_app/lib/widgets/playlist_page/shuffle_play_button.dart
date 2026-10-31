import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';

class ShufflePlayButton extends StatelessWidget {
  const ShufflePlayButton({super.key, required this.songs});

  final List songs;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      icon: const Icon(FluentIcons.arrow_shuffle_24_regular),
      iconSize: 24,
      tooltip: context.l10n!.shufflePlay,
      onPressed: () async {
        if (songs.isEmpty) return;
        final shuffledSongs = List<Map>.from(songs.whereType<Map>());
        if (shuffledSongs.isEmpty) return;
        shuffledSongs.shuffle();
        await audioHandler.addPlaylistToQueue(
          shuffledSongs,
          replace: true,
          startIndex: 0,
        );
      },
    );
  }
}
