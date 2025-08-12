part of 'library_cubit.dart';

sealed class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object> get props => [];
}

final class LibraryInitial extends LibraryState {}

class PlaylistLoading extends LibraryState {}

class PlaylistUpdate extends LibraryState {
  final PlaylistModel? playlist;
  const PlaylistUpdate({
    this.playlist,
  });

  @override
  List<Object> get props => [playlist ?? []];
}

class PlaylistListUpdate extends LibraryState {
  final List<PlaylistModel>? playlists;

  const PlaylistListUpdate({
    this.playlists,
  });

  @override
  List<Object> get props => [playlists ?? []];
}

class PlaylistResultSearchState extends LibraryState {
  final List<PlaylistModel>? playlists;
  final bool isLoading;

  const PlaylistResultSearchState({
    this.playlists,
    this.isLoading = false,
  });

  @override
  List<Object> get props => [playlists ?? []];
}

class ArtistFollowState extends LibraryState {
  final List<ArtistModel>? artists;

  const ArtistFollowState({
    this.artists,
  });

  @override
  List<Object> get props => [artists ?? []];
}

class PlaylistRecentlyUpdate extends LibraryState {
  final List<SongModel>? songs;

  const PlaylistRecentlyUpdate({
    this.songs,
  });

  @override
  List<Object> get props => [songs ?? []];
}

class PlaylistLibraryUpdate extends LibraryState {
  final List<SongModel>? songs;

  const PlaylistLibraryUpdate({
    this.songs,
  });

  @override
  List<Object> get props => [songs ?? []];
}

class PlaylistLikedUpdate extends LibraryState {
  final List<SongModel>? songs;

  const PlaylistLikedUpdate({
    this.songs,
  });

  @override
  List<Object> get props => [songs ?? []];
}

class YtbPlaylistListUpdate extends LibraryState {
  final List<PlaylistModel>? playlists;

  const YtbPlaylistListUpdate({
    this.playlists,
  });

  @override
  List<Object> get props => [playlists ?? []];
}


class PlaylistFailure extends LibraryState {}
