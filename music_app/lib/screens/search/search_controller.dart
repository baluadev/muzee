import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/firebase/analytics_service.dart';
import 'package:muzee/services/playlists_manager.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart'
    show TransientFailureException;

// Global ValueNotifier for search history
final ValueNotifier<List> searchHistoryNotifier = ValueNotifier<List>(
  Hive.box('user').get('searchHistory', defaultValue: []),
);

/// Most searches kept in the history.
const searchHistoryLimit = 30;

/// Results of one search, kept for a while so going back to it is instant.
class _CachedSearch {
  _CachedSearch(this.songs, this.albums, this.playlists);

  final List<dynamic> songs;
  final List<dynamic> albums;
  final List<dynamic> playlists;
  final DateTime at = DateTime.now();
}

class SearchController {
  final TextEditingController searchBar = TextEditingController();
  final FocusNode inputNode = FocusNode();

  /// The song search is running (it drives the field's progress bar).
  final ValueNotifier<bool> fetchingSongs = ValueNotifier(false);

  /// The album and playlist searches are running.
  final ValueNotifier<bool> fetchingCollections = ValueNotifier(false);

  final ValueNotifier<List<dynamic>> songsSearchResult = ValueNotifier([]);
  final ValueNotifier<List<dynamic>> albumsSearchResult = ValueNotifier([]);
  final ValueNotifier<List<dynamic>> playlistsSearchResult = ValueNotifier([]);
  final ValueNotifier<List<String>> suggestionsList = ValueNotifier([]);

  /// Results are on screen (a search was submitted and the text hasn't
  /// changed since). Otherwise the page shows history or suggestions.
  final ValueNotifier<bool> showingResults = ValueNotifier(false);

  /// True when the last search failed (network, quota, YouTube error), as
  /// opposed to finding nothing.
  final ValueNotifier<bool> searchFailed = ValueNotifier(false);

  Timer? _debounce;
  int _latestSuggestionRequest = 0;
  int _latestSearch = 0;

  static const _cacheSize = 10;
  static const _cacheFor = Duration(minutes: 10);
  final _cache = <String, _CachedSearch>{};

  ValueNotifier<List> get historyNotifier => searchHistoryNotifier;

  void dispose() {
    searchBar.dispose();
    inputNode.dispose();
    fetchingSongs.dispose();
    fetchingCollections.dispose();
    songsSearchResult.dispose();
    albumsSearchResult.dispose();
    playlistsSearchResult.dispose();
    suggestionsList.dispose();
    showingResults.dispose();
    searchFailed.dispose();
    _debounce?.cancel();
  }

  void onSearchQueryChanged(String query) {
    _debounce?.cancel();
    searchFailed.value = false;
    // Editing the query goes back to history / suggestions.
    showingResults.value = false;
    final requestId = ++_latestSuggestionRequest;

    if (query.trim().isEmpty) {
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
    inputNode.unfocus();
    await _performSearch();
  }

  Future<void> _performSearch() async {
    final query = searchBar.text.trim();
    final searchId = ++_latestSearch;
    bool current() => searchId == _latestSearch;

    if (query.isEmpty) {
      songsSearchResult.value = [];
      albumsSearchResult.value = [];
      playlistsSearchResult.value = [];
      suggestionsList.value = [];
      showingResults.value = false;
      return;
    }

    _remember(query);
    searchFailed.value = false;
    showingResults.value = true;

    final cached = _cache[query];
    if (cached != null && DateTime.now().difference(cached.at) < _cacheFor) {
      songsSearchResult.value = cached.songs;
      albumsSearchResult.value = cached.albums;
      playlistsSearchResult.value = cached.playlists;
      fetchingSongs.value = false;
      fetchingCollections.value = false;
      return;
    }

    songsSearchResult.value = [];
    albumsSearchResult.value = [];
    playlistsSearchResult.value = [];
    fetchingSongs.value = true;
    fetchingCollections.value = true;

    // All three at once; songs show as soon as they arrive. YouTube now and
    // then answers a search with a page missing its data: one quick retry
    // saves the listener a tap on "Try again".
    final songsFuture = fetchSongsList(query).catchError((Object _) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return fetchSongsList(query);
    }, test: (e) => e is TransientFailureException);
    // Handled right away: it may fail while the songs are still awaited.
    final collectionsFuture =
        Future.wait([
          getPlaylists(query: query, type: 'album'),
          getPlaylists(query: query, type: 'playlist'),
        ]).then<List<List<dynamic>>?>(
          (lists) => lists,
          onError: (Object e, StackTrace stackTrace) {
            logger.log(
              'Error while searching albums and playlists',
              error: e,
              stackTrace: stackTrace,
            );
            return null;
          },
        );

    var songsOk = false;
    try {
      final songs = await songsFuture;
      if (!current()) return;
      songsSearchResult.value = songs;
      songsOk = true;
    } catch (e, stackTrace) {
      logger.log(
        'Error while searching online songs',
        error: e,
        stackTrace: stackTrace,
      );
      if (current()) searchFailed.value = true;
    } finally {
      if (current()) fetchingSongs.value = false;
    }

    try {
      final collections = await collectionsFuture;
      if (!current() || collections == null) return;
      albumsSearchResult.value = collections[0];
      playlistsSearchResult.value = collections[1];
      if (songsOk) {
        _cache
          ..remove(query)
          ..[query] = _CachedSearch(
            songsSearchResult.value,
            collections[0],
            collections[1],
          );
        if (_cache.length > _cacheSize) _cache.remove(_cache.keys.first);
      }
    } finally {
      if (current()) fetchingCollections.value = false;
    }
  }

  /// Puts [query] first in the history (once), keeping the latest
  /// [searchHistoryLimit].
  void _remember(String query) {
    final updated = [
      query,
      ...searchHistoryNotifier.value.where((q) => q != query),
    ].take(searchHistoryLimit).toList();
    searchHistoryNotifier.value = updated;
    unawaited(addOrUpdateData('user', 'searchHistory', updated));
  }

  Future<void> removeHistoryItem(String query) async {
    final currentHistory = searchHistoryNotifier.value;
    if (currentHistory.contains(query)) {
      final updatedHistory = List.from(currentHistory)..remove(query);
      searchHistoryNotifier.value = updatedHistory;
      unawaited(addOrUpdateData('user', 'searchHistory', updatedHistory));
    }
  }

  Future<void> clearHistory() async {
    searchHistoryNotifier.value = [];
    await addOrUpdateData('user', 'searchHistory', []);
  }
}
