import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:muzee/main.dart' show logger;
import 'package:muzee/services/common_services.dart' show tasteProfile;
import 'package:muzee/services/google_account_service.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/services/taste_profile.dart';

/// Reads the signed-in listener's YouTube likes and subscriptions (YouTube
/// Data API, read-only scope) into their [TasteProfile].
///
/// Only artist names are kept: the channels of liked music videos and of
/// subscriptions. YouTube's API does not give watch history or YouTube's own
/// recommendations, so this is all it can tell about taste.
class YouTubeTasteSync {
  YouTubeTasteSync({
    required TasteProfile profile,
    required Future<String?> Function() accessToken,
    http.Client? client,
  }) : _profile = profile,
       _accessToken = accessToken,
       _client = client ?? http.Client();

  final TasteProfile _profile;
  final Future<String?> Function() _accessToken;
  final http.Client _client;

  /// Read YouTube again after this long.
  static const staleAfter = Duration(hours: 12);

  /// Pages of 50 read per list: the most recent 200 likes and
  /// subscriptions, 8 quota units at most.
  static const maxPages = 4;

  /// YouTube's "Music" video category.
  static const _musicCategory = '10';

  bool _running = false;

  bool get isStale {
    final synced = _profile.youTubeSyncedAt;
    return synced == null || DateTime.now().difference(synced) > staleAfter;
  }

  /// Reads YouTube when the stored copy is stale (or [force]). Returns
  /// whether it read it.
  Future<bool> sync({bool force = false}) async {
    if (_running || (!force && !isStale)) return false;
    _running = true;
    try {
      final token = await _accessToken();
      if (token == null) return false;

      final likedArtists = <String, int>{};
      await _pages(token, 'videos', {'part': 'snippet', 'myRating': 'like'}, (
        item,
      ) {
        final snippet = item['snippet'];
        if (snippet is! Map || snippet['categoryId'] != _musicCategory) return;
        for (final key in artistKeys(snippet['channelTitle']?.toString())) {
          likedArtists[key] = (likedArtists[key] ?? 0) + 1;
        }
      });

      final subscriptions = <String>{};
      await _pages(
        token,
        'subscriptions',
        {'part': 'snippet', 'mine': 'true'},
        (item) {
          final title = (item['snippet'] as Map?)?['title']?.toString();
          subscriptions.addAll(artistKeys(title));
        },
      );

      await _profile.setYouTubeTaste(
        likedArtists: likedArtists,
        subscriptions: subscriptions.toList(),
        syncedAt: DateTime.now(),
      );
      return true;
    } catch (e, stackTrace) {
      logger.log(
        'Reading YouTube taste failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      _running = false;
    }
  }

  Future<void> clear() => _profile.clearYouTubeTaste();

  /// Reads up to [maxPages] pages of `youtube/v3/[resource]`, passing each
  /// item to [onItem]. Throws on an API error (e.g. the scope wasn't granted).
  Future<void> _pages(
    String token,
    String resource,
    Map<String, String> query,
    void Function(Map item) onItem,
  ) async {
    String? pageToken;
    for (var page = 0; page < maxPages; page++) {
      final response = await _client
          .get(
            Uri.https('www.googleapis.com', '/youtube/v3/$resource', {
              ...query,
              'maxResults': '50',
              'pageToken': ?pageToken,
            }),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw http.ClientException(
          '$resource: ${response.statusCode} ${response.body}',
        );
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (final item in (json['items'] as List? ?? [])) {
        if (item is Map) onItem(item);
      }
      pageToken = json['nextPageToken'] as String?;
      if (pageToken == null) break;
    }
  }
}

final youTubeTasteSync = YouTubeTasteSync(
  profile: tasteProfile,
  accessToken: GoogleAccountService.instance.freshAccessToken,
);

/// Keeps the YouTube part of the taste profile in step with sign-in and the
/// "personalise with YouTube" setting: read on sign-in (when stale), dropped
/// on sign-out or when the setting is turned off.
void attachYouTubeTasteSync() {
  final accounts = GoogleAccountService.instance;
  void update() {
    if (accounts.account.value != null && personalizeWithYouTube.value) {
      unawaited(youTubeTasteSync.sync());
    } else {
      unawaited(youTubeTasteSync.clear());
    }
  }

  accounts.account.addListener(update);
  personalizeWithYouTube.addListener(update);
}
