import 'package:flutter/foundation.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/utilities/formatter.dart';
import 'package:youtube_charts/youtube_charts.dart';

class ExploreController {
  // Observables for the view
  ValueListenable<YouTubeChartsCountry> get currentCountryNotifier =>
      youtubeChartsCountryNotifier;

  // Data fetching. Kept per country so rebuilds don't refetch; Retry does.
  final _topVideos = <YouTubeChartsCountry, Future<List<dynamic>>>{};
  final _topArtists = <YouTubeChartsCountry, Future<List<dynamic>>>{};

  static Future<List<dynamic>> _keep(
    Map<YouTubeChartsCountry, Future<List<dynamic>>> cache,
    YouTubeChartsCountry country,
    Future<List<dynamic>> Function() fetch,
  ) => cache[country] ??= fetch().catchError((Object e) {
    cache.remove(country);
    throw e;
  });

  Future<List<dynamic>> getTopVideos(YouTubeChartsCountry country) => _keep(
    _topVideos,
    country,
    () => YouTubeChartsClient().getTopVideos(country: country),
  );

  Future<List<dynamic>> retryTopVideos(YouTubeChartsCountry country) {
    _topVideos.remove(country);
    return getTopVideos(country);
  }

  Future<List<dynamic>> getTopArtists(YouTubeChartsCountry country) => _keep(
    _topArtists,
    country,
    () => YouTubeChartsClient().getTopArtists(country: country),
  );

  Future<List<dynamic>> retryTopArtists(YouTubeChartsCountry country) {
    _topArtists.remove(country);
    return getTopArtists(country);
  }

  // Actions
  /// Plays through the queue; see HomeController.playTrendingSong.
  void playSong(Map<String, dynamic> song) {
    audioHandler.addPlaylistToQueue([song], replace: true);
  }

  /// Plays the chart from [index], so Next goes on down the chart.
  void playSongs(List<Map<String, dynamic>> songs, int index) {
    audioHandler.addPlaylistToQueue(songs, replace: true, startIndex: index);
  }

  Map<String, dynamic> mapVideo(String unknownArtistString, dynamic song) {
    String? highRes;
    String? lowRes;
    final thumbnailObj = song['thumbnail'];
    if (thumbnailObj != null && thumbnailObj['thumbnails'] != null) {
      final thumbnails = thumbnailObj['thumbnails'] as List;
      if (thumbnails.isNotEmpty) {
        lowRes = thumbnails.first['url'] as String?;
        highRes = thumbnails.last['url'] as String?;
      }
    }

    var artistNames = unknownArtistString;
    if (song['artists'] != null) {
      final artists = song['artists'] as List;
      artistNames = artists.map((a) => a['name']).join(', ');
    }

    final ytid = song['encryptedVideoId'] ?? song['id'] ?? '';
    return {
      'id': ytid,
      'ytid': ytid,
      'title': formatChartTitle(
        (song['title'] ?? song['name'] ?? '').toString(),
        artistNames,
      ),
      'artist': artistNames,
      'image': highRes ?? lowRes,
      'highResImage': highRes,
      'lowResImage': lowRes,
    };
  }
}
