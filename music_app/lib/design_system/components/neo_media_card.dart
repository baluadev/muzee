import 'package:flutter/material.dart';
import 'package:muzee/design_system/components/neo_artwork.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_icons.dart';
import 'package:muzee/theme/neo/neo_layout.dart';

/// Square (or round, for artists) artwork with a title and subtitle below.
/// Used in horizontal shelves and grids.
class NeoMediaCard extends StatelessWidget {
  const NeoMediaCard({
    required this.title,
    this.subtitle,
    this.image,
    this.placeholderIcon = NeoIcons.song,
    this.circular = false,
    this.size,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final String title;
  final String? subtitle;
  final ImageProvider? image;
  final IconData placeholderIcon;
  final bool circular;

  /// Artwork edge; defaults to the card artwork size.
  final double? size;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final shapes = NeoShapes.of(context);
    final text = Theme.of(context).textTheme;
    final edge = size ?? layout.artworkCard;
    final align = circular ? TextAlign.center : TextAlign.start;

    return SizedBox(
      width: edge,
      child: MergeSemantics(
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: shapes.large,
          child: Column(
            crossAxisAlignment: circular
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              NeoArtwork(
                size: edge,
                image: image,
                placeholderIcon: placeholderIcon,
                circular: circular,
              ),
              SizedBox(height: layout.space8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: align,
                style: text.titleSmall,
              ),
              if (subtitle != null) ...[
                SizedBox(height: layout.space2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: align,
                  style: text.bodySmall!.copyWith(color: c.onSurfaceMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
