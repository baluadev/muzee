import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:muzee/widgets/muzee_artwork.dart';

class SongArtworkWidget extends StatelessWidget {
  const SongArtworkWidget({
    super.key,
    required this.size,
    this.height,
    required this.metadata,
    this.borderRadius = 10.0,
    this.errorWidgetIconSize = 20.0,
  });
  final double size;
  final double? height;
  final MediaItem metadata;
  final double borderRadius;
  final double errorWidgetIconSize;

  @override
  Widget build(BuildContext context) {
    return metadata.artUri?.scheme == 'file'
        ? SizedBox(
            width: size,
            height: height ?? size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.file(
                File(metadata.extras?['artWorkPath']),
                fit: BoxFit.cover,
              ),
            ),
          )
        : MuzeeArtwork(
            // In the app, the sharpest thumbnail (it steps down by itself
            // when missing); artUri is the notification's smaller one.
            url:
                metadata.extras?['highResImage']?.toString() ??
                metadata.artUri?.toString(),
            width: size,
            height: height ?? size,
            borderRadius: borderRadius,
            iconSize: errorWidgetIconSize,
          );
  }
}
