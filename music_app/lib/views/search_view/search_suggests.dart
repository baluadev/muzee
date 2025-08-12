import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/search/search_cubit.dart';

class SearchSuggests extends StatelessWidget {
  const SearchSuggests({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (_, state) => state is SearchSuggestState,
      builder: (_, state) {
        List<String> suggests = [];
        if (state is SearchSuggestState) {
          suggests = state.suggests;
        }

        return ListView.builder(
          itemCount: suggests.length,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
          itemBuilder: (context, index) {
            final keyword = suggests[index];
            return InkWell(
              onTap: () => context.read<SearchCubit>().searchSong(keyword),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                child: Text(
                  keyword,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
