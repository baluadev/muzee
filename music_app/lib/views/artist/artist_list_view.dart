import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/components/custom_appbar.dart';
import 'package:muzee/components/widget_extension.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/models/artist_model.dart';
import 'package:muzee/services/database/db_service.dart';

import 'cell.dart';

class SearchArtistModel extends ChangeNotifier {
  bool _isEditing = false;
  bool get isEditing => _isEditing;
  List<ArtistModel> _items = [];
  List<ArtistModel> get items => _items;

  ///
  ///
  ///

  void editing(bool editing) {
    _isEditing = editing;
    notifyListeners();
  }

  void filterItems(List<ArtistModel> items) {
    _items = items;
    notifyListeners();
  }

  void reversedItems() {
    _items = _items.reversed.toList();
    notifyListeners();
  }

  void clearItems() {
    _items.clear();
  }
}

class ArtistListView extends StatefulWidget {
  const ArtistListView({super.key});

  @override
  State<ArtistListView> createState() => _ArtistListViewState();
}

class _ArtistListViewState extends State<ArtistListView> {
  List<ArtistModel> artists = [];
  final searchModel = SearchArtistModel();
  final controller = TextEditingController();
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fetchData();
      controller.addListener(() {
        searchModel.editing(controller.text.isNotEmpty);
      });
      context.read<LibraryCubit>().stream.listen((state) {
        if (state is ArtistFollowState) {
          _fetchData();
        }
      });
    });
  }

  void _fetchData() async {
    artists = await DBService.inst.getAllArtists();
    searchModel.filterItems(artists);
  }

  void _filterData(String word) {
    List<ArtistModel> copyOriginItems = artists.toList();
    if (word.isEmpty) {
      searchModel.filterItems(copyOriginItems);
      return;
    }
    List<ArtistModel> fakeItems = [];

    for (var i = 0; i < copyOriginItems.length; i++) {
      final item = copyOriginItems.elementAt(i);
      final name = item.name ?? '';
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
    return ListenableBuilder(
      listenable: searchModel,
      builder: (context, child) {
        return Scaffold(
          appBar:  CustomAppBar(title: locale.artistsFollowing),
          body: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${artists.length} ${locale.artistsFollowing.toLowerCase()}',
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
                                ?.copyWith(
                                    color: MyColors.black.withOpacity(0.75)),
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
                                          searchModel.filterItems(artists);
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(13.w),
                                          child: SizedBox(
                                            child: Assets.icons.icClose.svg(
                                              colorFilter: ColorFilter.mode(
                                                MyColors.black
                                                    .withOpacity(0.75),
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
                          onTap: () {
                            searchModel.reversedItems();
                          },
                          child: Assets.icons.icSort.image(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: searchModel.items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      return Cell(
                        artist: searchModel.items.elementAt(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ).attachHideKeyboard(),
        );
      },
    );
  }
}
