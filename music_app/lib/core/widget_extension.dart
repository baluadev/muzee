import 'package:muzee/core/utils.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/services/admob/interstitial_admanager.dart';
import 'package:muzee/views/dialogs/loading.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension WidgetX on Widget {
  Widget attachOverlayLoading({bool isLoading = true}) {
    return Stack(
      children: [
        this,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: MyColors.black.withOpacity(0.6),
              child: const Loading(),
            ),
          )
      ],
    );
  }

  Widget attachPageLoading({bool isLoading = true}) {
    if (isLoading) return const Loading();
    return this;
  }

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

  Widget attachPaddingVertical({double? padding}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: padding ?? 8.h),
      child: this,
    );
  }

  Widget attachGestureDetector({VoidCallback? onTap}) {
    return GestureDetector(
      onTap: () {
        InterstitialAdManager.inst.registerAction();
        if (onTap != null) {
          onTap();
        }
      },
      child: this,
    );
  }
}
