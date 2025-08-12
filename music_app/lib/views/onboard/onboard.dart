import 'package:flutter/material.dart';

import 'muzee_painter.dart';

class OnBoardView extends StatefulWidget {
  const OnBoardView({super.key});

  @override
  State<OnBoardView> createState() => _OnBoardViewState();
}

class _OnBoardViewState extends State<OnBoardView> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: MuzeeAnimation(),
      ),
    );
  }
}
