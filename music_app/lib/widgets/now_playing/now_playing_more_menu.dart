import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/services/pip_service.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/utilities/playlist_dialogs.dart';
import 'package:tuber_playback/tuber_playback.dart';

enum _MoreAction { addToPlaylist, floatingVideo }

/// The player's less frequent actions, behind the ⋮ in its top bar.
/// Floating video is only offered while a video is playing.
class NowPlayingMoreMenu extends StatelessWidget {
  const NowPlayingMoreMenu({super.key, required this.metadata});

  final MediaItem metadata;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final neo = context.neo;
    final isVideo = metadata.extras?['isVideo'] == true;

    PopupMenuItem<_MoreAction> item(
      _MoreAction value,
      IconData icon,
      String label,
    ) => PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: neo.onSurface),
          const SizedBox(width: 12),
          Flexible(child: Text(label)),
        ],
      ),
    );

    return PopupMenuButton<_MoreAction>(
      tooltip: l10n.moreOptions,
      icon: Icon(FluentIcons.more_vertical_24_regular, color: neo.onSurface),
      color: neo.surfaceRaised,
      onSelected: (action) {
        switch (action) {
          case _MoreAction.addToPlaylist:
            showAddToPlaylistDialog(context, song: mediaItemToMap(metadata));
          case _MoreAction.floatingVideo:
            _enterPip(context);
        }
      },
      itemBuilder: (_) => [
        item(
          _MoreAction.addToPlaylist,
          FluentIcons.album_add_24_regular,
          l10n.addToPlaylist,
        ),
        if (isVideo)
          item(
            _MoreAction.floatingVideo,
            FluentIcons.window_multiple_16_regular,
            l10n.floatingVideo,
          ),
      ],
    );
  }

  Future<void> _enterPip(BuildContext context) async {
    final entered = await PipService.enterImmediatePip();
    if (!entered && context.mounted) {
      showToast(context, context.l10n!.floatingVideoUnsupported);
    }
  }
}
