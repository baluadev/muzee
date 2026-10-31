import 'package:flutter/material.dart';
import 'package:muzee/screens/home/home_controller.dart';
import 'package:muzee/screens/home/home_mobile_view.dart';
import 'package:muzee/screens/home/home_tablet_view.dart';
import 'package:muzee/utilities/adaptive_navigation.dart';
import 'package:muzee/utilities/responsive_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
  }

  void _onPlaylistSelected(String ytid) {
    AdaptiveNavigation.pushPlaylist(context, playlistId: ytid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: ResponsiveLayout(
        mobile: HomeMobileView(
          controller: _controller,
          onPlaylistSelected: _onPlaylistSelected,
        ),
        tablet: HomeTabletView(
          controller: _controller,
          onPlaylistSelected: _onPlaylistSelected,
        ),
      ),
    );
  }
}
