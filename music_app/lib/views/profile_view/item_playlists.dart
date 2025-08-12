import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/views/playlist/playlist_view.dart';

import 'item_widget.dart';

class ItemPlaylist extends StatefulWidget {
  const ItemPlaylist({super.key});

  @override
  State<ItemPlaylist> createState() => _ItemPlaylistState();
}

class _ItemPlaylistState extends State<ItemPlaylist> {
  List<PlaylistModel> playlists = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<LibraryCubit>().getAllPlaylist();
      context.read<LibraryCubit>().stream.listen((state) {
        if (state is PlaylistListUpdate) {
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
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) => ItemWidget(
        icon: const Icon(
          FlutterRemix.play_list_line,
          size: 24,
          color: MyColors.primary,
        ),
        title: '${playlists.length} ${locale.playlists}',
        onTap: () => pushScreenWithNavBar(
          context,
          const PlaylistView(),
        ),
      ),
    );
  }
}
