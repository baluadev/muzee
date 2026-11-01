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

class SearchMobileView extends StatelessWidget {
  const SearchMobileView({super.key, required this.controller});
  final search_ctrl.SearchController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: controller.songsSearchResult,
      builder: (context, songs, _) {
        return ValueListenableBuilder<List<dynamic>>(
          valueListenable: controller.albumsSearchResult,
          builder: (context, albums, _) {
            return ValueListenableBuilder<List<dynamic>>(
              valueListenable: controller.playlistsSearchResult,
              builder: (context, playlists, _) {
                final hasResults =
                    songs.isNotEmpty ||
                    albums.isNotEmpty ||
                    playlists.isNotEmpty;

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
                          onSubmitted: (String value) {
                            controller.submitSearch();
                          },
                        ),
                      ),
                    ),
                    body: Column(
                      children: <Widget>[
                        if (hasResults)
                          TabBar(
                            // Scrollable so long labels (vi: "Danh sách
                            // phát") never get squeezed.
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            labelColor: context.neo.onSurface,
                            unselectedLabelColor: context.neo.onSurfaceMuted,
                            indicatorColor: context.neo.accent,
                            dividerColor: context.neo.hairline,
                            labelStyle: Theme.of(context).textTheme.titleSmall,
                            unselectedLabelStyle: Theme.of(
                              context,
                            ).textTheme.titleSmall,
                            tabs: [
                              Tab(text: context.l10n!.songs),
                              Tab(text: context.l10n!.albums),
                              Tab(text: context.l10n!.playlists),
                            ],
                          ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: (!hasResults)
                                ? _buildNoResults(context)
                                : TabBarView(
                                    children: [
                                      _buildSongsList(context, songs),
                                      _buildAlbumsList(context, albums),
                                      _buildPlaylistsList(context, playlists),
                                    ],
                                  ),
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
      },
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.searchFailed,
      builder: (context, failed, _) => failed
          ? LoadErrorView(
              message: context.l10n!.searchFailed,
              onRetry: controller.submitSearch,
            )
          : _buildHistoryOrSuggestions(context),
    );
  }

  Widget _buildHistoryOrSuggestions(BuildContext context) {
    return ValueListenableBuilder<List>(
      valueListenable: controller.historyNotifier,
      builder: (context, searchHistory, _) {
        return ValueListenableBuilder<List<String>>(
          valueListenable: controller.suggestionsList,
          builder: (context, suggestions, _) {
            // Suggestions come from YouTube while typing; only history can be
            // removed, so only history rows get the clock icon and delete.
            final showingHistory = suggestions.isEmpty;
            final items = showingHistory ? searchHistory : suggestions;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (searchHistory.isNotEmpty && suggestions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Text(
                      context.l10n!.recentSearches,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    key: ValueKey(
                      'history-${suggestions.length}-${controller.searchBar.text}-${searchHistory.length}',
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final query = items[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () async {
                            await controller.submitSearch(query.toString());
                          },
                          onLongPress: showingHistory
                              ? () async {
                                  final confirm =
                                      await _showConfirmationDialog(context) ??
                                      false;
                                  if (confirm) {
                                    await controller.removeHistoryItem(
                                      query.toString(),
                                    );
                                  }
                                }
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.neo.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.fromLTRB(
                              16,
                              showingHistory ? 4 : 16,
                              showingHistory ? 4 : 16,
                              showingHistory ? 4 : 16,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  showingHistory
                                      ? FluentIcons.history_24_regular
                                      : FluentIcons.search_24_regular,
                                  color: context.neo.onSurfaceMuted,
                                  size: 20,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    query.toString(),
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: context.neo.onSurface,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (showingHistory)
                                  IconButton(
                                    tooltip: context.l10n!.removeSearchQuery,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => controller
                                        .removeHistoryItem(query.toString()),
                                    icon: Icon(
                                      FluentIcons.dismiss_24_regular,
                                      color: context.neo.onSurfaceMuted,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSongsList(BuildContext context, List<dynamic> songs) {
    if (songs.isEmpty)
      return _buildEmptyTab(context, context.l10n!.noSongsFound);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _songsAdSlot.count(songs.length),
      itemBuilder: (context, row) {
        if (_songsAdSlot.isAd(row, songs.length)) {
          return const NativeAdTile(
            placement: AdNativePlacement.searchResults,
            padding: EdgeInsets.only(bottom: 8),
          );
        }
        final index = _songsAdSlot.item(row, songs.length);
        final borderRadius = BorderRadius.circular(12);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: context.neo.surface,
              borderRadius: borderRadius,
            ),
            padding: const EdgeInsets.all(4),
            child: SongBar(
              songs[index],
              true,
              key: listItemKey('search_song', index, songs[index]),
              showMusicDuration: true,
              borderRadius: borderRadius,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsList(BuildContext context, List<dynamic> albums) {
    if (albums.isEmpty) {
      return _buildEmptyTab(context, context.l10n!.noAlbumsFound);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final playlist = albums[index];
        final borderRadius = BorderRadius.circular(12);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: context.neo.surface,
              borderRadius: borderRadius,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: PlaylistBar(
              key: listItemKey('search_album', index, playlist),
              playlist['title'],
              playlistId: playlist['ytid'],
              playlistArtwork: playlist['image'],
              playlistData: playlist,
              cubeIcon: FluentIcons.cd_16_filled,
              isAlbum: true,
              borderRadius: borderRadius,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsList(BuildContext context, List<dynamic> playlists) {
    if (playlists.isEmpty) {
      return _buildEmptyTab(context, context.l10n!.noPlaylistsFound);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final borderRadius = BorderRadius.circular(12);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: context.neo.surface,
              borderRadius: borderRadius,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: PlaylistBar(
              key: listItemKey('search_playlist', index, playlist),
              playlist['title'],
              playlistId: playlist['ytid'],
              playlistArtwork: playlist['image'],
              playlistData: playlist,
              cubeIcon: FluentIcons.apps_list_24_filled,
              borderRadius: borderRadius,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTab(BuildContext context, String message) {
    return Center(
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: context.neo.onSurfaceMuted),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          confirmationMessage: context.l10n!.removeSearchQueryQuestion,
          submitMessage: context.l10n!.confirm,
          onCancel: () {
            Navigator.of(context).pop(false);
          },
          onSubmit: () {
            Navigator.of(context).pop(true);
          },
        );
      },
    );
  }
}

/// One native ad after the first four song results.
const _songsAdSlot = InlineAdSlot(4);
