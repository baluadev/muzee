import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/components/image_song_widget.dart';
import 'package:muzee/components/option_menu.dart';
import 'package:muzee/components/song_horiz_widget.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/core/widget_extension.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';
import 'package:muzee/models/custom_popup_model.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/services/firebase/remote_service.dart';
import 'package:muzee/views/dialogs/dialog_helper.dart';

class DetailPlaylistView extends StatefulWidget {
  final PlaylistModel playlist;
  final bool isLocal;
  const DetailPlaylistView({
    super.key,
    required this.playlist,
    this.isLocal = false,
  });

  @override
  State<DetailPlaylistView> createState() => _DetailPlaylistViewState();
}

class _DetailPlaylistViewState extends State<DetailPlaylistView> {
  late PlaylistModel playlist;
  late List<SongModel> songs;
  late LibraryCubit cubit;
  int adFrequency = RMConfigService.inst.adFrequency;

  List<CustomPopupModel> choices = [
    CustomPopupModel(
      id: 0,
      title: locale.remove,
      icon: FlutterRemix.delete_bin_line,
    ),
    CustomPopupModel(
      id: 1,
      title: locale.edit,
      icon: FlutterRemix.edit_line,
    ),
  ];

  @override
  void initState() {
    playlist = widget.playlist;
    songs = widget.isLocal ? playlist.songs.toList() : playlist.tempSongs;

    super.initState();
    cubit = context.read<LibraryCubit>();
  }

  void _onSelected(value) async {
    final id = value.id as int;
    if (id == 0) {
      await cubit.removePlaylist(playlist.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else if (id == 1) {
      DialogHelper.showCreateOrEditPlaylistDialog(playlist: playlist);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        if (state is PlaylistUpdate) {
          playlist = state.playlist!;
          songs = playlist.songs.toList();
        }
        final int totalItems = songs.length + (songs.length ~/ adFrequency);
        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
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
                  actions: [
                    PopupMenuButton(
                      color: MyColors.background,
                      padding: EdgeInsets.zero,
                      surfaceTintColor: Colors.white,
                      onSelected: (value) {
                        _onSelected(value);
                      },
                      itemBuilder: (BuildContext context) {
                        return choices.map(
                          (choice) {
                            return PopupMenuItem(
                              height: ScreenUtil().setHeight(50),
                              value: choice,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Icon(
                                      choice.icon,
                                      size: 24,
                                      color: MyColors.primary,
                                    ),
                                  ),
                                  SizedBox(
                                    width: ScreenUtil().setWidth(5),
                                  ),
                                  Text(choice.title?.toString() ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                ],
                              ),
                            );
                          },
                        ).toList();
                      },
                      child: const Icon(
                        FlutterRemix.more_2_line,
                        size: 24,
                        color: MyColors.primary,
                      ),
                    ),
                  ],
                  flexibleSpace: Stack(
                    children: [
                      ImageSongWidget(
                        id: songs.isNotEmpty ? songs.first.songId : '',
                        url: playlist.thumbnailUrl,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      FlexibleSpaceBar(
                        centerTitle: true,
                        titlePadding: const EdgeInsets.only(bottom: 16),
                        title: Text(
                          playlist.title ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.75),
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

              // VÙNG Pinned Thông tin dưới ảnh
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeader(
                  height: 80.h,
                  child: Container(
                    color: MyColors.background,
                    height: 60,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 16.w,
                          top: 16.h,
                          child: Text(
                            '${locale.playlist} - ${songs.length} ${locale.songs}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Positioned(
                          left: 16.w,
                          top: 40.h,
                          right: 16.w,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                child: const Icon(FlutterRemix.heart_line,
                                    color: MyColors.primary),
                                onTap: () {},
                              ),
                              // const SizedBox(width: 16),
                              // const Icon(FlutterRemix.share_fill,
                              //     color: MyColors.primary),
                              const Spacer(),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: MyColors.primary,
                                child: Icon(
                                  FlutterRemix.play_fill,
                                  color: MyColors.black.withOpacity(0.75),
                                ),
                              ).attachGestureDetector(onTap: () {
                                if (songs.isNotEmpty) {
                                  myPlayerService.setQueue(songs.toList());
                                }
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // SliverToBoxAdapter(
              //   child: context.read<AppCubit>().bannerWidget,
              // ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: totalItems,
                  (context, index) {
                    final int numAdsShown = index ~/ (adFrequency + 1);
                    if ((index + 1) % (adFrequency + 1) == 0) {
                      return context.read<AppCubit>().songNativeAdManager.attachPaddingHorizontal();
                    }
                    final int songIndex = index - numAdsShown;
                    final song = songs[songIndex];
                    return SongHorizWidget(
                      song: song,
                      optionMenu: widget.isLocal
                          ? OptionMenu(
                              song: song,
                              playlist: playlist,
                            )
                          : null,
                    ).attachPaddingHorizontal();
                  },
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 150),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==== DELEGATE CHUNG ====
class _PinnedHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double? height;
  _PinnedHeader({required this.child, this.height});

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
  bool shouldRebuild(_PinnedHeader oldDelegate) => false;
}
