import 'package:audio_service/audio_service.dart';

/// The song map the handler queues, rebuilt from a [MediaItem].
Map mediaItemToMap(MediaItem mediaItem) {
  final extras = mediaItem.extras;
  return {
    'id': mediaItem.id,
    'ytid': extras?['ytid'],
    'album': mediaItem.album.toString(),
    'artist': mediaItem.artist.toString(),
    'title': mediaItem.title,
    'highResImage': extras?['highResImage'] ?? mediaItem.artUri.toString(),
    'lowResImage': extras?['lowResImage'],
    'isLive': extras?['isLive'] ?? false,
    'isVideo': extras?['isVideo'] ?? false,
    'videoSource': extras?['videoSource'],
  };
}

/// [song] as a [MediaItem]. When [offlineSong] (the downloaded copy, see
/// `PlaybackHost.offlineSong`) has artwork, that is used instead of the
/// remote image.
MediaItem mapToMediaItem(
  Map song, {
  Map<String, dynamic> offlineSong = const {},
}) {
  final isOffline = offlineSong.isNotEmpty;

  final artUri = isOffline && offlineSong['artworkPath'] != null
      ? Uri.file(offlineSong['artworkPath'].toString())
      : Uri.parse(song['highResImage'].toString());

  return MediaItem(
    id: song['id'].toString(),
    artist: song['artist'].toString().trim(),
    title: song['title'].toString(),
    artUri: artUri,
    duration: song['duration'] != null
        ? Duration(seconds: song['duration'])
        : null,
    extras: {
      'lowResImage': song['lowResImage'],
      'ytid': song['ytid'],
      'isLive': song['isLive'],
      'highResImage': song['highResImage'],
      'isVideo': song['isVideo'] ?? false,
      'videoSource': song['videoSource'],
      'artWorkPath':
          (isOffline ? offlineSong['artworkPath'] : song['highResImage'])
              ?.toString() ??
          '',
    },
  );
}

/// Compares two Duration objects with tolerance for minor differences.
///
/// This prevents unnecessary updates when duration values have minor variations
/// (e.g., due to buffering or precision differences).
bool durationEquals(Duration? prev, Duration? curr) {
  if (prev == curr) return true;
  if (prev == null || curr == null) return prev == curr;

  // Consider durations equal if they differ by less than 1 second
  return (prev - curr).abs() < const Duration(seconds: 1);
}
