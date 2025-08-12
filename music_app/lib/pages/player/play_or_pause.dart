import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/player/muzee_player_cubit.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';

class PlayOrPause extends StatelessWidget {
  final MuzeePlayerState state;
  const PlayOrPause({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (!myPlayerService.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          color: MyColors.white.withOpacity(0.75),
          shape: BoxShape.circle,
        ),
        height: 48.w,
        width: 48.w,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        ),
      );
    }

    final playerCubit = context.read<MuzeePlayerCubit>();

    return GestureDetector(
      onTap: () => state.status == PlayerStatus.playing
          ? playerCubit.pause()
          : playerCubit.play(),
      child: Container(
        decoration: BoxDecoration(
          color: MyColors.white.withOpacity(0.75),
          shape: BoxShape.circle,
        ),
        height: 48.w,
        width: 48.w,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: child.key == const Key('icon1')
                ? Tween<double>(begin: 0, end: 1).animate(anim)
                : Tween<double>(begin: 1, end: 0).animate(anim),
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: Icon(
            state.status == PlayerStatus.playing
                ? Icons.pause
                : Icons.play_arrow,
            size: 32,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
