// The notification's artwork is a thumbnail every YouTube video has.

import 'package:flutter_test/flutter_test.dart';
import 'package:tuber_playback/tuber_playback.dart';

void main() {
  test('maxres and sd YouTube thumbnails become hqdefault', () {
    expect(
      notificationArtwork('https://img.youtube.com/vi/abc/maxresdefault.jpg'),
      'https://img.youtube.com/vi/abc/hqdefault.jpg',
    );
    expect(
      notificationArtwork('https://i.ytimg.com/vi_webp/abc/sddefault.webp'),
      'https://i.ytimg.com/vi_webp/abc/hqdefault.webp',
    );
  });

  test('other artwork is kept', () {
    const cover = 'https://lh3.googleusercontent.com/cover=w544';
    expect(notificationArtwork(cover), cover);
    expect(
      notificationArtwork('https://img.youtube.com/vi/abc/hqdefault.jpg'),
      'https://img.youtube.com/vi/abc/hqdefault.jpg',
    );
  });

  test('the media item uses it; the full-size one stays in extras', () {
    final item = mapToMediaItem({
      'id': 1,
      'ytid': 'abc',
      'title': 'Song',
      'artist': 'Artist',
      'highResImage': 'https://img.youtube.com/vi/abc/maxresdefault.jpg',
    });
    expect(item.artUri.toString(), contains('hqdefault'));
    expect(item.extras!['highResImage'], contains('maxresdefault'));
  });
}
