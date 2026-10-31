import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:shimmer/shimmer.dart';

// Skeleton colors follow the theme surfaces.
extension on BuildContext {
  Color get _baseColor => neo.surface;
  Color get _highlightColor => neo.surfaceRaised;
}

class ShimmerHeroBanner extends StatelessWidget {
  const ShimmerHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 390),
      child: AspectRatio(
        aspectRatio: 1,
        child: Shimmer.fromColors(
          baseColor: context._baseColor,
          highlightColor: context._highlightColor,
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}

class ShimmerPlaylistCard extends StatelessWidget {
  const ShimmerPlaylistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 144,
      child: Shimmer.fromColors(
        baseColor: context._baseColor,
        highlightColor: context._highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 144,
              height: 142,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 120,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerArtistCard extends StatelessWidget {
  const ShimmerArtistCard({super.key, this.size = 128});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context._baseColor,
      highlightColor: context._highlightColor,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: size * 0.7,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerSongBar extends StatelessWidget {
  const ShimmerSongBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Shimmer.fromColors(
        baseColor: context._baseColor,
        highlightColor: context._highlightColor,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.neo.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerSuggestedCard extends StatelessWidget {
  const ShimmerSuggestedCard({super.key, this.width = 280});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context._baseColor,
      highlightColor: context._highlightColor,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: context.neo.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.neo.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: width * 0.6,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: width * 0.4,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
