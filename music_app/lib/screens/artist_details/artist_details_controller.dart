import 'package:flutter/material.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:youtube_charts/youtube_charts.dart';

class ArtistDetailsController {
  ArtistDetailsController({required this.artistId});
  final String artistId;

  ValueNotifier<YouTubeChartsCountry> get countryNotifier =>
      youtubeChartsCountryNotifier;

  Future<Map<String, dynamic>> fetchArtistDetails(
    YouTubeChartsCountry country,
  ) {
    return YouTubeChartsClient().getArtistDetails(
      artistId: artistId,
      country: country,
    );
  }

  void playTopSongs(List<dynamic> topSongs, String defaultArtistName) {
    if (topSongs.isEmpty) return;

    final songMaps = topSongs
        .map((song) => mapSong(song, defaultArtistName))
        .toList();

    audioHandler.addPlaylistToQueue(songMaps, replace: true);
  }

  Map<String, dynamic> mapSong(dynamic song, String defaultArtist) {
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

    var artistNames = defaultArtist;
    if (song['artists'] != null) {
      final artists = song['artists'] as List;
      artistNames = artists.map((a) => a['name']).join(', ');
    }

    final ytid = song['encryptedVideoId'] ?? song['id'] ?? '';
    return {
      'id': ytid,
      'ytid': ytid,
      'title': song['name'] ?? 'Unknown',
      'artist': artistNames,
      'image': highRes ?? lowRes,
      'highResImage': highRes,
      'lowResImage': lowRes,
    };
  }
}
