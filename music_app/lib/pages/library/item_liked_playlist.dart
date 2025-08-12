import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/views/liked_playlist/liked_playlist.dart';

import 'category_widget.dart';

class ItemLikedPlaylist extends StatefulWidget {
  const ItemLikedPlaylist({super.key});

  @override
  State<ItemLikedPlaylist> createState() => _ItemLikedPlaylistState();
}

class _ItemLikedPlaylistState extends State<ItemLikedPlaylist> {
  List<SongModel> songs = [];
  StreamSubscription? _librarySub;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<LibraryCubit>().getLikedSongs();
      _librarySub = context.read<LibraryCubit>().stream.listen((state) {
        if (!mounted) return;
        if (state is PlaylistLikedUpdate) {
          songs = state.songs ?? [];
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
          FlutterRemix.heart_line,
          color: MyColors.primary,
        ),
        title: locale.likedSongs,
        subTitle: '${songs.length} ${locale.songs}',
        onTap: () => pushScreenWithNavBar(
          context,
          const LikedPlaylist(),
        ),
      ),
    );
  }
}
