import 'package:flutter/material.dart';
import 'package:muzee/screens/now_playing_page.dart';
import 'package:muzee/screens/now_playing_route.dart';

/// Opens the full player from a drag up on the mini player, the page
/// following the finger.
///
/// A route can't be pushed mid-drag (the navigator cancels the pointer), so
/// while the finger is down a preview of the page slides in the app's
/// overlay. On release the real [NowPlayingRoute] is pushed at the preview's
/// position and finishes the move, or the preview slides back down.
class NowPlayingDragOpener {
  NowPlayingDragOpener({
    required TickerProvider vsync,
    @visibleForTesting WidgetBuilder? pageBuilder,
    @visibleForTesting Widget? preview,
  }) : _progress = AnimationController(vsync: vsync),
       _pageBuilder = pageBuilder,
       _previewPage = preview ?? const NowPlayingPage(preview: true);

  final WidgetBuilder? _pageBuilder;
  final Widget _previewPage;

  /// 0 closed – 1 open, like the route's own animation.
  final AnimationController _progress;
  OverlayEntry? _preview;

  static const _closeDuration = Duration(milliseconds: 200);

  bool get isDragging => _preview != null;

  void start(BuildContext context) {
    _remove();
    _progress.value = 0;
    if (MediaQuery.disableAnimationsOf(context)) return;
    final entry = OverlayEntry(
      builder: (_) => _DragPreview(progress: _progress, page: _previewPage),
    );
    _preview = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  /// [delta] in logical pixels (negative = up), out of a screen [height].
  void update(double delta, double height) {
    if (height <= 0) return;
    _progress.value = (_progress.value - delta / height).clamp(0.0, 1.0);
  }

  /// [velocity] in logical px/s (negative = up).
  void end(BuildContext context, double velocity) {
    final value = _progress.value;
    if (NowPlayingRoute.shouldOpen(value, velocity)) {
      Navigator.of(context).push(
        // With reduced motion there is no preview to take over from.
        NowPlayingRoute(
          initialValue: _preview == null ? null : value,
          pageBuilder: _pageBuilder,
        ),
      );
      // Keep the preview for the route's first frame, so nothing flickers.
      WidgetsBinding.instance.addPostFrameCallback((_) => _remove());
    } else if (_preview != null) {
      _progress
          .animateTo(0, duration: _closeDuration * value, curve: Curves.easeOut)
          .whenCompleteOrCancel(_remove);
    }
  }

  void _remove() {
    _preview?.remove();
    _preview = null;
  }

  void dispose() {
    _remove();
    _progress.dispose();
  }
}

class _DragPreview extends StatelessWidget {
  const _DragPreview({required this.progress, required this.page});

  final Animation<double> progress;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Same tint as the route's barrier.
        AnimatedBuilder(
          animation: progress,
          builder: (_, __) => ColoredBox(
            color: Color.lerp(
              Colors.transparent,
              Colors.black54,
              Curves.ease.transform(progress.value),
            )!,
          ),
        ),
        SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(progress),
          child: page,
        ),
      ],
    );
  }
}
