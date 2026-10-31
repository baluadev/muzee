import 'package:flutter/material.dart';

class TabletDetailManager {
  TabletDetailManager._privateConstructor();
  static final TabletDetailManager instance =
      TabletDetailManager._privateConstructor();

  final ValueNotifier<Widget?> detailWidget = ValueNotifier<Widget?>(null);

  void show(Widget widget) {
    detailWidget.value = widget;
  }

  void clear() {
    detailWidget.value = null;
  }
}
