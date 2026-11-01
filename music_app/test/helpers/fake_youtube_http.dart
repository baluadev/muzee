// Test-only fake of the network layer underneath youtube_explode_dart.
//
// The app talks to YouTube through the global `ytClient`
// (lib/services/youtube_client.dart), which is created lazily with a plain
// `http.Client()` -> dart:io `HttpClient()`. Installing [FakeYouTubeHttp] as
// `HttpOverrides.global` before the first request therefore routes every
// YouTube call through [FakeYouTubeHttp.responder] without touching lib/.
//
// Keep a single instance per test file: `ytClient` binds to the HttpClient
// created on first use, so swap [FakeYouTubeHttp.responder] between tests
// instead of installing a new override.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// What the fake network should do with one request.
class FakeReply {
  const FakeReply._({
    this.statusCode = 200,
    this.body = '',
    this.headers = const {},
    this.socketError = false,
    this.hang = false,
  });

  factory FakeReply.ok(String body, {Map<String, String> headers = const {}}) =>
      FakeReply._(body: body, headers: headers);

  factory FakeReply.status(int statusCode, [String body = '']) =>
      FakeReply._(statusCode: statusCode, body: body);

  /// The connection fails, like airplane mode or a DNS failure.
  const factory FakeReply.socketError() = _SocketErrorReply;

  /// The server never answers.
  const factory FakeReply.hang() = _HangReply;

  final int statusCode;
  final String body;
  final Map<String, String> headers;
  final bool socketError;
  final bool hang;
}

class _SocketErrorReply extends FakeReply {
  const _SocketErrorReply() : super._(socketError: true);
}

class _HangReply extends FakeReply {
  const _HangReply() : super._(hang: true);
}

/// One request seen by the fake network.
class FakeRequest {
  FakeRequest(this.method, this.url, this.body);

  final String method;
  final Uri url;
  final String body;

