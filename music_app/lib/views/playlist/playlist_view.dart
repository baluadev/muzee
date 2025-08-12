import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/components/custom_appbar.dart';
import 'package:muzee/components/widget_extension.dart';
import 'package:muzee/core/extensions.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/views/dialogs/dialog_helper.dart';
import 'package:muzee/views/playlist/cell.dart';
import 'package:muzee/views/search_playlist_controller.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  List<PlaylistModel> playlists = [];
  late final StreamSubscription _librarySub;
  final searchModel = SearchPlaylistController();
  final controller = TextEditingController();
  final focusNode = FocusNode();
  int adFrequency = 4;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryCubit>().getAllPlaylist();
      _librarySub = context.read<LibraryCubit>().stream.listen((state) {
        if (state is PlaylistListUpdate) {
          playlists = state.playlists ?? [];
          reloadView();
          searchModel.filterItems(playlists);
        }
      });
    });
  }

  void _filterData(String word) {
    List<PlaylistModel> copyOriginItems = playlists.toList();
    if (word.isEmpty) {
      searchModel.filterItems(copyOriginItems);
      return;
    }
    List<PlaylistModel> fakeItems = [];
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
    _librarySub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: locale.playlists.capitalize(),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${playlists.length} ${locale.playlists}',
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
                    child: InkWell(
                      radius: 15,
                      highlightColor: Colors.transparent,
                      onTap: _addPlaylist,
                      child: const Icon(
                        FlutterRemix.add_line,
                        color: MyColors.primary,
                        size: 38,
                      ),
                    ),
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
            // context.read<AppCubit>().bannerWidget,
            Expanded(
              child: ListenableBuilder(
                listenable: searchModel,
                builder: (context, child) {
                  final playlistR = searchModel.items;
                  // Tổng số ad cần chèn: (playlistR.length / adFrequency).ceil()
                  final int totalAds = (playlistR.length / adFrequency).ceil();

// Tổng item là dữ liệu gốc + tổng số ad + 1 ad đầu tiên
                  final int totalItems = playlistR.length + totalAds + 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    itemCount: totalItems,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.79,
                    ),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return context.read<AppCubit>().playlistNativeAdManager;
                      }

                      // Trừ đi ad đầu tiên để tính lại index dữ liệu gốc
                      final int adjustedIndex = index - 1;

                      // Mỗi (adFrequency + 1) sẽ có 1 ad => sau mỗi 5 mục dữ liệu, thêm 1 ad
                      if ((adjustedIndex + 1) % (adFrequency + 1) == 0) {
                        return context.read<AppCubit>().playlistNativeAdManager;
                      }

                      // Số ad đã chèn trước vị trí này (sau ad đầu tiên)
                      final int numAdsBefore =
                          (adjustedIndex ~/ (adFrequency + 1)) + 1;
                      final int songIndex = adjustedIndex - numAdsBefore + 1;

                      // Nếu vượt quá danh sách thì trả Container rỗng (an toàn)
                      if (songIndex >= playlistR.length) {
                        return const SizedBox.shrink();
                      }
                      final playlist = playlistR[songIndex];
                      return Cell(
                        playlist: playlist,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ).attachHideKeyboard(),
    );
  }

  Future<void> _addPlaylist() async {
    await DialogHelper.showCreateOrEditPlaylistDialog();
  }
}
