import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/screens/search/search_controller.dart' as search_ctrl;
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/app_utils.dart';
import 'package:muzee/widgets/confirmation_dialog.dart';
import 'package:muzee/widgets/custom_search_bar.dart';
import 'package:muzee/widgets/load_error_view.dart';
import 'package:muzee/widgets/monetization/native_ad_tile.dart';
import 'package:muzee/widgets/playlist_bar.dart';
import 'package:muzee/widgets/song_bar.dart';

/// Search: history and suggestions while typing, then songs, albums and
/// playlists in tabs. The field and the tabs stay put while results come
/// in (songs first, then albums and playlists), so the chosen tab is kept.
class SearchMobileView extends StatelessWidget {
  const SearchMobileView({super.key, required this.controller});
  final search_ctrl.SearchController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: CustomSearchBar(
              loadingProgressNotifier: controller.fetchingSongs,
              controller: controller.searchBar,
              focusNode: controller.inputNode,
              labelText: context.l10n!.searchHint,
              onChanged: controller.onSearchQueryChanged,
              onSubmitted: (_) => controller.submitSearch(),
            ),
          ),
        ),
        body: ValueListenableBuilder<bool>(
          valueListenable: controller.showingResults,
          builder: (context, showingResults, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: showingResults
                ? _Results(controller: controller)
                : _HistoryOrSuggestions(controller: controller),
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.controller});
  final search_ctrl.SearchController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        TabBar(
          // Scrollable so long labels (vi: "Danh sách phát") never get
          // squeezed.
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          labelColor: context.neo.onSurface,
          unselectedLabelColor: context.neo.onSurfaceMuted,
          indicatorColor: context.neo.accent,
          dividerColor: context.neo.hairline,
          labelStyle: text.titleSmall,
          unselectedLabelStyle: text.titleSmall,
          tabs: [
            Tab(text: l10n.songs),
            Tab(text: l10n.albums),
            Tab(text: l10n.playlists),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _SongsTab(controller: controller),
              _CollectionTab(
                results: controller.albumsSearchResult,
                loading: controller.fetchingCollections,
                emptyMessage: l10n.noAlbumsFound,
                isAlbum: true,
              ),
              _CollectionTab(
                results: controller.playlistsSearchResult,
                loading: controller.fetchingCollections,
                emptyMessage: l10n.noPlaylistsFound,
                isAlbum: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SongsTab extends StatelessWidget {
  const _SongsTab({required this.controller});
  final search_ctrl.SearchController controller;

  /// One native ad after the first four song results.
  static const _adSlot = InlineAdSlot(4);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.songsSearchResult,
        controller.fetchingSongs,
        controller.searchFailed,
      ]),
      builder: (context, _) {
        final songs = controller.songsSearchResult.value;
        if (controller.searchFailed.value) {
          return LoadErrorView(
            message: context.l10n!.searchFailed,
            onRetry: controller.submitSearch,
          );
        }
        if (songs.isEmpty) {
          return controller.fetchingSongs.value
              ? const _Loading()
              : _EmptyTab(context.l10n!.noSongsFound);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: _adSlot.count(songs.length),
          itemBuilder: (context, row) {
            if (_adSlot.isAd(row, songs.length)) {
              return const NativeAdTile(
                placement: AdNativePlacement.searchResults,
                padding: EdgeInsets.only(bottom: 8),
              );
            }
            final index = _adSlot.item(row, songs.length);
            final borderRadius = BorderRadius.circular(12);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.neo.surface,
                  borderRadius: borderRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SongBar(
                    songs[index],
                    true,
                    key: listItemKey('search_song', index, songs[index]),
                    showMusicDuration: true,
                    borderRadius: borderRadius,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CollectionTab extends StatelessWidget {
  const _CollectionTab({
    required this.results,
    required this.loading,
    required this.emptyMessage,
    required this.isAlbum,
  });

  final ValueNotifier<List<dynamic>> results;
  final ValueNotifier<bool> loading;
  final String emptyMessage;
  final bool isAlbum;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([results, loading]),
      builder: (context, _) {
        final items = results.value;
        if (items.isEmpty) {
          return loading.value ? const _Loading() : _EmptyTab(emptyMessage);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final playlist = items[index];
            final borderRadius = BorderRadius.circular(12);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.neo.surface,
                  borderRadius: borderRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: PlaylistBar(
                    key: listItemKey(
                      isAlbum ? 'search_album' : 'search_playlist',
                      index,
                      playlist,
                    ),
                    playlist['title'],
                    playlistId: playlist['ytid'],
                    playlistArtwork: playlist['image'],
                    playlistData: playlist,
                    cubeIcon: isAlbum
                        ? FluentIcons.cd_16_filled
                        : FluentIcons.apps_list_24_filled,
                    isAlbum: isAlbum,
                    borderRadius: borderRadius,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HistoryOrSuggestions extends StatelessWidget {
  const _HistoryOrSuggestions({required this.controller});
  final search_ctrl.SearchController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.historyNotifier,
        controller.suggestionsList,
        controller.searchFailed,
      ]),
      builder: (context, _) {
        if (controller.searchFailed.value) {
          return LoadErrorView(
            message: context.l10n!.searchFailed,
            onRetry: controller.submitSearch,
          );
        }
        final history = controller.historyNotifier.value;
        final suggestions = controller.suggestionsList.value;
        // Suggestions come from YouTube while typing; only history can be
        // removed, so only history rows get the clock icon and delete.
        final showingHistory = suggestions.isEmpty;
        final items = showingHistory ? history : suggestions;
        final l10n = context.l10n!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showingHistory && history.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.recentSearches,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _confirmClearHistory(context),
                      child: Text(l10n.clearAll),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                // One list for history, one for suggestions: switching
                // between them starts at the top; typing doesn't.
                key: ValueKey(showingHistory),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: items.length,
                itemBuilder: (context, index) => _QueryRow(
                  query: items[index].toString(),
                  isHistory: showingHistory,
                  controller: controller,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        confirmationMessage: context.l10n!.clearSearchHistoryQuestion,
        submitMessage: context.l10n!.clear,
        isDangerous: true,
        onCancel: () => Navigator.pop(dialogContext),
        onSubmit: () {
          Navigator.pop(dialogContext);
          controller.clearHistory();
        },
      ),
    );
  }
}

class _QueryRow extends StatelessWidget {
  const _QueryRow({
    required this.query,
    required this.isHistory,
    required this.controller,
  });

  final String query;
  final bool isHistory;
  final search_ctrl.SearchController controller;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: neo.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => controller.submitSearch(query),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              isHistory ? 4 : 16,
              isHistory ? 4 : 16,
              isHistory ? 4 : 16,
            ),
            child: Row(
              children: [
                Icon(
                  isHistory
                      ? FluentIcons.history_24_regular
                      : FluentIcons.search_24_regular,
                  color: neo.onSurfaceMuted,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    query,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: neo.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isHistory)
                  IconButton(
                    tooltip: context.l10n!.removeSearchQuery,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.removeHistoryItem(query),
                    icon: Icon(
                      FluentIcons.dismiss_24_regular,
                      color: neo.onSurfaceMuted,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: context.neo.onSurfaceMuted),
    ),
  );
}
