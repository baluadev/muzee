import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/components/custom_appbar.dart';
import 'package:muzee/core/widget_extension.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/models/category_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/ytb/ytb_service.dart';
import 'package:muzee/views/dialogs/loading.dart';
import 'package:muzee/views/playlist/detail_playlist_view.dart';

class DetailMood extends StatelessWidget {
  final CategoryModel categoryModel;
  const DetailMood({super.key, required this.categoryModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: categoryModel.title),
      body: FutureBuilder(
        future: YtbService.getMoodDetail(categoryModel.params ?? ""),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Loading(),
            );
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const SizedBox();
          }
          final list = snapshot.data!;
          return Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: GridView.builder(
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemBuilder: (context, index) {
                final item = list.elementAt(index);
                return Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        item.thumbnailUrl ?? '',
                      ),
                    ),
                  ),
                ).attachGestureDetector(
                  onTap: () => pushScreenWithNavBar(
                    context,
                    FutureBuilder<List<SongModel>>(
                      future: YtbService.getMoodPlayList(item.playlistId),
                      builder: (context, snapshot) {
                        List<SongModel> songs = [];
                        if (snapshot.connectionState != ConnectionState.done) {
                          return Center(
                            child: Container(
                              color: MyColors.background,
                              child: const Loading(),
                            ),
                          );
                        }

                        if (snapshot.hasData) {
                          songs = snapshot.data!;
                        }
                        item.tempSongs = songs;

                        return DetailPlaylistView(
                          playlist: item,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
