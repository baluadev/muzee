import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/design_system/components/neo_icon_button.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/services/common_services.dart';

/// Heart next to the song title. Follows the liked list, so it stays in step
/// with likes made from other screens, and flips at once on tap (adding a
/// song looks up its details before the list changes).
class NowPlayingLikeButton extends StatefulWidget {
  const NowPlayingLikeButton({super.key, required this.audioId});

  final dynamic audioId;

  @override
  State<NowPlayingLikeButton> createState() => _NowPlayingLikeButtonState();
}

class _NowPlayingLikeButtonState extends State<NowPlayingLikeButton> {
  /// The state the user asked for while the update is still in flight.
  bool? _pending;

  @override
  void didUpdateWidget(NowPlayingLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioId != widget.audioId) _pending = null;
  }

  Future<void> _toggle(bool liked) async {
    final id = widget.audioId;
    setState(() => _pending = !liked);
    await updateSongLikeStatus(id, !liked);
    if (mounted && widget.audioId == id) setState(() => _pending = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    return ValueListenableBuilder<int>(
      valueListenable: currentLikedSongsLength,
      builder: (context, _, __) {
        final liked = _pending ?? isSongAlreadyLiked(widget.audioId);
        return NeoIconButton(
          icon: FluentIcons.heart_24_regular,
          selectedIcon: FluentIcons.heart_24_filled,
          isSelected: liked,
          tooltip: liked ? l10n.unlike : l10n.like,
          onPressed: () => _toggle(liked),
        );
      },
    );
  }
}
