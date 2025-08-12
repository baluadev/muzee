import 'package:flutter/material.dart';
import 'package:muzee/models/song_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YtHelper {
  static String formatDuration(Duration? duration) {
    if (duration == null) {
      return '00:00:00';
    }

    String twoDigits(int n) {
      if (n >= 10) {
        return '$n';
      }
      return '0$n';
    }

    final twoDigitHours = twoDigits(duration.inHours);
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours <= 0) {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }

    return '$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds';
  }

  static int parseYoutubeDurationToMs(String? duration) {
    var duration0 = duration;

    try {
      if (duration0 == null || duration0.isEmpty) {
        return 0;
      }

      duration0 = duration0.toLowerCase().trim();

      var ms = 0;

      if (duration0.contains('h') && duration0.contains('m')) {
        final hour = int.tryParse(_getDataFromAToB(duration0, 'pt', 'h'));
        final minute = int.tryParse(_getDataFromAToB(duration0, 'h', 'm'));

        if (duration0.contains('s')) {
          final second = int.tryParse(_getDataFromAToB(duration0, 'm', 's'));
          ms += second!;
        }

        ms += hour! * 3600 + minute! * 60;
        ms *= 1000;
      } else if (duration0.contains('h') && !duration0.contains('m')) {
        final hour = int.tryParse(_getDataFromAToB(duration0, 'pt', 'h'));

        if (duration0.contains('s')) {
          final second = int.tryParse(_getDataFromAToB(duration0, 'h', 's'));
          ms += second!;
        }

        ms += hour! * 3600;
        ms *= 1000;
      } else if (!duration0.contains('h') && duration0.contains('m')) {
        final minute = int.tryParse(_getDataFromAToB(duration0, 'pt', 'm'));

        if (duration0.contains('s')) {
          final second = int.tryParse(_getDataFromAToB(duration0, 'm', 's'));
          ms += second!;
        }

        ms += minute! * 60;
        ms *= 1000;
      } else if (duration0.contains('s')) {
        final second = int.tryParse(_getDataFromAToB(duration0, 'pt', 's'));
        ms += second!;
        ms *= 1000;
      }

      return ms;
    } catch (e, stackTrace) {
      debugPrint('$e - $stackTrace');
      return 0;
    }
  }

  static String _getDataFromAToB(String source, String matchA, String matchB) {
    var startIndex = source.indexOf(matchA);
    final endIndex = source.indexOf(matchB);

    if (startIndex != -1 && endIndex != -1) {
      startIndex += matchA.length;
      return source.substring(startIndex, endIndex);
    }

    return '';
  }

  static String parseMsToString(int? duration) {
    var duration0 = duration;
    try {
      if (duration0 == null || duration0 == 0) {
        return '00:00';
      } else {
        var format = '';
        final hour = (duration0 / 3600000).floor();

        if (hour > 0) {
          format = '${_addZeroIfNeed(hour)}:';
          duration0 -= hour * 3600000;
        }

        final minute = (duration0 / 60000).floor();
        duration0 -= minute * 60000;

        format += '${_addZeroIfNeed(minute)}:';

        final second = (duration0 / 1000).floor();

        return format += _addZeroIfNeed(second);
      }
    } catch (e, stackTrace) {
      debugPrint('$e - $stackTrace');
      return '00:00';
    }
  }

  static String _addZeroIfNeed(int? data) {
    if (data == null) {
      return '00';
    } else if (data < 10) {
      return '0$data';
    }
    return '$data';
  }

  static SongModel? videoToSong(Video? video) {
    if (video is Video) {
      return SongModel(
        songId: video.id.value,
        thumbnailUrl: video.thumbnails.highResUrl,
        artist: video.author,
        title: video.title,
        duration: video.duration?.inMilliseconds,
      );
    }

    return null;
  }

  // static PlaylistModel parsePlaylist(Playlist? playlist, List<Video>? videos) {
  //   if (playlist == null) {
  //     return PlaylistModel();
  //   }

  //   final songs = videos?.map(videoToMusic).toList();

  //   return PlaylistModel(
  //     playlistId: playlist.id.value,
  //     title: playlist.title,
  //     thumb: playlist.thumbnails.highResUrl,
  //     videoCount: songs?.length ?? 0,
  //     songs: songs,
  //   );
  // }

  static String getIdPlaylistFromUrl(String url) {
    if (url.isEmpty) {
      return '';
    }
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['list'] ?? '';
    } catch (e) {
      return '';
    }
  }
}
