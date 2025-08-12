import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/auth/auth_cubit.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/components/image_song_widget.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/core/widget_extension.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/views/liked_playlist/recently_playlist.dart';

class RecentlyWidget extends StatefulWidget {
  const RecentlyWidget({super.key});

  @override
  State<RecentlyWidget> createState() => _RecentlyWidgetState();
}

class _RecentlyWidgetState extends State<RecentlyWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryCubit>().getSongsRecently();
    });

    context.read<AuthCubit>().stream.listen((state) {
      context.read<LibraryCubit>().getSongsRecently();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        List<SongModel> songs = [];
        if (state is PlaylistRecentlyUpdate) {
          songs = state.songs ?? [];
        }

        if (songs.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    locale.recentlyPlayed,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  GestureDetector(
                    onTap: () => pushScreenWithNavBar(
                      context,
                      const RecentlyPlaylist(),
                    ),
                    child: Text(
                      locale.seeMore,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: MyColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 110.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: songs.length > 5 ? 5 : songs.length,
                padding: EdgeInsets.only(left: 16.w),
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 80.w,
                          height: 80.w,
                          child: Stack(
                            children: [
                              ImageSongWidget(
                                id: song.songId,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              Positioned(
                                left: 8.w,
                                bottom: 8.w,
                                child: Container(
                                  width: 24.w,
                                  height: 24.w,
                                  decoration: const BoxDecoration(
                                    color: MyColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    FlutterRemix.play_fill,
                                    size: 16.w,
                                    color: MyColors.inputText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        SizedBox(
                          width: 80.w,
                          child: Text(
                            song.title ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ).attachGestureDetector(
                      onTap: () => myPlayerService.setQueue([song]));
                },
              ),
            ),
          ],
        );
      },
      buildWhen: (previous, current) => current is PlaylistRecentlyUpdate,
    );
  }
}
