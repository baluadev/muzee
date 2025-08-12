import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/components/custom_appbar.dart';
import 'package:muzee/components/option_menu.dart';
import 'package:muzee/components/song_horiz_widget.dart';
import 'package:muzee/components/widget_extension.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/admob/native_admanager.dart';
import 'package:muzee/views/liked_playlist/recently_playlist.dart';
import 'item_artists.dart';
import 'item_liked_playlist.dart';
import 'item_playlists.dart';
import 'item_ytb_playlists.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<LibraryCubit>().getSongsRecently();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: locale.yourLibrary,
        hasBack: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(top: 32.h),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ItemLikedPlaylist(),
                  ItemYtbPlaylist(),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ItemPlaylist(),
                  ItemArtist(),
                ],
              ),
              const NativeAdManager(
                templateType: TemplateType.medium,
              ),
              BlocBuilder<LibraryCubit, LibraryState>(
                buildWhen: (previous, current) =>
                    current is PlaylistRecentlyUpdate,
                builder: (context, state) {
                  final songs = (state is PlaylistRecentlyUpdate)
                      ? state.songs ?? []
                      : [];

                  if (songs.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
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
                        Column(
                          children: List.generate(
                            songs.length > 10 ? 10 : songs.length,
                            (index) => SongHorizWidget(
                              song: songs[index],
                              optionMenu: OptionMenu(
                                song: songs[index],
                              ),
                            ),
                          ),
                        ).attachPaddingIfPlaying(),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
