import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/app.dart';

void main() {
  // AndroidManifest.xml hien khong khai bao POST_NOTIFICATIONS, nen tren
  // Android 13+ app khong the xin quyen thong bao. Test nay ghi lai hanh vi:
  // neu mot hop thoai quyen xuat hien thi tu choi va app van phai dung duoc.
  patrolTest('PERM-001: tu choi quyen (neu co) app van dung duoc', ($) async {
    await launchApp($);

    if (await $.platform.mobile.isPermissionDialogVisible(
      timeout: const Duration(seconds: 5),
    )) {
      await $.platform.mobile.denyPermission();
    }

    expect($(NavigationBar).exists, isTrue);
  });
}
