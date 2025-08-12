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
import 'item_widget.dart';

class ItemLikedPlaylist extends StatefulWidget {
  const ItemLikedPlaylist({super.key});

  @override
  State<ItemLikedPlaylist> createState() => _ItemLikedPlaylistState();
}

class _ItemLikedPlaylistState extends State<ItemLikedPlaylist> {
  List<SongModel> songs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<LibraryCubit>().getLikedSongs();
      context.read<LibraryCubit>().stream.listen((state) {
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
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) => ItemWidget(
        icon: const Icon(
          FlutterRemix.heart_line,
          size: 24,
          color: MyColors.primary,
        ),
        title: '${songs.length} ${locale.songs}',
        onTap: () => pushScreenWithNavBar(
          context,
          const LikedPlaylist(),
        ),
      ),
    );
  }
}
