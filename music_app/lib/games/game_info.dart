import 'package:flutter/material.dart';

class GameInfo {
  final String title;
  final String subtitle;
  final Color color;
  final String logo;
  final Widget screen;

  GameInfo({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.logo,
    required this.screen,
  });
}
