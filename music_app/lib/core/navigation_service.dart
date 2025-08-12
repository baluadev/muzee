import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _inst = NavigationService._internal();
  static NavigationService get inst => _inst;
  factory NavigationService() {
    return _inst;
  }
  NavigationService._internal();
  GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  BuildContext get curContext => rootNavigatorKey.currentContext!;
  BuildContext get rootContext => rootNavigatorKey.currentState!.overlay!.context;
}
