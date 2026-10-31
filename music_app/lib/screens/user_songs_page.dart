import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/constants/app_constants.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart' show logger, audioHandler;
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/utilities/app_utils.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/utilities/playlist_utils.dart';
import 'package:muzee/utilities/song_filtering.dart';
import 'package:muzee/widgets/confirmation_dialog.dart';
import 'package:muzee/widgets/playlist_cube.dart';
import 'package:muzee/widgets/playlist_page/empty_playlist_state.dart';
import 'package:muzee/widgets/playlist_page/play_shuffle_buttons.dart';
import 'package:muzee/widgets/playlist_page/playlist_header.dart';
import 'package:muzee/widgets/playlist_page/search_bar_section.dart';
import 'package:muzee/widgets/song_bar.dart';

class UserSongsPage extends StatefulWidget {
  const UserSongsPage({super.key, required this.page});

  final String page;

  @override
  State<UserSongsPage> createState() => _UserSongsPageState();
}

class _UserSongsPageState extends State<UserSongsPage> {
  bool _isEditEnabled = false;
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  List _getDisplayList(List songsList) =>
      filterSongsByQuery(songsList, _searchQueryNotifier.value);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = getTitle(widget.page, context);
    final icon = getIcon(widget.page);
    final songsList = getSongsList(widget.page);
    final length = getLength(widget.page);
    final isLikedSongs = widget.page == 'liked';
    final isRecents = widget.page == 'recents';

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (isLikedSongs && songsList.isNotEmpty)
            IconButton(
              tooltip: context.l10n!.reorder,
              isSelected: _isEditEnabled,
              onPressed: _toggleEditMode,
              icon: const Icon(FluentIcons.re_order_24_regular),
              selectedIcon: const Icon(FluentIcons.re_order_24_filled),
            ),
          if (isRecents && songsList.isNotEmpty)
            TextButton(
              onPressed: _confirmClearRecents,
              child: Text(context.l10n!.clear),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildCustomScrollView(title, icon, songsList, length),
    );
  }

  void _toggleEditMode() {
    setState(() => _isEditEnabled = !_isEditEnabled);
  }

  Widget _buildCustomScrollView(
    String title,
    IconData icon,
    List songsList,
    ValueNotifier<int> length,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeaderSection(title, icon, songsList.length),
        ),
        buildSongList(title, songsList, length),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  String getTitle(String page, BuildContext context) {
    return switch (page) {
      'liked' => context.l10n!.likedSongs,
      'recents' => context.l10n!.recentlyPlayed,
      _ => context.l10n!.playlist,
    };
  }

  IconData getIcon(String page) {
    return switch (page) {
      'liked' => FluentIcons.heart_24_regular,
      'recents' => FluentIcons.history_24_regular,
      _ => FluentIcons.heart_24_regular,
    };
  }

  List getSongsList(String page) {
    return switch (page) {
      'liked' => userLikedSongsList,
      'recents' => userRecentlyPlayed,
      _ => userLikedSongsList,
    };
  }

  ValueNotifier<int> getLength(String page) {
    return switch (page) {
      'liked' => currentLikedSongsLength,
      'recents' => currentRecentlyPlayedLength,
      _ => currentLikedSongsLength,
    };
  }

  Widget _buildHeaderSection(String title, IconData icon, int songsLength) {
    final l10n = context.l10n!;

    return Column(
      children: [
        PlaylistHeader(
          _buildPlaylistImage(title, icon),
          title,
          songsLength,
          owner: '',
        ),
        if (songsLength > 0) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: PlayShuffleButtons(
              onPlay: () => audioHandler.playPlaylistSong(
                playlist: _playlist(title, getSongsList(widget.page)),
                songIndex: 0,
              ),
              onShuffle: () async {
                final songs = getSongsList(widget.page);
                if (songs.isEmpty) return;
                final shuffled = List<Map>.from(songs.whereType<Map>())
                  ..shuffle();
                await audioHandler.addPlaylistToQueue(
                  shuffled,
                  replace: true,
                  startIndex: 0,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SearchBarSection(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onSearchChanged: (value) => _searchQueryNotifier.value = value,
            labelText: l10n.search,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Map<String, dynamic> _playlist(String title, List songs) => {
    'ytid': '',
    'title': title,
    'source': 'user-created',
    'list': songs,
  };

  Widget _buildPlaylistImage(String title, IconData icon) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLandscape = screenWidth > MediaQuery.sizeOf(context).height;
    return PlaylistCube(
      {'title': title},
      size: isLandscape ? 250 : screenWidth / commonPlaylistArtworkDivision,
      cubeIcon: icon,
    );
  }

  void _confirmClearRecents() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          confirmationMessage: context.l10n!.clearRecentlyPlayedQuestion,
          submitMessage: context.l10n!.clear,
          isDangerous: true,
          onCancel: () => Navigator.pop(context),
          onSubmit: () {
            Navigator.pop(context);
            userRecentlyPlayed.clear();
            currentRecentlyPlayedLength.value = 0;
            addOrUpdateData('user', 'recentlyPlayedSongs', []);
            showToast(context, context.l10n!.recentlyPlayedMsg);
          },
        );
      },
    );
  }

  Widget buildSongList(
    String title,
    List songsList,
    ValueNotifier<int> currentSongsLength,
  ) {
    final isLikedSongs = widget.page == 'liked';
    final isRecentlyPlayed = widget.page == 'recents';

    return ValueListenableBuilder(
      valueListenable: currentSongsLength,
      builder: (_, value, __) {
        return ValueListenableBuilder<String>(
          valueListenable: _searchQueryNotifier,
          builder: (_, searchQuery, __) {
            final isSearching = searchQuery.isNotEmpty;
            final displayList = _getDisplayList(songsList);
            final playlist = _playlist(title, songsList);

            if (displayList.isEmpty) {
              final emptyIcon = isLikedSongs
                  ? FluentIcons.heart_24_regular
                  : FluentIcons.text_bullet_list_24_filled;
              return EmptyPlaylistState(
                icon: emptyIcon,
                message: context.l10n!.playlistEmpty,
              );
            }

            if (isLikedSongs && !isSearching) {
              return SliverReorderableList(
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final song = displayList[index];
                  final borderRadius = getItemBorderRadius(
                    index,
                    displayList.length,
                  );
                  return ReorderableDragStartListener(
                    enabled: _isEditEnabled,
                    key: listItemKey('liked_song', index, song),
                    index: index,
                    child: _buildSongBar(
                      song,
                      index,
                      borderRadius,
                      playlist,
                      isRecentSong: isRecentlyPlayed,
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    moveLikedSong(oldIndex, newIndex);
                  });
                },
              );
            } else {
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = displayList[index];
                  final borderRadius = getItemBorderRadius(
                    index,
                    displayList.length,
                  );
                  return RepaintBoundary(
                    key: listItemKey('user_song_row', index, song),
                    child: _buildSongBar(
                      song,
                      index,
                      borderRadius,
                      playlist,
                      isRecentSong: isRecentlyPlayed,
                    ),
                  );
                }, childCount: displayList.length),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSongBar(
    Map song,
    int index,
    BorderRadius borderRadius,
    Map playlist, {
    bool isRecentSong = false,
  }) {
    final isLikedSongs = widget.page == 'liked';

    return SongBar(
      key: listItemKey('user_song', index, song),
      song,
      true,
      onPlay: () {
        final fullIndex = PlaylistUtils.findSongIndexByYtid(
          playlist,
          song['ytid'],
        );
        if (fullIndex == -1) {
          logger.log(
            'Warning: Song ${song['ytid']} not found in full song list',
          );
        }
        audioHandler.playPlaylistSong(
          playlist: playlist,
          songIndex: fullIndex != -1 ? fullIndex : index,
        );
      },
      borderRadius: borderRadius,
      isRecentSong: isRecentSong,
      isFromLikedSongs: isLikedSongs,
    );
  }
}
