import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:muzee/blocs/auth/auth_cubit.dart';
import 'package:muzee/core/navigation_service.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class Utils {
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 18) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  static String k_m_b_generator(String? number) {
    final num = int.parse(number ?? '0');
    if (num > 999 && num < 99999) {
      return "${(num / 1000).toStringAsFixed(1)} K";
    } else if (num > 99999 && num < 999999) {
      return "${(num / 1000).toStringAsFixed(0)} K";
    } else if (num > 999999 && num < 999999999) {
      return "${(num / 1000000).toStringAsFixed(1)} M";
    } else if (num > 999999999) {
      return "${(num / 1000000000).toStringAsFixed(1)} B";
    } else {
      return num.toString();
    }
  }

  static String thumbM(id) =>
      "https://img.youtube.com/vi/$id/maxresdefault.jpg";
  static String thumbD(id) => "https://img.youtube.com/vi/$id/mqdefault.jpg";
  static void showToast(String title) {
    Fluttertoast.showToast(
        msg: title,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: MyColors.background,
        textColor: MyColors.white,
        fontSize: 16);
  }

  static Future showToastWarning(String content) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return showToast(content);
  }

  static Future<void> showSugesstLoginDialog() async {
    await showDialog(
      context: NavigationService.inst.curContext,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu đăng nhập'),
        content:
            const Text('Bạn cần đăng nhập Google để sử dụng chức năng này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Đóng dialog
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog trước
              context.read<AuthCubit>().signInWithGoogle();
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  static String formatDuration(Duration duration) {
    // ignore: unnecessary_null_comparison
    if (duration == null) {
      return '00:00:00';
    }

    String twoDigits(int n) {
      if (n >= 10) {
        return '$n';
      }
      return '0$n';
    }

    final twoDigitHours = twoDigits(duration.inHours);
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).toInt());
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).toInt());

    if (duration.inHours <= 0) {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }

    return '$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds';
  }

  static dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static bool isDevicePhone() {
    final data = MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.single);
    return data.size.shortestSide < 600;
  }

  static Future<bool> openUrl(String url) async {
    return await launchUrl(
      mode: LaunchMode.inAppWebView,
      Uri.parse(url),
    );
  }

  static escape(String? badString) {
    if (badString == null) {
      return null;
    }

    return badString
        .replaceAll('&amp;', '&')
        // .replaceAll('&quot;', '\"')
        .replaceAll('&apos;', "'")
        .replaceAll('&gt;', '>')
        .replaceAll('&lt;', '<')
        .replaceAll('&#39;', "'");
  }

  // Hàm so sánh version kiểu "1.2.3"
  static bool isNewerVersion(String current, String latest) {
    List<int> c = current.split('.').map(int.parse).toList();
    List<int> l = latest.split('.').map(int.parse).toList();
    for (int i = 0; i < l.length; i++) {
      if (i >= c.length || l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  static String formatPrice(double amount, String locale) {
    final format = NumberFormat.simpleCurrency(locale: locale);
    return format.format(amount);
  }
}

class PermissionUtil {
  static List<Permission> androidPermissions = <Permission>[
    Permission.storage,
    Permission.notification,
    Permission.scheduleExactAlarm,
  ];

  static List<Permission> iosPermissions = <Permission>[
    Permission.storage,
    Permission.notification,
    Permission.scheduleExactAlarm,
  ];

  static Future<Map<Permission, PermissionStatus>> requestAll() async {
    if (Platform.isIOS) {
      return await iosPermissions.request();
    }
    return await androidPermissions.request();
  }

  static Future<Map<Permission, PermissionStatus>> request(
      Permission permission) async {
    final List<Permission> permissions = <Permission>[permission];
    return await permissions.request();
  }

  static bool isDenied(Map<Permission, PermissionStatus> result) {
    var isDenied = false;
    result.forEach((key, value) {
      if (value == PermissionStatus.denied) {
        isDenied = true;
        return;
      }
    });
    return isDenied;
  }

  static Future<bool> checkGranted(Permission permission) async {
    PermissionStatus storageStatus = await permission.status;
    if (storageStatus == PermissionStatus.granted) {
      return true;
    } else {
      return false;
    }
  }
}
