import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/gen/colors.gen.dart';

class ItemWidget extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback? onTap;
  const ItemWidget({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88.w,
        height: 70.h,
        decoration: BoxDecoration(
          color: MyColors.background,
          border: Border.all(color: MyColors.primary, width: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  icon,
                  const SizedBox(height: 5),
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
            // Gradient overlay mờ phía trên
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(255, 255, 255, 0.1), // 75%
                      Color.fromRGBO(255, 255, 255, 0.05), // 50%
                      Color.fromRGBO(255, 255, 255, 0.03), // 8%
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.25, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
