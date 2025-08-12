import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/components/custom_appbar.dart';
import 'package:muzee/configs/const.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/services/database/local_store.dart';

class SearchCountryModel extends ChangeNotifier {
  bool _isEditing = false;
  bool get isEditing => _isEditing;
  List<Map<String, String>> _items = [];
  List<Map<String, String>> get items => _items;

  ///
  ///
  ///

  void editing(bool editing) {
    _isEditing = editing;
    notifyListeners();
  }

  void filterItems(List<Map<String, String>> items) {
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

class ChooseCountry extends StatefulWidget {
  const ChooseCountry({super.key});

  @override
  State<ChooseCountry> createState() => _ChooseCountryState();
}

class _ChooseCountryState extends State<ChooseCountry> {
  List<Map<String, String>> region = [];
  late String selectedItem;
  final searchModel = SearchCountryModel();
  final controller = TextEditingController();
  final focusNode = FocusNode();

  @override
  void initState() {
    region = Const.supportRegions.map((e) => e).toList();
    selectedItem = LocalStore.inst.getCountryCode;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      searchModel.filterItems(region);
    });
  }

  void _filterData(String word) {
    List<Map<String, String>> copyOriginItems = region.toList();
    if (word.isEmpty) {
      searchModel.filterItems(copyOriginItems);
      return;
    }
    List<Map<String, String>> fakeItems = [];

    for (var i = 0; i < copyOriginItems.length; i++) {
      final item = copyOriginItems.elementAt(i);
      final name = item['name'] ?? '';
      if (name.toLowerCase().contains(word.toLowerCase())) {
        fakeItems.add(item);
      }
    }
    searchModel.filterItems(fakeItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: locale.chooseCountry),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            SizedBox(
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
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                              searchModel.filterItems(region);
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
            SizedBox(height: 16.h),
            Expanded(
              child: ListenableBuilder(
                listenable: searchModel,
                builder: (context, child) {
                  return ListView.builder(
                    itemCount: searchModel.items.length,
                    itemBuilder: (context, index) {
                      final item = searchModel.items.elementAt(index);
                      final selected = selectedItem == item['code'];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['name'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Checkbox(
                            activeColor: MyColors.primary,
                            checkColor: MyColors.inputText,
                            value: selected,
                            onChanged: (value) async {
                              if (value == null) return;
                              selectedItem = item['code'] ?? 'US';
                              await context
                                  .read<AppCubit>()
                                  .changeCountry(selectedItem);
                              if (mounted) setState(() {});
                            },
                          )
                        ],
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
