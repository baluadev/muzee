import 'dart:convert';

import 'package:http/http.dart' as http;

/// A minimal client for YouTube Music's InnerTube API (the one its web app
/// uses). Unofficial: no key, no guarantees, so callers treat every failure
/// as "no answer".
class YouTubeMusicApi {
  YouTubeMusicApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const timeout = Duration(seconds: 10);

  /// The web client the requests present themselves as.
  static const _context = {
    'client': {'clientName': 'WEB_REMIX', 'clientVersion': '1.20241023.01.00'},
  };

  /// POSTs [body] to `youtubei/v1/[endpoint]` and returns the decoded JSON.
  /// Throws on a network error or a non-200 answer.
  Future<Object?> post(String endpoint, Map<String, Object> body) async {
    final response = await _client
        .post(
          Uri.https('music.youtube.com', '/youtubei/v1/$endpoint', {
            'prettyPrint': 'false',
          }),
          headers: const {
            'Content-Type': 'application/json',
            'Origin': 'https://music.youtube.com',
            'User-Agent': 'Mozilla/5.0',
          },
          body: jsonEncode({'context': _context, ...body}),
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('$endpoint: ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// Every value stored under [key], anywhere in [node].
  static Iterable<Object?> findAll(Object? node, String key) sync* {
    if (node is Map) {
      if (node.containsKey(key)) yield node[key];
      for (final value in node.values) {
        yield* findAll(value, key);
      }
    } else if (node is List) {
      for (final value in node) {
        yield* findAll(value, key);
      }
    }
  }

  /// The value at [keys] under [node], or null.
  static Object? path(Object? node, List<String> keys) {
    var current = node;
    for (final key in keys) {
      if (current is! Map) return null;
      current = current[key];
    }
    return current;
  }

  /// The text of a `{runs: [{text}]}` node.
  static String? runsText(Object? node) {
    final runs = node is Map ? node['runs'] : null;
    if (runs is! List) return null;
    return runs.map((r) => r is Map ? r['text'] ?? '' : '').join();
  }
}
