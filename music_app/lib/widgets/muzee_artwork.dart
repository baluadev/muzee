import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';

/// Retries artwork that failed to load (typically while offline).
abstract final class ArtworkRetry {
  /// Bumped when failed images should try again: the app came back to the
  /// foreground. Every [MuzeeArtwork] that failed reloads.
  static final generation = ValueNotifier<int>(0);

  static void retryFailed() => generation.value++;

  static bool _installed = false;

  /// Retries failed artwork whenever the app is resumed. Call once at startup.
  static void install() {
    if (_installed) return;
    _installed = true;
    WidgetsBinding.instance.addObserver(_ResumeObserver());
  }
}

class _ResumeObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ArtworkRetry.retryFailed();
  }
}

/// Network artwork with a placeholder, a music-note fallback, and retries:
/// a failed image tries again after 5 s, 15 s and 60 s, and whenever the
/// app is resumed. One loader for every cover in the app.
/// YouTube thumbnail sizes, best first.
const _youTubeThumbnailSizes = [
  'maxresdefault',
  'sddefault',
  'hqdefault',
  'mqdefault',
];
final _youTubeThumbnail = RegExp(
  r'^(https?://(?:i\d?\.ytimg\.com|img\.youtube\.com)/vi(?:_webp)?/[^/]+/)(\w+)(\.\w+)$',
);

/// The next smaller thumbnail of the same YouTube video as [url], or null
/// when [url] isn't one or is already the smallest. Old videos have no
/// maxres (or even sd) thumbnail, so artwork steps down on a failure.
String? smallerYouTubeThumbnail(String? url) {
  final match = _youTubeThumbnail.firstMatch(url ?? '');
  if (match == null) return null;
  final index = _youTubeThumbnailSizes.indexOf(match.group(2)!);
  if (index < 0 || index == _youTubeThumbnailSizes.length - 1) return null;
  return '${match.group(1)}${_youTubeThumbnailSizes[index + 1]}'
      '${match.group(3)}';
}

class MuzeeArtwork extends StatefulWidget {
  const MuzeeArtwork({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.iconSize = 24,
    this.fallbackIcon = FluentIcons.music_note_2_24_regular,
  });

  final String? url;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final double iconSize;
  final IconData fallbackIcon;

  @override
  State<MuzeeArtwork> createState() => _MuzeeArtworkState();
}

class _MuzeeArtworkState extends State<MuzeeArtwork> {
  static const _backoff = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 60),
  ];

  int _attempt = 0;
  bool _failed = false;
  Timer? _retryTimer;

  /// [MuzeeArtwork.url], or a smaller thumbnail of the same video after
  /// the bigger ones failed.
  String? _currentUrl;
  String? get _url => _currentUrl ?? widget.url;

  @override
  void initState() {
    super.initState();
    ArtworkRetry.generation.addListener(_onRetryRequested);
  }

  @override
  void didUpdateWidget(MuzeeArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _attempt = 0;
      _currentUrl = null;
      _failed = false;
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    ArtworkRetry.generation.removeListener(_onRetryRequested);
    super.dispose();
  }

  void _onRetryRequested() {
    if (_failed) _retry();
  }

  Future<void> _retry() async {
    final url = _url;
    _retryTimer?.cancel();
    _retryTimer = null;
    if (url == null || url.isEmpty) return;
    await CachedNetworkImage.evictFromCache(url);
    if (!mounted) return;
    setState(() {
      _attempt++;
      _failed = false;
    });
  }

  void _onError() {
    final smaller = smallerYouTubeThumbnail(_url);
    if (smaller != null) {
      // After this frame: errorWidget runs during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentUrl = smaller);
      });
      return;
    }
    _failed = true;
    final step = _attempt.clamp(0, _backoff.length);
    if (_retryTimer != null || step >= _backoff.length) return;
    _retryTimer = Timer(_backoff[step], _retry);
  }

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    final url = _url;
    Widget box(Widget? child) => Container(
      width: widget.width,
      height: widget.height,
      color: neo.surfaceRaised,
      alignment: Alignment.center,
      child: child,
    );
    final fallback = box(
      Icon(
        widget.fallbackIcon,
        size: widget.iconSize,
        color: neo.onSurfaceSubtle,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: (url == null || url.isEmpty)
          ? fallback
          : CachedNetworkImage(
              key: ValueKey('$url#$_attempt'),
              imageUrl: url,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (_, __) => box(null),
              errorWidget: (_, __, ___) {
                _onError();
                return fallback;
              },
            ),
    );
  }
}
