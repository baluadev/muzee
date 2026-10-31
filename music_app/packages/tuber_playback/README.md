# tuber_playback

Music playback shared by the Tuber apps. It started as NeoTuber's
`MusifyAudioHandler`, and NeoTuber now runs on it.

What it does:

- Queue, shuffle, repeat (off / all / one), sleep timer, autoplay of similar
  songs, as an `audio_service` handler (`TuberAudioHandler`).
- Skips songs that can't be played (removed, region-blocked, no stream),
  reports each one on `playbackErrors` so the app can tell the user, and
  stops after 3 failures in a row instead of retrying forever. Play retries
  the song that failed.
- Recovers from streams that fail after resolving (expired URL: drops the
  cache and looks the song up again; dropped network: media_kit's error).
- Plays through media_kit (`MediaPlayerAdapter`).
- Fast YouTube stream lookup (`StreamManifestResolver`): one client at a
  time, fastest first, and a client that YouTube rejects is tried last for
  30 minutes.

## Using it in an app

1. Depend on it, along with the `youtube_explode_dart` fork it builds on
   (`StreamForbiddenException`, the 403 probe):

   ```yaml
   dependencies:
     tuber_playback:
       path: ../path/to/tuber_playback
   ```

   Add `media_kit_libs_audio` (or `media_kit_libs_video`) to the app for the
   native libraries, and call `MediaKit.ensureInitialized()` before playing.

2. Implement `PlaybackHost`. It covers what depends on the app: settings
   (`ValueNotifier`s the app owns and persists), stream lookup and URL
   cache, downloaded songs, similar songs, listens and logging. NeoTuber's
   version is `NeoTuberPlaybackHost` in `lib/services/audio_service.dart`.

3. Start the handler:

   ```dart
   final handler = await AudioService.init(
     builder: () => TuberAudioHandler(host: MyPlaybackHost()),
     config: const AudioServiceConfig(
       androidNotificationChannelId: 'com.example.app.audio',
       androidNotificationChannelName: 'Playback',
     ),
   );
   handler.playbackErrors.listen((song) => showCantPlay(song['title']));
   ```

Songs are maps with at least `ytid`, `title`, `artist` and `highResImage`
(plus `lowResImage`, `isLive`, `duration` in seconds).

## Tests

`package:tuber_playback/testing.dart` has `SilentPlatformPlayer`, a media_kit
backend that plays nothing, so the handler runs in `flutter test` without
libmpv. `test/` shows how to use it with a fake host:

```sh
flutter test
```
