import 'package:flutter/material.dart';
import 'package:muzee/screens/library/library_controller.dart';
import 'package:muzee/screens/library/library_mobile_view.dart';
import 'package:muzee/screens/library/library_tablet_view.dart';
import 'package:muzee/utilities/responsive_layout.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final LibraryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LibraryController();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: LibraryMobileView(controller: _controller),
      tablet: LibraryTabletView(controller: _controller),
    );
  }
}
