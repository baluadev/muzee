import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/search/search_cubit.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/services/firebase/analytics_service.dart';

class AppBarSearch extends StatelessWidget implements PreferredSizeWidget {
  const AppBarSearch({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final searchCubit = context.read<SearchCubit>();
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        final textFull = searchCubit.textEditingController.text.isNotEmpty;
        return SafeArea(
          left: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Assets.icons.icBack.image(width: 40, height: 40),
                ),
              ),
              Expanded(
                child: SizedBox(
                  child: TextField(
                    autocorrect: false,
                    controller: searchCubit.textEditingController,
                    focusNode: searchCubit.focusNode,
                    enableSuggestions: false,
                    autofocus: true,
                    cursorColor: MyColors.primary,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: locale.search,
                      hintStyle: TextStyle(
                        color: MyColors.primary.withOpacity(0.5),
                        fontSize: 14.sp,
                      ),
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: MyColors.background,
                      filled: true,
                      contentPadding: const EdgeInsets.only(
                          bottom: 10, left: 16, right: 16),
                      suffix: textFull
                          ? GestureDetector(
                              onTap: () => searchCubit.clearSearchBar(),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 16.0),
                                child: Text('Xóa'),
                              ),
                            )
                          : const SizedBox(),
                    ),
                    onChanged: (value) {
                      searchCubit.isSubmit = false;
                    },
                    onSubmitted: (value) {
                      searchCubit.searchSong(value);
                      FirebaseAnalyticsService.inst.logKeySearchEvent(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
