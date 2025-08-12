import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/views/playlist/ytb_playlist_view.dart';

import 'category_widget.dart';

class ItemYtbPlaylist extends StatefulWidget {
  const ItemYtbPlaylist({super.key});

  @override
  State<ItemYtbPlaylist> createState() => _ItemYtbPlaylistState();
}

class _ItemYtbPlaylistState extends State<ItemYtbPlaylist> {
  List<PlaylistModel> playlists = [];
  StreamSubscription? _librarySub;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<LibraryCubit>().getYtbPlaylists();
      _librarySub = context.read<LibraryCubit>().stream.listen((state) {
        if (!mounted) return;
        if (state is YtbPlaylistListUpdate) {
          playlists = state.playlists ?? [];
          reloadView();
        }
      });
    });
  }

  void reloadView() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _librarySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) => CategoryWidget(
        icon: const Icon(
          FlutterRemix.youtube_line,
          color: MyColors.primary,
        ),
        title: 'Youtube',
        subTitle: '${playlists.length} ${locale.playlists}',
        onTap: () => pushScreenWithNavBar(
          context,
          const YtbPlaylistView(),
        ),
      ),
    );
  }
}
