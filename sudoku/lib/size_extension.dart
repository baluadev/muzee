import 'dart:math';

import 'package:flutter/material.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;

  /// 设备宽度
  static double screenWidth = 0;

  /// 设备高度
  static double screenHeight = 0;

  /// 方向
  static late Orientation orientation;

  /// 设计图宽度
  static double inputHeight = 390;

  /// 设计图宽度
  static double inputWidth = 844;
  static late EdgeInsets padding;

  /// The ratio of actual height to UI design
  static double get scaleWidth => screenWidth / inputWidth;

  static double get scaleHeight => screenHeight / inputHeight;

  static double get scaleText => min(scaleWidth, scaleHeight);

  /// 在使用前应当初始化他，
  static void init(BuildContext context, double w, double h) {
    inputWidth = w;
    inputHeight = h;
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;
    padding = _mediaQueryData.padding;
  }
}

// Get the proportionate height as per screen size
double getProportionateScreenWidth(num inputWidth) {
  return inputWidth * SizeConfig.scaleWidth;
}

// Get the proportionate height as per screen size
double getProportionateScreenHeight(num inputHeight) {
  return inputHeight * SizeConfig.scaleHeight;
}

/// 对num进行扩展，可直接使用1.2.w的形式代替getProportionateScreenWidth(1.2)
extension SizeExtension on num {
  ///[ScreenUtil.setWidth]
  double get w => getProportionateScreenWidth(this);

  ///[ScreenUtil.setHeight]
  double get h => getProportionateScreenHeight(this);

  ///[ScreenUtil.radius]
  double get r => this * SizeConfig.scaleText;

  ///屏幕宽度的倍数
  ///Multiple of screen width
  double get sw => SizeConfig.screenWidth * this;

  ///屏幕高度的倍数
  ///Multiple of screen height
  double get sh => SizeConfig.screenHeight * this;
}
