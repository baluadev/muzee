import 'package:test/test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'skip_gh.dart';

/// Reproduces Home recommendations path: getRelatedVideos + lockup parsing.
void main() {
  late YoutubeExplode yt;

  setUpAll(() => yt = YoutubeExplode());
  tearDownAll(() => yt.close());

  test('related videos for SqGBAFvNTjQ (user stack trace id)', () async {
    final video = await yt.videos.get('SqGBAFvNTjQ');
    final related = await yt.videos.getRelatedVideos(video);
    expect(related, isNotNull);
    expect(related!.toList(), isNotEmpty);
  }, skip: skipGH, timeout: const Timeout(Duration(minutes: 2)));
}
