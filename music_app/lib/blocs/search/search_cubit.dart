import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzee/models/search_history_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/services/api_client/api_client.dart';
import 'package:muzee/services/database/db_service.dart';
import 'package:muzee/services/ytb/ytb_service.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial()) {
    textEditingController.addListener(textEditListener);

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        // searchMore();
      }
    });
  }
  bool isSubmit = false;
  final PageController pageController = PageController();
  final TextEditingController textEditingController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  void textEditListener() async {
    if (!isSubmit) {
      String search = textEditingController.text;
      if (search.isNotEmpty) {
        final suggests = await ApiClient.inst.fetchSuggestions(search);
        jumpSearchSuggests();
        emit(SearchSuggestState(suggests));
      } else {
        getHistories();
      }
    }
  }

  void clearSearchBar() {
    textEditingController.clear();
    getHistories();
  }

  void jumpHistory() {
    pageController.jumpToPage(0);
  }

  void jumpSearchSuggests() {
    pageController.jumpToPage(1);
  }

  void jumpSearchResult() {
    pageController.jumpToPage(2);
  }

  Future getHistories() async {
    final histories = await DBService.inst.getRecentSearches();
    jumpHistory();
    emit(SearchHistoryState(histories: histories));
  }

  Future deleteHistory(int id) async {
    await DBService.inst.deleteSearchHistory(id);
    getHistories();
  }

  Future clearHistory() async {
    await DBService.inst.clearAllSearchHistory();
    getHistories();
  }

  List<SongModel> songs = [];
  Future searchSong(String keyword) async {
    isSubmit = true;
    focusNode.unfocus();
    textEditingController.text = keyword;
    //jump page
    jumpSearchResult();
    //save history
    DBService.inst.addSearchHistory(keyword: keyword, type: 'song');
    //request
    songs = await YtbService.searchVideos(keyword);
    emit(SearchResultState(songs: songs));
  }

  Future searchMore() async {
    emit(SearchLoading(songs: songs));
    final songsMore = await YtbService.searchMoreVideos();
    if (songsMore.isNotEmpty) {
      songs += songsMore;
      emit(SearchResultState(songs: songs));
      return true;
    } else {
      emit(SearchResultState(songs: songs));
      return false;
    }
  }
}
