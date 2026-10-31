import 'package:flutter/foundation.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/playlists_manager.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:youtube_charts/youtube_charts.dart';

class HomeController {
  // Observables for the view
  ValueListenable<String?> get announcementUrlNotifier => announcementURL;
  ValueListenable<YouTubeChartsCountry> get currentCountryNotifier =>
      youtubeChartsCountryNotifier;
  ValueListenable<int> get recentlyPlayedLengthNotifier =>
      currentRecentlyPlayedLength;
  ValueListenable<int> get recentlyPlayedVersionNotifier =>
      recentlyPlayedVersion;

  // Data fetching. Each request is kept, so rebuilding Home neither
  // refetches nor reshuffles; Retry asks again.
  final _trending = <YouTubeChartsCountry, Future<List<dynamic>>>{};
  Future<List<dynamic>>? _suggested;

  Future<List<dynamic>> getTrendingVideos(YouTubeChartsCountry country) =>
      _trending[country] ??= YouTubeChartsClient()
          .getTrendingIn(country: country)
          .catchError((Object e) {
            _trending.remove(country);
            throw e;
          });

  Future<List<dynamic>> retryTrendingVideos(YouTubeChartsCountry country) {
    _trending.remove(country);
    return getTrendingVideos(country);
  }

  Future<List<dynamic>> getSuggestedPlaylists() =>
      _suggested ??= getPlaylists(playlistsNum: 8);

  Future<List<dynamic>> retrySuggestedPlaylists() {
    _suggested = null;
    return getSuggestedPlaylists();
  }

  List<Map> getMostPlayedSongs() {
    return getMostPlayed(limit: 5);
  }

  /// The latest distinct songs, for the "Listen again" grid.
  List<Map> getRecentlyPlayed({int limit = 6}) {
    final seen = <String>{};
    return [
      for (final song in userRecentlyPlayed.whereType<Map>())
        if (seen.add(song['ytid']?.toString() ?? '')) song,
    ].take(limit).toList();
  }

  /// Morning before noon, afternoon until 6 pm, evening otherwise.
  static GreetingPart greetingFor(DateTime now) =>
      now.hour >= 5 && now.hour < 12
      ? GreetingPart.morning
      : now.hour >= 12 && now.hour < 18
      ? GreetingPart.afternoon
      : GreetingPart.evening;

  // Actions
  void dismissAnnouncement() {
    announcementURL.value = null;
  }

  /// Plays through the queue (like search) so the mini player shows the song
  /// and a spinner at once, and failures get the queue's error handling.
  void playTrendingSong(Map song) {
    audioHandler.addPlaylistToQueue([song], replace: true);
  }

  Future<void> playSongList({
    required String title,
    required List<Map> list,
    required int index,
  }) => playMostPlayedPlaylist(title: title, list: list, index: index);

  Future<void> playMostPlayedPlaylist({
    required String title,
    required List<Map> list,
    required int index,
  }) async {
    await audioHandler.playPlaylistSong(
      playlist: {'title': title, 'list': list},
      songIndex: index,
    );
  }
}

enum GreetingPart { morning, afternoon, evening }
