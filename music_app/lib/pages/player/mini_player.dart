import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marquee/marquee.dart';
import 'package:muzee/blocs/player/muzee_player_cubit.dart';
import 'package:muzee/components/image_song_widget.dart';

import 'progress_linear.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final playerCubit = context.read<MuzeePlayerCubit>();
    return BlocBuilder<MuzeePlayerCubit, MuzeePlayerState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
          child: GestureDetector(
            onTap: () {
              context.read<MuzeePlayerCubit>().hideOrShowFullPlayer(true);
            },
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 16,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ImageSongWidget(
                              id: state.currentSong!.songId,
                              width: 48.w,
                              height: 48.h,
                              radius: 8,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    child: Marquee(
                                      text: state.currentSong?.title ?? "-----",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
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
                                  SizedBox(height: 4.h),
                                  Text(
                                    state.currentSong?.artist ??
                                        "Unknown Artist",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                             padding: const EdgeInsets.only(top: 8),
                              child: GestureDetector(
                                onTap: () => state.status == PlayerStatus.playing
                                    ? playerCubit.pause()
                                    : playerCubit.play(),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  transitionBuilder: (child, anim) =>
                                      RotationTransition(
                                    turns: child.key == const Key('icon1')
                                        ? Tween<double>(begin: 0, end: 1)
                                            .animate(anim)
                                        : Tween<double>(begin: 1, end: 0)
                                            .animate(anim),
                                    child: ScaleTransition(
                                        scale: anim, child: child),
                                  ),
                                  child: state.status == PlayerStatus.playing
                                      ? const Icon(
                                          key: Key('icon1'),
                                          Icons.pause,
                                          size: 32,
                                          color: Colors.white,
                                        )
                                      : const Icon(
                                          key: Key('icon2'),
                                          Icons.play_arrow,
                                          size: 32,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const ProgressLinear(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
