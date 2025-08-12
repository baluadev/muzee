part of 'search_cubit.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

final class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {
  final List<SongModel>? songs;

  const SearchLoading({this.songs});

  @override
  List<Object> get props => [songs ?? []];
}

class SearchHistoryState extends SearchState {
  final List<SearchHistoryModel> histories;

  const SearchHistoryState({
    required this.histories,
  });

  @override
  List<Object> get props => [histories];
}

class SearchSuggestState extends SearchState {
  final List<String> suggests;

  const SearchSuggestState(this.suggests);

  @override
  List<Object> get props => [suggests];
}

class SearchResultState extends SearchState {
  final List<SongModel>? songs;

  const SearchResultState({this.songs});

  @override
  List<Object> get props => [songs ?? []];
}

