import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/screens/playlist/playlist_controller.dart';
import 'package:muzee/screens/playlist/playlist_mobile_view.dart';
import 'package:muzee/screens/playlist/playlist_tablet_view.dart';
import 'package:muzee/utilities/responsive_layout.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({
    super.key,
    this.playlistId,
    this.playlistData,
    this.cubeIcon = FluentIcons.text_bullet_list_24_filled,
    this.isArtist = false,
  });

  final String? playlistId;
  final dynamic playlistData;
  final IconData cubeIcon;
  final bool isArtist;

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late final PlaylistController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlaylistController(
      context: context,
      playlistId: widget.playlistId,
      initialPlaylistData: widget.playlistData,
      cubeIcon: widget.cubeIcon,
      isArtist: widget.isArtist,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initializePlaylist();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: PlaylistMobileView(controller: _controller),
      tablet: PlaylistTabletView(controller: _controller),
    );
  }
}
