import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/gen/colors.gen.dart';

class CategoryWidget extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subTitle;
  final VoidCallback? onTap;
  const CategoryWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148.w,
        height: 110.h,
        decoration: BoxDecoration(
          color: MyColors.background,
          border: Border.all(color: MyColors.primary, width: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.w, 8, 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  icon,
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(subTitle, style: Theme.of(context).textTheme.titleMedium),
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
