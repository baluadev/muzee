/// A stream URL the player can open.
class StreamPlaybackInfo {
  const StreamPlaybackInfo({
    required this.url,
    required this.isVideo,
    required this.cacheKey,
  });

  final String url;

  /// A muxed (audio + video) stream rather than audio only.
  final bool isVideo;

  /// Where the app caches [url]; see [cacheKeyFor].
  final String cacheKey;

  /// Cache key for a song's stream URL: muxed and audio-only URLs are cached
  /// separately.
  static String cacheKeyFor(String ytid, {required bool isVideo}) =>
      isVideo ? 'song_${ytid}_muxed_low_url' : 'song_${ytid}_audio_url';
}
