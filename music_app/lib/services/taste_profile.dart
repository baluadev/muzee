import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// An artist name reduced to a comparable key: lower case, no spaces (VEVO
/// channels run the name together: "LukeCombsVEVO"), without channel
/// suffixes ("HozierVEVO", "Joy Crookes - Topic") or "Official".
String artistKey(String name) {
  var key = name.trim();
  key = key.replaceAll(RegExp(r'\s*-\s*topic$', caseSensitive: false), '');
  key = key.replaceAll(RegExp(r'vevo$', caseSensitive: false), '');
  key = key.replaceAll(RegExp(r'\bofficial\b', caseSensitive: false), '');
  return key.replaceAll(RegExp(r'\s+'), '').toLowerCase();
}

/// Every artist in [raw] ("Đen, MIN", "Chủ Tịch Mai x Giám Đốc Hà",
/// "Hozier feat. Mavis Staples") as [artistKey]s.
List<String> artistKeys(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(
        RegExp(r',|&|\s+x\s+|\s+feat\.?\s+|\s+ft\.?\s+', caseSensitive: false),
      )
      .map(artistKey)
      .where((k) => k.isNotEmpty)
      .toList();
}

/// How a play ended, judged from how far it got.
enum PlayOutcome {
  /// Listened to the end, or most of the way.
  finished,

  /// Left within the first seconds.
  skipped,

  /// Somewhere in between: says little either way.
  partial;

  static PlayOutcome of({
    required Duration position,
    required Duration? duration,
    required bool completed,
  }) {
    final length = duration ?? Duration.zero;
    if (completed ||
        (length > Duration.zero && position >= length * finishedShare)) {
      return finished;
    }
    if (position < skipWithin &&
        (length <= Duration.zero || position < length * skipShare)) {
      return skipped;
    }
    return partial;
  }

  static const finishedShare = 0.7;
  static const skipShare = 0.4;
  static const skipWithin = Duration(seconds: 30);
}

/// What the listener likes, learned on this device from how songs end, the
/// liked songs and listening counts, plus (when signed in) the artists of
/// their YouTube likes and their YouTube subscriptions.
///
/// It only reorders suggestions; nothing leaves the phone. Listening signals
/// are kept with the user's data (and so in their backups); the YouTube part
/// is a cache, refreshed from YouTube and never backed up.
class TasteProfile {
  TasteProfile({
    required Box userBox,
    required Box deviceBox,
    required List Function() likedSongs,
    required List Function() recentSongs,
  }) : _userBox = userBox,
       _deviceBox = deviceBox,
       _likedSongs = likedSongs,
       _recentSongs = recentSongs;

  final Box _userBox;
  final Box _deviceBox;
  final List Function() _likedSongs;
  final List Function() _recentSongs;

  static const _signalsKey = 'tasteSignals';
  static const youTubeKey = 'youtubeTaste';

  /// Caps on what is kept, so the stored profile stays small.
  static const _maxArtists = 1000;
  static const _maxSkippedSongs = 500;

  /// Records how a play of [song] ended.
  Future<void> recordPlayEnd(
    Map song, {
    required Duration position,
    required Duration? duration,
    required bool completed,
  }) async {
    final outcome = PlayOutcome.of(
      position: position,
      duration: duration,
      completed: completed,
    );
    if (outcome == PlayOutcome.partial) return;

    final signals = _signals();
    final artists = Map<String, dynamic>.from(signals['artists'] as Map);
    final skips = Map<String, dynamic>.from(signals['skips'] as Map);
    for (final key in artistKeys(song['artist']?.toString())) {
      final counts = List<int>.from((artists.remove(key) as List?) ?? [0, 0]);
      counts[outcome == PlayOutcome.finished ? 0 : 1]++;
      artists[key] = counts; // re-inserted last: most recent
    }
    final ytid = song['ytid']?.toString();
    if (ytid != null && outcome == PlayOutcome.skipped) {
      final n = (skips.remove(ytid) as int? ?? 0) + 1;
      skips[ytid] = n;
    }
    _trim(artists, _maxArtists);
    _trim(skips, _maxSkippedSongs);
    await _userBox.put(_signalsKey, {'artists': artists, 'skips': skips});
  }

