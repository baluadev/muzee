import 'dart:convert';

import 'package:muzee/main.dart';
import 'package:muzee/services/proxy_manager.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/utilities/formatter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistSharingService {
  static Map createCompactPlaylist(Map fullPlaylist) {
    return {
      'title': fullPlaylist['title'],
      if (fullPlaylist['image'] != null) 'image': fullPlaylist['image'],
      'source': 'user-created',
      'list': fullPlaylist['list'].map((song) => song['ytid']).toList(),
    };
  }

  static Future<Map> expandCompactPlaylist(Map compactPlaylist) async {
    final List<dynamic> songIds = compactPlaylist['list'];
    YoutubeExplode? ytClient;
    try {
      if (useProxy.value) {
        ytClient = await ProxyManager().getYoutubeExplodeClient();
      } else {
        ytClient = ProxyManager().getClientSync();
      }

      final expandedSongs = await Future.wait(
        songIds.map((ytid) async {
          try {
            final video = await ytClient!.videos.get(ytid);
            return returnSongLayout(songIds.indexOf(ytid), video);
          } catch (e, stackTrace) {
            logger.log(
              'Error expanding song: $ytid',
              error: e,
              stackTrace: stackTrace,
            );
            return null;
          }
        }),
      );

      return {
        ...compactPlaylist,
        'list': expandedSongs.where((song) => song != null).toList(),
      };
    } finally {
      try {
        if (useProxy.value) {
          ytClient?.close();
        }
      } catch (_) {}
    }
  }

  static String encodePlaylist(Map playlist) {
    final compactPlaylist = createCompactPlaylist(playlist);
    return base64Url.encode(utf8.encode(json.encode(compactPlaylist)));
  }

  static Future<Map?> decodeAndExpandPlaylist(String encodedPlaylist) async {
    try {
      final jsonString = utf8.decode(base64Url.decode(encodedPlaylist));
      final compactPlaylist = json.decode(jsonString) as Map;
      return await expandCompactPlaylist(compactPlaylist);
    } catch (e, stackTrace) {
      logger.log('Failed to decode playlist', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
