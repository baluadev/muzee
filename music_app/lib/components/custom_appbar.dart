import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/views/premium/premium_view.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic title;
  final bool? hasBack;
  final double height;
  final Widget? trailing;
  final bool showCrown;

  const CustomAppBar({
    super.key,
    required this.title,
    this.hasBack = true,
    this.height = kToolbarHeight,
    this.trailing,
    this.showCrown = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasBack!)
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Assets.icons.icBack.image(width: 40, height: 40),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 5),
              child: title is String
                  ? Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    )
                  : title,
            ),
            const Spacer(),
            if (showCrown)
              GestureDetector(
                onTap: () => pushScreenWithoutNavBar(
                  context,
                  const PremiumScreen(),
                ),
                child: Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: Assets.images.crown.image(
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            if (trailing != null)
              Padding(
                padding: EdgeInsets.only(right: 16.w, top: 6.h),
                child: trailing,
              ),
          ],
        ),
      ),
    );
  }
}
