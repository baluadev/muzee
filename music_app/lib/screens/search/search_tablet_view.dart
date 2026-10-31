import 'package:flutter/material.dart';
import 'package:muzee/screens/search/search_controller.dart' as search_ctrl;
import 'package:muzee/screens/search/search_mobile_view.dart';

class SearchTabletView extends StatelessWidget {
  const SearchTabletView({super.key, required this.controller});
  final search_ctrl.SearchController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SearchMobileView(controller: controller),
      ),
    );
  }
}
