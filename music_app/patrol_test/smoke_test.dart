import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/app.dart';

void main() {
  patrolTest('SMOKE-001: app khoi dong va hien thanh dieu huong', ($) async {
    await launchApp($);

    expect($(NavigationBar).exists, isTrue);
    // Home, Search, Library (Settings opens from Home).
    expect($(NavigationDestination).evaluate().length, 3);
  });

  patrolTest('SMOKE-002: chuyen qua lai giua cac tab khong loi', ($) async {
    await launchApp($);

    final tabCount = $(NavigationDestination).evaluate().length;
    for (var i = 0; i < tabCount; i++) {
      await $(NavigationDestination).at(i).tap();
      await $.pump(const Duration(seconds: 1));
      expect($(NavigationBar).exists, isTrue);
    }
  });
}
