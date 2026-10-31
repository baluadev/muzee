import 'package:flutter/material.dart';
import 'package:muzee/screens/playlist/playlist_controller.dart';
import 'package:muzee/screens/playlist/playlist_mobile_view.dart';

class PlaylistTabletView extends StatelessWidget {
  const PlaylistTabletView({super.key, required this.controller});
  final PlaylistController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: PlaylistMobileView(controller: controller),
      ),
    );
  }
}
