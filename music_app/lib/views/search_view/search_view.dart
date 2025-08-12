import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/search/search_cubit.dart';

import '../../pages/search/appbar_search.dart';
import 'search_history.dart';
import 'search_result.dart';
import 'search_suggests.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late SearchCubit _searchCubit;
  @override
  void initState() {
    super.initState();
    _searchCubit = context.read<SearchCubit>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _searchCubit.getHistories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        return Scaffold(
          appBar: const AppBarSearch(),
          body: Column(
            children: [
              context.read<AppCubit>().nativeAdManager,
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _searchCubit.pageController,
                  children: const [
                    SearchHistory(),
                    SearchSuggests(),
                    SearchResult(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
