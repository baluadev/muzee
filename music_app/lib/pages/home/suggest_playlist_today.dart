import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/auth/auth_cubit.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/components/image_song_widget.dart';
import 'package:muzee/components/song_horiz_widget.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/core/widget_extension.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/database/local_store.dart';
import 'package:muzee/services/notification/notification_service.dart';
import 'package:muzee/views/playlist/detail_playlist_view.dart';

class SuggestPlaylistToday extends StatefulWidget {
  const SuggestPlaylistToday({super.key});

  @override
  State<SuggestPlaylistToday> createState() => _SuggestPlaylistTodayState();
}

class _SuggestPlaylistTodayState extends State<SuggestPlaylistToday>
    with AutomaticKeepAliveClientMixin {
  List<PlaylistModel> list = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSuggestPlaylist();
      context.read<AppCubit>().stream.listen((state) {
        fetchSuggestPlaylist();
      });
    });

    context.read<AuthCubit>().stream.listen((state) {
      if (state.isLoggedIn) fetchSuggestPlaylist();
    });
  }

  Future<void> fetchSuggestPlaylist() async {
    try {
      list = await context
          .read<LibraryCubit>()
          .generateMultipleSuggestedPlaylists();
      reloadView();

      //schedule
      List<SongModel> songs = [];
      for (var plist in list) {
        songs.addAll(plist.tempSongs);
      }
      songs.shuffle();
      _setScheduleSongDaily(songs.take(3).toList());
    } catch (e) {
      list = [];
    }
  }

  void _setScheduleSongDaily(List<SongModel> songs) {
    NotificationService.scheduleDailyNotifications(
        songs, LocalStore.inst.getLanguageCode);
  }

  reloadView() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Text(
          locale.todaySongsSuggest,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 380.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final playlist = list[index];
              final songs = playlist.tempSongs.toList();
              return Container(
                width: 288.w,
                height: double.infinity,
                margin: const EdgeInsets.only(right: 16),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.black.withOpacity(0.12)
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ImageSongWidget(
                          url: playlist.thumbnailUrl,
                          width: 100,
                          height: 100,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mix ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6.w),
                              Text(
                                '${songs.length} ${locale.songs}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 16.w),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.w,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: MyColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(FlutterRemix.play_fill),
                                ).attachGestureDetector(
                                    onTap: () =>
                                        myPlayerService.setQueue(songs)),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 16.w),
                    ...songs.map((e) => SongHorizWidget(song: e)).take(4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () => pushScreenWithNavBar(
                            context, DetailPlaylistView(playlist: playlist)),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.w,
                          ),
                          decoration: BoxDecoration(
                            color: MyColors.primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            locale.seeAll,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: MyColors.black.withOpacity(0.75),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