  /// The `videoId` sent to the InnerTube player endpoint, if any.
  String? get playerVideoId {
    if (!url.path.endsWith('/youtubei/v1/player')) return null;
    try {
      return (jsonDecode(body) as Map)['videoId'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// InnerTube client (e.g. `ANDROID`, `ANDROID_VR`) of a player request.
  String? get playerClientName {
    if (playerVideoId == null) return null;
    try {
      final context = (jsonDecode(body) as Map)['context'] as Map;
      return (context['client'] as Map)['clientName'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => '$method $url';
}

typedef FakeResponder = FakeReply Function(FakeRequest request);

class FakeYouTubeHttp extends HttpOverrides {
  FakeYouTubeHttp({FakeResponder? responder})
    : responder = responder ?? ((_) => const FakeReply.socketError());

  FakeResponder responder;
  final List<FakeRequest> requests = [];

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FakeHttpClient(this);
}

// ---------------------------------------------------------------------------
// YouTube fixtures

/// Minimal watch page that youtube_explode accepts (`#player`, `og:url`,
/// `ytcfg`). With [available] false the `og:url` meta is missing, which is
/// how youtube_explode detects a removed/private video.
String watchPageHtml(String videoId, {bool available = true}) =>
    '<html><head>'
    '${available ? '<meta property="og:url" content="https://www.youtube.com/watch?v=$videoId">' : ''}'
    '</head><body><div id="player"></div>'
    '<script>ytcfg.set({"INNERTUBE_CONTEXT":{"client":{"visitorData":"vd"}},"STS":20000});</script>'
    '</body></html>';

FakeReply watchPageReply(String videoId, {bool available = true}) =>
    FakeReply.ok(
      watchPageHtml(videoId, available: available),
      headers: {'set-cookie': 'YSC=test; path=/; VISITOR_INFO1_LIVE=test;'},
    );

/// InnerTube player response for a video that can't be played.
FakeReply playerUnplayableReply(String status, String reason) => FakeReply.ok(
  jsonEncode({
    'playabilityStatus': {'status': status, 'reason': reason},
  }),
);

/// InnerTube player response with one muxed (audio+video) stream at [url]
/// (default [streamUrlFor]).
FakeReply playerOkReply(String videoId, {String? url}) => FakeReply.ok(
  jsonEncode({
    'playabilityStatus': {'status': 'OK'},
    'videoDetails': {'videoId': videoId, 'title': 'Song $videoId'},
    'streamingData': {
      'formats': [
        {
          'itag': 18,
          'url': url ?? streamUrlFor(videoId),
          'mimeType': 'video/mp4; codecs="avc1.42001E, mp4a.40.2"',
          'bitrate': 500000,
          'width': 640,
          'height': 360,
          'contentLength': '123456',
          'qualityLabel': '360p',
          'fps': 30,
        },
      ],
    },
  }),
);

String streamUrlFor(String videoId) =>
    'https://rr1---sn-test.googlevideo.com/videoplayback?id=$videoId&itag=18';

/// Routes requests the way YouTube would answer for a set of videos.
///
/// [player] decides the InnerTube player response per video id. Ids in
/// [removed] get YouTube's "Video unavailable" answer from both the watch page
/// (no `og:url`) and the player endpoint. googlevideo HEAD/GET probes return
/// 200. Anything else (charts, related videos, metadata lookups) gets
/// [fallback].
FakeResponder youtubeResponder({
  required FakeReply Function(String videoId) player,
  Set<String> removed = const {},
  FakeReply fallback = const FakeReply.socketError(),
}) {
  return (request) {
    final url = request.url;
    if (url.host == 'www.youtube.com' && url.path == '/watch') {
      final id = url.queryParameters['v'] ?? '';
      return watchPageReply(id, available: !removed.contains(id));
    }
    final playerId = request.playerVideoId;
    if (playerId != null) {
      return removed.contains(playerId)
          ? playerUnplayableReply('ERROR', 'Video unavailable')
          : player(playerId);
    }
    if (url.host.endsWith('googlevideo.com')) return FakeReply.ok('');
    return fallback;
  };
}

// ---------------------------------------------------------------------------
// dart:io fakes

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this._owner);

  final FakeYouTubeHttp _owner;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest(_owner, method, url);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this._owner, this.method, this.uri);

  final FakeYouTubeHttp _owner;
  final List<int> _body = [];
  Future<HttpClientResponse>? _response;

  @override
  final String method;

  @override
  final Uri uri;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      stream.forEach(_body.addAll);

  @override
  void add(List<int> data) => _body.addAll(data);

  @override
  Future<HttpClientResponse> close() => _response ??= _respond();

  @override
  Future<HttpClientResponse> get done => close();

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  Future<HttpClientResponse> _respond() {
    final request = FakeRequest(method, uri, utf8.decode(_body));
    _owner.requests.add(request);
    final reply = _owner.responder(request);
    if (reply.hang) return Completer<HttpClientResponse>().future;
    if (reply.socketError) {
      return Future.error(
        SocketException(
          'Failed host lookup: ${uri.host}',
          osError: const OSError('No address', 8),
        ),
      );
    }
    return Future.value(_FakeHttpClientResponse(reply));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(this._reply) : _bytes = utf8.encode(_reply.body) {
    _reply.headers.forEach(headers.set);
    headers.set('content-type', 'text/html; charset=utf-8');
  }

  final FakeReply _reply;
  final List<int> _bytes;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  int get statusCode => _reply.statusCode;

  @override
  String get reasonPhrase => statusCode == 200 ? 'OK' : 'Error';

  @override
  int get contentLength => _bytes.length;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.fromIterable([_bytes]).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = ['$value'];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    (_values[name.toLowerCase()] ??= []).add('$value');
  }

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  String? value(String name) => _values[name.toLowerCase()]?.join(',');

  @override
  void forEach(void Function(String name, List<String> values) action) =>
      _values.forEach(action);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
