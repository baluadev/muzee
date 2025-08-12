import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/player/muzee_player_cubit.dart';
import 'package:muzee/gen/colors.gen.dart';

class RepeatButton extends StatelessWidget {
  const RepeatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuzeePlayerCubit, MuzeePlayerState>(
      builder: (context, state) {
        final enable = state.repeatMode == AudioServiceRepeatMode.one;
        return Icon(
          FlutterRemix.repeat_one_line,
          size: 24.w,
          color: enable ? MyColors.white : MyColors.secondary,
        );
      },
    );
  }
}
