import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/player/muzee_player_cubit.dart';
import 'package:muzee/core/utils.dart';
import 'package:muzee/services/firebase/remote_service.dart';
import 'package:muzee/views/dialogs/loading.dart';

extension WidgetX on Widget {
  Widget attachHideKeyboard() {
    return GestureDetector(
      onTap: Utils.dismissKeyboard,
      behavior: HitTestBehavior.opaque,
      child: this,
    );
  }

  Widget attachPaddingHorizontal({double? padding}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding ?? 16.w),
      child: this,
    );
  }

  Widget attachPaddingBottom({double? padding}) {
    return Container(
      padding: EdgeInsets.only(bottom: 80.h),
      child: this,
    );
  }

  Widget attachPaddingIfPlaying() {
    return BlocBuilder<MuzeePlayerCubit, MuzeePlayerState>(
        builder: (context, state) {
      double padding = 0.0;
      if (state.status == PlayerStatus.playing) {
        padding = 100.0;
      }
      return Container(
        padding: EdgeInsets.only(bottom: padding),
        child: this,
      );
    });
  }

  Widget attachRMConfigWidget() {
    if (RMConfigService.inst.isSetup) {
      return this;
    }

    return FutureBuilder(
      future: RMConfigService.inst.setup(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Stack(
            alignment: Alignment.center,
            children: [this, const Loading()],
          );
        }
        return this;
      },
    );
  }
}
