import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/auth/auth_cubit.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/components/option_menu.dart';
import 'package:muzee/components/song_horiz_widget.dart';
import 'package:muzee/core/extensions.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/core/utils.dart';
import 'package:muzee/core/widget_extension.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';
import 'package:muzee/models/artist_model.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/services/ytb/ytb_service.dart';

import 'cell_playlist_artist.dart';

class ArtistView extends StatefulWidget {
  final ArtistModel artistModel;
  const ArtistView({super.key, required this.artistModel});

  @override
  State<ArtistView> createState() => _ArtistViewState();
}

class _ArtistViewState extends State<ArtistView> {
  late ArtistModel _artistModel;
  List<SongModel> lastestSongs = [];
  List<PlaylistModel> playlists = [];

  @override
  void initState() {
    _artistModel = widget.artistModel;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchLatestVideos();
      fetchLatestPlaylists();
      context.read<AuthCubit>().stream.listen((state) {
        if (state.isLoggedIn) {
          fetchLatestVideos();
          fetchLatestPlaylists();
        }
      });
    });
  }

  Future<void> fetchLatestVideos() async {
    try {
      lastestSongs = await YtbService.getLatestVideosFromChannel(
        _artistModel.channelId!,
      );

      reloadView();
    } catch (e) {
      lastestSongs = [];
    }
  }

  Future<void> fetchLatestPlaylists() async {
    final accessToken = await context.read<AuthCubit>().getAccessToken();
    if (accessToken == null) {
      return;
    }
    try {
      playlists = await YtbService.getPlaylistsFromChannel(
        channelId: _artistModel.channelId!,
      );
      reloadView();
    } catch (e) {
      playlists = [];
    }
  }

  reloadView() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: MyColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: 200,
              backgroundColor: MyColors.background,
              leading: IconButton(
                icon: const Icon(FlutterRemix.arrow_left_s_line),
                onPressed: () => Navigator.pop(context),
              ),
              // actions: [
              //   IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
              // ],
              flexibleSpace: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: _artistModel.imgPath ?? '',
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                  ),
                  FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: const EdgeInsets.only(bottom: 16),
                    title: Text(
                      _artistModel.name ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    background: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black87],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ],
              )),

          // Pinned phần Follow, Share, Play
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              child: Container(
                color: MyColors.background,
                height: 60,
                child: Stack(
                  children: [
                    Positioned(
                      left: 16.w,
                      top: 16.h,
                      child: Text(
                        '${Utils.k_m_b_generator(_artistModel.videoCount?.toString() ?? '0')} ${locale.views.toLowerCase()}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Positioned(
                      left: 16.w,
                      top: 40.h,
                      right: 16.w,
                      child: Row(
                        children: [
                          BlocBuilder<LibraryCubit, LibraryState>(
                            buildWhen: (previous, current) =>
                                current is ArtistFollowState,
                            builder: (context, state) {
                              bool followed = false;
                              if (state is ArtistFollowState) {
                                final artists = state.artists ?? [];
                                followed = artists
                                    .where((e) => e.name == _artistModel.name)
                                    .toList()
                                    .isNotEmpty;
                              }
                              return GestureDetector(
                                onTap: () async {
                                  if (followed) {
                                    context
                                        .read<LibraryCubit>()
                                        .followArtist(_artistModel, add: false);
                                  } else {
                                    context
                                        .read<LibraryCubit>()
                                        .followArtist(_artistModel, add: true);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.w,
                                  ),
                                  decoration: BoxDecoration(
                                      color: MyColors.primary,
                                      borderRadius: BorderRadius.circular(99)),
                                  child: Text(
                                    followed
                                        ? locale.followed.capitalize()
                                        : locale.follow.capitalize(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color:
                                              MyColors.black.withOpacity(0.75),
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // const SizedBox(width: 16),
                          // const Icon(FlutterRemix.share_fill,
                          //     color: MyColors.primary),
                          const Spacer(),
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: MyColors.primary,
                            child: Icon(Icons.play_arrow, color: Colors.black),
                          ).attachGestureDetector(onTap: () {
                            if (lastestSongs.isNotEmpty) {
                              myPlayerService.setQueue(lastestSongs);
                            }
                          }),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
           SliverToBoxAdapter(
              child: context.read<AppCubit>().bannerWidget,
            ),
          if (lastestSongs.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                height: 60,
                child: Container(
                  padding: EdgeInsets.only(left: 16.w),
                  color: MyColors.background,
                  child: Text(
                    locale.popularRelease,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: MyColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          if (lastestSongs.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: SongHorizWidget(
                    song: lastestSongs.elementAt(index),
                    optionMenu: OptionMenu(
                      song: lastestSongs.elementAt(index),
                    ),
                  ),
                ),
                childCount: lastestSongs.length, // thêm dòng này
              ),
            ),

          if (playlists.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: Container(
                  padding: EdgeInsets.only(left: 16.w),
                  child: Text(
                    locale.popularPlaylists,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: MyColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          if (playlists.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return CellPlaylistArtist(playlist: playlist);
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                ),
              ),
            ),
          SliverToBoxAdapter(
              child: SizedBox(
            height: 150.h,
          )),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double? height;
  _StickyHeaderDelegate({required this.child, this.height});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: maxExtent,
      child: child,
    );
  }

  @override
  double get maxExtent => height ?? 100;

  @override
  double get minExtent => 40;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) => false;
}
