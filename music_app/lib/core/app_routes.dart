import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:muzee/pages/main_view.dart';

class AppRoutes {
  static const String root = '/';
  Route onGenerateRoute(RouteSettings settings) {
    final String name = settings.name!;

    switch (name) {
      case root:
        return _build(_getHome(), settings);
      default:
        return _build(_getHome(), settings);
    }
  }

  CupertinoPageRoute _build(Widget child, RouteSettings settings) {
    return CupertinoPageRoute(builder: (_) => child, settings: settings);
  }

  Widget _getHome() {
    // return const OnBoardView();
    return const MainView();
  }
}

// Hiệu ứng chuyển màn Hero
class CustomPageRoute extends PageRouteBuilder {
  final Widget? page;
  final RouteSettings? settings1;
  CustomPageRoute({this.page, this.settings1})
      : super(
          settings: settings1,
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page!,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              Align(
            child: SizeTransition(
              sizeFactor: animation,
              child: child,
            ),
          ),
        );
}
