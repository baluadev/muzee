import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/models/artist_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/database/db_service.dart';
import 'package:muzee/views/artist/artist_list_view.dart';

import 'item_widget.dart';

class ItemArtist extends StatefulWidget {
  const ItemArtist({super.key});

  @override
  State<ItemArtist> createState() => _ItemArtistState();
}

class _ItemArtistState extends State<ItemArtist> {
  List<ArtistModel> artists = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      artists = await DBService.inst.getAllArtists();
      reloadView();
      // ignore: use_build_context_synchronously
      context.read<LibraryCubit>().stream.listen((state) {
        if (state is ArtistFollowState) {
          artists = state.artists ?? [];
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
        icon: Assets.icons.icArtist.image(),
        title: '${artists.length} ${locale.artists}',
        onTap: () => pushScreenWithNavBar(
          context,
          const ArtistListView(),
        ),
      ),
    );
  }
}
