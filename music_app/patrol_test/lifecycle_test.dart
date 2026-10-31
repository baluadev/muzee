import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/app.dart';

// Ten ham trong $.platform.mobile can doi chieu voi phien ban Patrol dang cai
// (chay `dart analyze patrol_test` sau khi `pub get`).
void main() {
  patrolTest('INT-004: ve man hinh chinh roi mo lai app van hoat dong', (
    $,
  ) async {
    await launchApp($);

    await $.platform.mobile.pressHome();
    await $.platform.mobile.openApp();

    await $(
      NavigationBar,
    ).waitUntilVisible(timeout: const Duration(seconds: 30));
    expect($(NavigationBar).exists, isTrue);
  });

  patrolTest('NET-002: bat roi tat airplane mode app khong crash', ($) async {
    await launchApp($);

    await $.platform.mobile.enableAirplaneMode();
    await $.pump(const Duration(seconds: 3));
    expect($(NavigationBar).exists, isTrue);

    await $.platform.mobile.disableAirplaneMode();
    await $.pump(const Duration(seconds: 3));
    expect($(NavigationBar).exists, isTrue);
  });
}
