import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/core/widget_extension.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';
import 'package:muzee/models/song_model.dart';

class RoundPlayButton extends StatelessWidget {
  final List<SongModel> songs;
  const RoundPlayButton({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 6.w,
      ),
      decoration: const BoxDecoration(
        color: MyColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(FlutterRemix.play_fill),
    ).attachGestureDetector(onTap: () => myPlayerService.setQueue(songs));
  }
}
