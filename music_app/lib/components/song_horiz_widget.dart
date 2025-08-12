import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/player/muzee_player_cubit.dart';
import 'package:muzee/components/waveform_animation.dart';
import 'package:muzee/core/widget_extension.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';
import 'package:muzee/models/song_model.dart';
import 'image_song_widget.dart';

class SongHorizWidget extends StatelessWidget {
  final SongModel song;
  final String? keyword;
  final Widget? optionMenu;
  const SongHorizWidget({
    super.key,
    required this.song,
    this.keyword,
    this.optionMenu,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuzeePlayerCubit, MuzeePlayerState>(
        builder: (context, state) {
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Row(
          children: [
            ImageSongWidget(
              id: song.songId,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: MyColors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: MyColors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            if (state.currentSong != null &&
                state.currentSong?.songId == song.songId)
              Container(
                width: 18,
                height: 24,
                margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                child: const WaveformAnimation(),
              ),
            if (optionMenu != null)
              Align(
                alignment: Alignment.centerRight,
                child: optionMenu,
              ),
          ],
        ),
      ).attachGestureDetector(onTap: () {
        final fixSong = song.copyWith(keyword: keyword);
        myPlayerService.setQueue([fixSong]);
      });
    });
  }
}
