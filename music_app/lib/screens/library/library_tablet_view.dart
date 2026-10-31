import 'package:flutter/material.dart';
import 'package:muzee/screens/library/library_controller.dart';
import 'package:muzee/screens/library/library_mobile_view.dart';

class LibraryTabletView extends StatelessWidget {
  const LibraryTabletView({super.key, required this.controller});
  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: LibraryMobileView(controller: controller),
      ),
    );
  }
}
