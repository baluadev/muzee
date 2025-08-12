import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/search/search_cubit.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/models/search_history_model.dart';

class SearchHistory extends StatelessWidget {
  const SearchHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (_, state) => state is SearchHistoryState,
      builder: (_, state) {
        List<SearchHistoryModel> histories = [];
        if (state is SearchHistoryState) {
          histories = state.histories;
        }

        return ListView.builder(
          itemCount: histories.length,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
          itemBuilder: (context, index) {
            final history = histories[index];
            return InkWell(
              onTap: () {
                context.read<SearchCubit>().searchSong(history.keyword);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        history.keyword,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          context.read<SearchCubit>().deleteHistory(history.id),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: Assets.icons.icClose.svg(fit: BoxFit.fill),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
