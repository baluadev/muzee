import 'package:audio_service/audio_service.dart';
import 'package:tuber_playback/tuber_playback.dart';

class FullPlayerState {
  FullPlayerState({
    required this.playbackState,
    required this.queue,
    required this.position,
  });
  final PlaybackState playbackState;
  final List<MediaItem> queue;
  final PositionData position;
}
