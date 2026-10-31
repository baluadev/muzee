import 'package:flutter/material.dart';
import 'package:muzee/screens/search/search_controller.dart' as search_ctrl;
import 'package:muzee/screens/search/search_mobile_view.dart';
import 'package:muzee/screens/search/search_tablet_view.dart';
import 'package:muzee/utilities/responsive_layout.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final search_ctrl.SearchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = search_ctrl.SearchController();
    // Opened from a search bar, so the user is about to type. Focus once the
    // page transition has finished: Android ignores the request to show the
    // keyboard while the route is still animating in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animation = ModalRoute.of(context)?.animation;
      if (animation == null || animation.isCompleted) {
        _focusField();
        return;
      }
      void onStatus(AnimationStatus status) {
        if (status != AnimationStatus.completed) return;
        animation.removeStatusListener(onStatus);
        _focusField();
      }

      animation.addStatusListener(onStatus);
    });
  }

  void _focusField() {
    if (mounted) _controller.inputNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: SearchMobileView(controller: _controller),
      tablet: SearchTabletView(controller: _controller),
    );
  }
}