  /// Stores what YouTube says about the signed-in listener.
  Future<void> setYouTubeTaste({
    required Map<String, int> likedArtists,
    required List<String> subscriptions,
    required DateTime syncedAt,
  }) => _deviceBox.put(youTubeKey, {
    'syncedAt': syncedAt.toIso8601String(),
    'likedArtists': likedArtists,
    'subscriptions': subscriptions,
  });

  Future<void> clearYouTubeTaste() => _deviceBox.delete(youTubeKey);

  /// When YouTube was last read, or null.
  DateTime? get youTubeSyncedAt {
    final data = _deviceBox.get(youTubeKey);
    return data is Map ? DateTime.tryParse('${data['syncedAt']}') : null;
  }

  /// The profile as it is now, ready to score many songs.
  TasteSnapshot snapshot({bool includeYouTube = true}) {
    final positive = <String, double>{};
    final negative = <String, double>{};
    void add(Map<String, double> map, String? artist, double weight) {
      for (final key in artistKeys(artist)) {
        map[key] = (map[key] ?? 0) + weight;
      }
    }

    final signals = _signals();
    (signals['artists'] as Map).forEach((key, counts) {
      if (counts is List && counts.length == 2) {
        positive[key] = (positive[key] ?? 0) + (counts[0] as num);
        negative[key] = (negative[key] ?? 0) + (counts[1] as num);
      }
    });
    for (final song in _likedSongs()) {
      if (song is Map) add(positive, song['artist']?.toString(), 2);
    }
    for (final song in _recentSongs()) {
      if (song is Map) {
        final count = (song['listeningCount'] as num?) ?? 1;
        add(positive, song['artist']?.toString(), 0.5 * min(count, 5));
      }
    }
    final youTube = includeYouTube ? _deviceBox.get(youTubeKey) : null;
    if (youTube is Map) {
      (youTube['likedArtists'] as Map? ?? {}).forEach((key, count) {
        positive['$key'] = (positive['$key'] ?? 0) + 2 * (count as num);
      });
      for (final key in (youTube['subscriptions'] as List? ?? [])) {
        positive['$key'] = (positive['$key'] ?? 0) + 3;
      }
    }

    final skips = <String, int>{
      for (final e in (signals['skips'] as Map).entries)
        '${e.key}': (e.value as num).toInt(),
    };
    return TasteSnapshot._(positive, negative, skips);
  }

  Map _signals() {
    final stored = _userBox.get(_signalsKey);
    if (stored is Map && stored['artists'] is Map && stored['skips'] is Map) {
      return stored;
    }
    return {'artists': {}, 'skips': {}};
  }

  /// Drops the oldest entries (insertion order) beyond [max].
  static void _trim(Map map, int max) {
    while (map.length > max) {
      map.remove(map.keys.first);
    }
  }
}

/// A frozen [TasteProfile] that scores candidate songs.
class TasteSnapshot {
  TasteSnapshot._(this._positive, this._negative, this._skips);

  /// A profile with fixed artist weights (by [artistKey]) and skip counts.
  @visibleForTesting
  factory TasteSnapshot.test({
    Map<String, double> liked = const {},
    Map<String, double> skippedArtists = const {},
    Map<String, int> skippedSongs = const {},
  }) => TasteSnapshot._(liked, skippedArtists, skippedSongs);

  final Map<String, double> _positive;
  final Map<String, double> _negative;
  final Map<String, int> _skips;

  /// An empty profile: every song scores 0.
  static final empty = TasteSnapshot._({}, {}, {});

  /// How much the listener should like a song: above 0 for artists they
  /// play, like or follow, below 0 for ones they skip and for songs they
  /// skipped before. Diminishing returns, so one huge artist doesn't
  /// drown out everything else.
  double score({required String ytid, required Iterable<String?> artists}) {
    double? best;
    for (final key in artists.expand(artistKeys)) {
      final value =
          log(1 + (_positive[key] ?? 0)) - 1.2 * log(1 + (_negative[key] ?? 0));
      if (best == null || value > best) best = value;
    }
    final songSkips = min(_skips[ytid] ?? 0, 3);
    return (best ?? 0) - 1.5 * songSkips;
  }
}
