import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/components/custom_appbar.dart';
import 'package:muzee/components/option_menu.dart';
import 'package:muzee/components/round_play_button.dart';
import 'package:muzee/components/song_horiz_widget.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/services/firebase/remote_service.dart';
import 'package:muzee/services/ytb/ytb_service.dart';
import 'package:muzee/views/dialogs/loading.dart';

import 'search_song_model.dart';

class DetailBrowse extends StatefulWidget {
  final String title;
  final String genreCode;
  const DetailBrowse({super.key, required this.genreCode, required this.title});

  @override
  State<DetailBrowse> createState() => _DetailBrowseState();
}

class _DetailBrowseState extends State<DetailBrowse> {
  List<SongModel> songs = [];
  final searchModel = SearchSongModel();
  final controller = TextEditingController();
  final focusNode = FocusNode();
  bool loading = true;
  int adFrequency = RMConfigService.inst.adFrequency;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      songs = await YtbService.getMusicsFromCategory(widget.genreCode);
      loading = false;
      searchModel.filterItems(songs);
      reloadView();
      controller.addListener(() {
        searchModel.editing(controller.text.isNotEmpty);
      });
    });
  }

  void _filterData(String word) {
    List<SongModel> copyOriginItems = songs.toList();
    if (word.isEmpty) {
      searchModel.filterItems(copyOriginItems);
      return;
    }
    List<SongModel> fakeItems = [];

    for (var i = 0; i < copyOriginItems.length; i++) {
      final item = copyOriginItems.elementAt(i);
      final name = item.title ?? '';
      if (name.toLowerCase().contains(word.toLowerCase())) {
        fakeItems.add(item);
      }
    }
    searchModel.filterItems(fakeItems);
  }

  void reloadView() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.title),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${songs.length} ${locale.songs}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: MyColors.primary),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40.h,
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autocorrect: false,
                        enableSuggestions: false,
                        onChanged: _filterData,
                        onSubmitted: _filterData,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: MyColors.black.withOpacity(0.75)),
                        cursorColor: MyColors.black.withOpacity(0.75),
                        decoration: InputDecoration(
                          fillColor: MyColors.primary,
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(
                            FlutterRemix.search_line,
                            color: MyColors.black.withOpacity(0.5),
                          ),
                          hintText: locale.search,
                          hintStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: MyColors.black.withOpacity(0.5),
                                  fontWeight: FontWeight.w400),
                          contentPadding: const EdgeInsets.all(12),
                          suffixIcon: ListenableBuilder(
                              listenable: searchModel,
                              builder: (context, child) {
                                return Visibility(
                                  visible: searchModel.isEditing,
                                  child: GestureDetector(
                                    onTap: () {
                                      focusNode.unfocus();
                                      controller.clear();
                                      searchModel.editing(false);
                                      searchModel.filterItems(songs);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(13.w),
                                      child: SizedBox(
                                        child: Assets.icons.icClose.svg(
                                          colorFilter: ColorFilter.mode(
                                            MyColors.black.withOpacity(0.75),
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: RoundPlayButton(songs: songs),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => searchModel.reversedItems(),
              child: Row(
                children: [
                  Assets.icons.icSort.image(width: 20.w, height: 20.w),
                  Text(
                    locale.recents,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            loading
                ? const Center(
                    child: Loading(),
                  )
                : Expanded(
                    child: ListenableBuilder(
                      listenable: searchModel,
                      builder: (context, child) {
                        final songsR = searchModel.items;
                        final int totalItems =
                            songsR.length + (songsR.length ~/ adFrequency);
                        return ListView.builder(
                          itemCount: totalItems,
                          itemBuilder: (context, index) {
                            final int numAdsShown = index ~/ (adFrequency + 1);
                            if ((index + 1) % (adFrequency + 1) == 0) {
                              return context.read<AppCubit>().songNativeAdManager;
                            }
                            final int songIndex = index - numAdsShown;
                            final song = songsR[songIndex];
                            return SongHorizWidget(
                              song: song,
                              optionMenu: OptionMenu(song: song),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
