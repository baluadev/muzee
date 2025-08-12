import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../gen/colors.gen.dart';


class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: MyColors.background,
    primaryColor: MyColors.primary,
    secondaryHeaderColor: MyColors.secondary,
    fontFamily: 'Inter',
    indicatorColor: MyColors.primary,
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: MaterialStateProperty.all(MyColors.primary),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      // color: MyColors.white,
      iconTheme: IconThemeData(
        color: Colors.white,
        size: 16.sp,
      ),
      titleTextStyle: TextStyle(
        color: MyColors.primary,
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        height: 1.5,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 44.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: MyColors.primary,
      ),
      displayMedium: TextStyle(
        fontSize: 40.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: MyColors.primary,
      ),
      displaySmall: TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: MyColors.primary,
      ),

      // Headings (Title)
      headlineLarge: TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: MyColors.primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: MyColors.primary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: MyColors.primary,
      ),

      // Body Text
      bodyLarge: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: MyColors.primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: MyColors.primary,
      ),
      bodySmall: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: MyColors.primary,
      ),

      // Body 2
      labelLarge: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: MyColors.primary,
      ),
      labelMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: MyColors.primary,
      ),
      labelSmall: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: MyColors.primary,
      ),

      // Tiny Text
      titleLarge: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: MyColors.primary,
      ),
      titleMedium: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: MyColors.primary,
      ),
      titleSmall: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: MyColors.primary,
      ),
    ).apply(
      fontFamily: 'Inter',
    ),
  );
}
