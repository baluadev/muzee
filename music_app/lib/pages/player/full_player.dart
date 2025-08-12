import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:marquee/marquee.dart';
import 'package:muzee/blocs/player/muzee_player_cubit.dart';
import 'package:muzee/components/image_song_widget.dart';
import 'package:muzee/components/liked_widget.dart';
import 'package:muzee/core/widget_extension.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/admob/native_admanager.dart';
import 'package:muzee/views/dialogs/dialog_helper.dart';
import 'package:muzee/views/profile_view/sleep_time.dart';

import 'now_playing.dart';
import 'play_or_pause.dart';
import 'progress_slider.dart';
import 'repeat_button.dart';
import 'shuffle_button.dart';
import 'video_player_view.dart';

class FullPlayerWidget extends StatelessWidget {
  const FullPlayerWidget({super.key});
  @override
  Widget build(BuildContext context) {
    final playerCubit = context.read<MuzeePlayerCubit>();
    return Scaffold(
      backgroundColor: MyColors.background,
      body: BlocBuilder<MuzeePlayerCubit, MuzeePlayerState>(
        builder: (context, state) {
          if (state.currentSong == null) {
            return Center(
              child: Text(
                "No song is playing",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            );
          }

          return SafeArea(
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            splashRadius: 2,
                            icon: Icon(
                              FlutterRemix.arrow_drop_down_line,
                              color: MyColors.primary,
                              size: 40.w,
                            ),
                            onPressed: () =>
                                playerCubit.hideOrShowFullPlayer(false),
                          ),
                          // IconButton(
                          //   icon: SizedBox(
                          //     width: 40.w,
                          //     height: 40.w,
                          //     child: const Icon(
                          //       FlutterRemix.share_fill,
                          //       color: MyColors.primary,
                          //     ),
                          //   ),
                          //   onPressed: () =>
                          //       playerCubit.hideOrShowFullPlayer(false),
                          // ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const VideoPlayerView(),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 30,
                                      child: Marquee(
                                        text:
                                            state.currentSong?.title ?? "-----",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: Colors.white
                                                  .withOpacity(0.75),
                                            ),
                                        blankSpace: 20.0,
                                        velocity: 40.0,
                                        pauseAfterRound:
                                            const Duration(seconds: 1),
                                        startPadding: 10.0,
                                        accelerationDuration:
                                            const Duration(seconds: 1),
                                        accelerationCurve: Curves.linear,
                                        decelerationDuration:
                                            const Duration(milliseconds: 500),
                                        decelerationCurve: Curves.easeOut,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      state.currentSong?.artist ??
                                          "Unknown Artist",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: Colors.white
                                                  .withOpacity(0.5)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  const LikedWidget(),
                                  GestureDetector(
                                    onTap: () => pushScreenWithNavBar(
                                        context, const SleepTimerView()),
                                    child: const Icon(
                                      FlutterRemix.time_line,
                                      color: MyColors.primary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      DialogHelper.addSongToPlaylists(
                                          state.currentSong!);
                                    },
                                    child: const Icon(
                                      FlutterRemix.play_list_add_line,
                                      color: MyColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 15.h),
                        const ProgressSlider(),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const ShuffleButton().attachGestureDetector(
                              onTap: playerCubit.toogleShuffle,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 28.w, right: 12.w),
                              child: Icon(
                                Icons.skip_previous,
                                size: 24.w,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ).attachGestureDetector(
                              onTap: () => playerCubit.skipToPrevious(),
                            ),
                            PlayOrPause(state: state),
                            Padding(
                              padding: EdgeInsets.only(right: 28.w, left: 12.w),
                              child: Icon(
                                Icons.skip_next,
                                size: 24.w,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ).attachGestureDetector(
                              onTap: () => playerCubit.skipToNext(),
                            ),
                            const RepeatButton().attachGestureDetector(
                                onTap: playerCubit.toogleRepeatMode),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: NativeAdManager(
                        templateType: TemplateType.small,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: MyQueue(
                    state: state,
                    onTap: () => playerCubit.showQueue(),
                  ),
                ),
                AnimatedSlide(
                  offset: state.showQueue
                      ? const Offset(0, 0)
                      : const Offset(0, 1.4),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: NowPlaying(
                    onBack: playerCubit.showQueue,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MyQueue extends StatelessWidget {
  final MuzeePlayerState state;
  final VoidCallback onTap;
  const MyQueue({super.key, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNext = state.currentIndex + 1 < state.queue.length;
    if (state.queue.isEmpty || !isNext) return const SizedBox.shrink();

    final nextSong = state.queue[state.currentIndex + 1];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Up Next',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: MyColors.white.withOpacity(0.25)),
              ),
              TextButton(
                onPressed: onTap,
                child: Text(
                  'Queue >',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: MyColors.white.withOpacity(0.75)),
                ),
              )
            ],
          ),
          Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: MyColors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageSongWidget(
                  id: nextSong.songId,
                  width: 60,
                  height: 60,
                  radius: 8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nextSong.title ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: MyColors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        nextSong.artist ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
