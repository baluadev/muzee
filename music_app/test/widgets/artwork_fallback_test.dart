// Old YouTube videos have no maxres (or sd) thumbnail: artwork steps down
// to the next size instead of showing the placeholder.

import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/widgets/muzee_artwork.dart';

void main() {
  const base = 'https://i.ytimg.com/vi/2ZBtPf7FOoM';

  test('steps down maxres → sd → hq → mq, then stops', () {
    expect(
      smallerYouTubeThumbnail('$base/maxresdefault.jpg'),
      '$base/sddefault.jpg',
    );
    expect(
      smallerYouTubeThumbnail('$base/sddefault.jpg'),
      '$base/hqdefault.jpg',
    );
    expect(
      smallerYouTubeThumbnail('$base/hqdefault.jpg'),
      '$base/mqdefault.jpg',
    );
    expect(smallerYouTubeThumbnail('$base/mqdefault.jpg'), isNull);
  });

  test('leaves other images alone', () {
    expect(smallerYouTubeThumbnail('https://img.test/cover.jpg'), isNull);
    expect(smallerYouTubeThumbnail('$base/default.jpg'), isNull);
    expect(smallerYouTubeThumbnail(null), isNull);
  });

  test('works for img.youtube.com (what search results use)', () {
    expect(
      smallerYouTubeThumbnail(
        'https://img.youtube.com/vi/abc/maxresdefault.jpg',
      ),
      'https://img.youtube.com/vi/abc/sddefault.jpg',
    );
  });

  test('works for the numbered and webp hosts too', () {
    expect(
      smallerYouTubeThumbnail(
        'https://i9.ytimg.com/vi_webp/abc/maxresdefault.webp',
      ),
      'https://i9.ytimg.com/vi_webp/abc/sddefault.webp',
    );
  });
}
