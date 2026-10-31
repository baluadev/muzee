import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/firebase/analytics_service.dart';
import 'package:muzee/services/playlists_manager.dart';

// Global ValueNotifier for search history
final ValueNotifier<List> searchHistoryNotifier = ValueNotifier<List>(
  Hive.box('user').get('searchHistory', defaultValue: []),
);

class SearchController {
  final TextEditingController searchBar = TextEditingController();
  final FocusNode inputNode = FocusNode();

  final ValueNotifier<bool> fetchingSongs = ValueNotifier(false);
  final ValueNotifier<List<dynamic>> songsSearchResult = ValueNotifier([]);
  final ValueNotifier<List<dynamic>> albumsSearchResult = ValueNotifier([]);
  final ValueNotifier<List<dynamic>> playlistsSearchResult = ValueNotifier([]);
  final ValueNotifier<List<String>> suggestionsList = ValueNotifier([]);

  /// True when the last search failed (network, quota, YouTube error), as
  /// opposed to finding nothing.
  final ValueNotifier<bool> searchFailed = ValueNotifier(false);

  Timer? _debounce;
  int _latestSuggestionRequest = 0;

  ValueNotifier<List> get historyNotifier => searchHistoryNotifier;

  void dispose() {
    searchBar.dispose();
    inputNode.dispose();
    fetchingSongs.dispose();
    songsSearchResult.dispose();
    albumsSearchResult.dispose();
    playlistsSearchResult.dispose();
    suggestionsList.dispose();
    searchFailed.dispose();
    _debounce?.cancel();
  }

  void onSearchQueryChanged(String query) {
    _debounce?.cancel();
    searchFailed.value = false;
    final requestId = ++_latestSuggestionRequest;

    if (query.isEmpty) {
      suggestionsList.value = [];
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final searchSuggestions = await getSearchSuggestions(query);

      if (requestId != _latestSuggestionRequest || searchBar.text != query) {
        return;
      }

      suggestionsList.value = List<String>.from(searchSuggestions);
    });
  }

  Future<void> submitSearch([String? query]) async {
    if (query != null) {
      searchBar.text = query;
      searchBar.selection = TextSelection.fromPosition(
        TextPosition(offset: searchBar.text.length),
      );
    }

    _latestSuggestionRequest++;
    _debounce?.cancel();
    suggestionsList.value = [];

    final keyword = searchBar.text.trim();
    if (keyword.isNotEmpty) unawaited(AnalyticsService.logSearch(keyword));
    await _performSearch();
    inputNode.unfocus();
  }

  Future<void> _performSearch() async {
    final query = searchBar.text;

    if (query.isEmpty) {
      songsSearchResult.value = [];
      albumsSearchResult.value = [];
      playlistsSearchResult.value = [];
      suggestionsList.value = [];
      return;
    }

    fetchingSongs.value = true;
    searchFailed.value = false;

    final currentHistory = searchHistoryNotifier.value;
    if (!currentHistory.contains(query)) {
      final updatedHistory = List.from(currentHistory)..insert(0, query);
      searchHistoryNotifier.value = updatedHistory;
      unawaited(addOrUpdateData('user', 'searchHistory', updatedHistory));
    }

    try {
      final songs = await fetchSongsList(query);
      final albums = await getPlaylists(query: query, type: 'album');
      final playlists = await getPlaylists(query: query, type: 'playlist');

      songsSearchResult.value = songs;
      albumsSearchResult.value = albums;
      playlistsSearchResult.value = playlists;
    } catch (e, stackTrace) {
      logger.log(
        'Error while searching online songs',
        error: e,
        stackTrace: stackTrace,
      );
      songsSearchResult.value = [];
      albumsSearchResult.value = [];
      playlistsSearchResult.value = [];
      searchFailed.value = true;
    } finally {
      fetchingSongs.value = false;
    }
  }

  Future<void> removeHistoryItem(String query) async {
    final currentHistory = searchHistoryNotifier.value;
    if (currentHistory.contains(query)) {
      final updatedHistory = List.from(currentHistory)..remove(query);
      searchHistoryNotifier.value = updatedHistory;
      unawaited(addOrUpdateData('user', 'searchHistory', updatedHistory));
    }
  }
}
