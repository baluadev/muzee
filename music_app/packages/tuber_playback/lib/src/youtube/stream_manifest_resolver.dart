import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tuber_playback/src/playback_host.dart';
import 'package:tuber_playback/src/youtube/clients.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// One way of asking YouTube for a video's streams.
class StreamLookup {
  const StreamLookup(this.name, this.client, {required this.watchPage});

  final String name;
  final YoutubeApiClient client;

  /// Fetch and parse the watch page first (slower, ~1 s, but some clients
  /// need its visitor data and cookies).
  final bool watchPage;

  @override
  String toString() => name;
}

/// Fastest first. Measured 2026-10: `android` resolves in ~0.4 s;
/// `android_vr` needs the watch page and its stream probe often gets 403.
const defaultStreamLookups = [
  StreamLookup('android', customAndroidSdkless, watchPage: false),
  StreamLookup('android_vr+watch', customAndroidVr, watchPage: true),
  StreamLookup('android+watch', customAndroidSdkless, watchPage: true),
];

/// Resolves stream manifests by trying [lookups] one at a time and stopping
/// at the first that works. (youtube_explode's own multi-client getManifest
/// keeps querying the remaining clients after one has succeeded.)
///
/// A lookup that YouTube rejected is moved to the end of the order for
/// [cooldown], so songs don't keep paying for it. Network failures and rate
/// limiting stop the search at once: every other lookup would fail the same
/// way, only slower.
class StreamManifestResolver {
  StreamManifestResolver(
    this._youtube, {
    this.lookups = defaultStreamLookups,
    this.cooldown = const Duration(minutes: 30),
    this.lookupTimeout = const Duration(seconds: 15),
    DateTime Function()? now,
    PlaybackLog? log,
  }) : _now = now ?? DateTime.now,
       _log = log ?? _noLog;

  final YoutubeExplode Function() _youtube;
  final List<StreamLookup> lookups;
  final Duration cooldown;
  final Duration lookupTimeout;
  final DateTime Function() _now;
  final PlaybackLog _log;
  final Map<String, DateTime> _rejectedAt = {};

  /// Forgets which lookups YouTube rejected recently.
  void clearRejections() => _rejectedAt.clear();

  /// [lookups] in the order the next resolve will try them.
  List<StreamLookup> get order {
    final now = _now();
    bool cooling(StreamLookup l) {
      final at = _rejectedAt[l.name];
      return at != null && now.difference(at) < cooldown;
    }

    return [...lookups.where((l) => !cooling(l)), ...lookups.where(cooling)];
  }

  Future<({StreamManifest manifest, StreamLookup lookup})> resolve(
    String videoId,
  ) async {
    Object? lastError;
    for (final lookup in order) {
      try {
        final manifest = await _youtube().videos.streams
            .getManifest(
              videoId,
              ytClients: [lookup.client],
              requireWatchPage: lookup.watchPage,
            )
            .timeout(lookupTimeout);
        _rejectedAt.remove(lookup.name);
        return (manifest: manifest, lookup: lookup);
      } on http.ClientException {
        rethrow;
      } on SocketException {
        rethrow;
      } on TimeoutException {
        rethrow;
      } on RequestLimitExceededException {
        // Rate limiting applies to the whole connection, not one client.
        rethrow;
      } catch (e) {
        _rejectedAt[lookup.name] = _now();
        lastError = e;
        _log('Stream lookup "$lookup" failed for $videoId', error: e);
      }
    }
    throw lastError ??
        VideoUnavailableException('No stream lookup configured for $videoId');
  }
}

void _noLog(String message, {Object? error, StackTrace? stackTrace}) {}
