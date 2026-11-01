import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/theme/neo/neo_colors.dart';

/// Cover, title and "owner · N songs" at the top of a playlist, album or
/// song list.
class PlaylistHeader extends StatelessWidget {
  const PlaylistHeader(
    this.image,
    this.title,
    this.songsLength, {
    super.key,
    this.isAlbum,
    this.owner,
  });

  final Widget image;
  final String title;
  final int songsLength;
  final bool? isAlbum;

  /// Who made it: "Your playlist", an artist, "YouTube"… Defaults to
  /// "Created by Muzee" (the app's own song lists); empty hides it.
  final String? owner;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final neo = context.neo;
    final ownerText = owner ?? context.l10n!.createdByApp;
    final details = [
      if (ownerText.isNotEmpty) ownerText,
      context.l10n!.songCount(songsLength),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ConstrainedBox(
              // Leaves the title and Play button above the fold on phones.
              constraints: const BoxConstraints(maxWidth: 260),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                // Centred: an image smaller than the box would otherwise sit
                // in its top-left corner.
                child: AspectRatio(aspectRatio: 1, child: Center(child: image)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            details,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(color: neo.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
