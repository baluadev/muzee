import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/player/muzee_player_cubit.dart';
import 'package:muzee/components/image_song_widget.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({
    super.key,
  });

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  bool _showVideo = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuzeePlayerCubit, MuzeePlayerState>(
      builder: (context, state) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 205.h,
          child: Stack(
            children: [
              if (!_showVideo)
                Positioned.fill(
                  child: ImageSongWidget(
                    id: state.currentSong!.songId,
                    width: 312.w,
                    height: 312.w,
                  ),
                )
              else
                ValueListenableBuilder(
                  valueListenable: myPlayerService.videoControllerStream,
                  builder: (context, player, child) {
                    if (player == null) {
                      return Positioned.fill(
                        child: ImageSongWidget(
                          id: state.currentSong!.songId,
                          width: 312.w,
                          height: 312.w,
                        ),
                      );
                    }

                    var ratio = player.value.aspectRatio;
                    return Center(
                      child: AspectRatio(
                        aspectRatio: ratio,
                        child: VideoPlayer(
                          player,
                        ),
                      ),
                    );
                  },
                ),
              Align(
                alignment: Alignment.bottomLeft,
                child: GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        _showVideo = !_showVideo;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(left: 8, bottom: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MyColors.white.withOpacity(0.2),
                    ),
                    child: Icon(
                      _showVideo
                          ? FlutterRemix.movie_line
                          : FlutterRemix.music_line,
                      color: MyColors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
