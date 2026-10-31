import 'youtube_explode_exception.dart';

/// Exception thrown when YouTube answers 403 to the probe of a client's
/// stream URL. Retrying the same client rarely helps, so [retry] gives up on
/// it at once and the caller can move on to another client.
class StreamForbiddenException extends YoutubeExplodeException {
  /// Initializes an instance of [StreamForbiddenException].
  StreamForbiddenException(String videoId, int tag)
      : super('Video $videoId returned 403 (stream: $tag)');
}
