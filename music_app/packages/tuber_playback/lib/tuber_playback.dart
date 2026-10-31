/// Music playback shared by the Tuber apps.
///
/// An app implements `PlaybackHost` (settings, stream lookup and cache,
/// offline library, recommendations) and runs a `TuberAudioHandler` with it:
///
/// ```dart
/// final handler = await AudioService.init(
///   builder: () => TuberAudioHandler(host: MyPlaybackHost()),
///   config: const AudioServiceConfig(androidNotificationChannelId: '...'),
/// );
/// ```
library;

export 'src/engine/media_player_adapter.dart';
export 'src/handler/tuber_audio_handler.dart';
export 'src/media_item_mapping.dart';
export 'src/playback_host.dart';
export 'src/position_data.dart';
export 'src/queue/queue_entry_id_manager.dart';
export 'src/stream_playback_info.dart';
export 'src/utils/map_utils.dart';
export 'src/youtube/clients.dart';
export 'src/youtube/stream_manifest_resolver.dart';
