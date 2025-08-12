import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/core/extensions.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/models/artist_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/database/db_service.dart';
import 'package:muzee/views/artist/artist_list_view.dart';

import 'category_widget.dart';

class ItemArtist extends StatefulWidget {
  const ItemArtist({super.key});

  @override
  State<ItemArtist> createState() => _ItemArtistState();
}

class _ItemArtistState extends State<ItemArtist> {
  List<ArtistModel> artists = [];
  StreamSubscription? _librarySub;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      DBService.inst.getAllArtists().then((values) {
        artists = values;
        reloadView();
      });
      _librarySub = context.read<LibraryCubit>().stream.listen((state) {
        if (!mounted) return;
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
  void dispose() {
    _librarySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) => CategoryWidget(
        icon: Assets.icons.icArtist.image(),
        title: locale.artists.capitalize(),
        subTitle: '${artists.length} ${locale.artists}',
        onTap: () {
          pushScreenWithNavBar(context, const ArtistListView());
        },
      ),
    );
  }
}
