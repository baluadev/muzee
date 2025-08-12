import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/search/search_cubit.dart';
import 'package:muzee/components/option_menu.dart';
import 'package:muzee/components/song_horiz_widget.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/packages/loadmore/loadmore.dart';
import 'package:muzee/services/firebase/remote_service.dart';

class SearchResult extends StatelessWidget {
  const SearchResult({super.key});

  @override
  Widget build(BuildContext context) {
    int adFrequency = RMConfigService.inst.adFrequency;
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (previous, current) => current is SearchResultState,
      builder: (context, state) {
        List<SongModel> songs = [];

        if (state is SearchResultState) {
          songs = state.songs ?? [];
        }
        final int totalItems = songs.length + (songs.length ~/ adFrequency);
        return LoadMore(
          isFinish: totalItems == 0,
          onLoadMore: () async {
            return await context.read<SearchCubit>().searchMore();
          },
          textBuilder: DefaultLoadMoreTextBuilder.english,
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              final int numAdsShown = index ~/ (adFrequency + 1);
              if ((index + 1) % (adFrequency + 1) == 0) {
                return context.read<AppCubit>().songNativeAdManager;
              }
              final int songIndex = index - numAdsShown;

              final item = songs.elementAt(songIndex);
              return SongHorizWidget(
                song: item,
                optionMenu: OptionMenu(
                  song: item,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
