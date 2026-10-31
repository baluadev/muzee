import 'package:flutter/material.dart';
import 'package:muzee/screens/now_playing_page.dart';
import 'package:muzee/theme/neo/neo_motion.dart';

/// Hero tag shared by the mini player's artwork and the full player's.
const nowPlayingArtworkHeroTag = 'now_playing_artwork';

/// The full player, sliding up over the app.
///
/// A drag down on the player closes it, the page following the finger
/// ([dragStart]/[dragUpdate]/[dragEnd]); releasing past half way, or with a
/// fling, finishes the move, otherwise it springs back.
///
/// A drag up on the mini player can't push a route mid-drag (pushing cancels
/// the pointer), so the mini player slides a preview of this page instead and
/// pushes the route on release with [initialValue] set to where the preview
/// stopped; the route carries on from there.
class NowPlayingRoute extends PageRoute<void> {
  NowPlayingRoute({this.initialValue, WidgetBuilder? pageBuilder})
    : _pageBuilder = pageBuilder ?? ((_) => const NowPlayingPage()),
      _heroesEnabled = initialValue == null;

  /// How far open (0–1) the page starts, when taking over from a drag.
  final double? initialValue;

  /// Off while taking over from a drag preview, which shows the artwork in
  /// place already; a flight from the mini player would jump.
  bool _heroesEnabled;

  /// Builds the page; tests pass a stand-in for [NowPlayingPage].
  final WidgetBuilder _pageBuilder;

  static const _flingVelocity = 700.0; // logical px / s
  static const _settleDuration = Duration(milliseconds: 220);

  /// Whether a gesture sends [velocity] (logical px/s, negative = up) and a
  /// page [value] (0 closed – 1 open) to the open state.
  static bool shouldOpen(double value, double velocity) =>
      velocity.abs() >= _flingVelocity ? velocity < 0 : value >= 0.5;

  /// How long the page takes to finish opening from [value].
  static Duration settleDuration(double value) =>
      _settleDuration * (1 - value).clamp(0.0, 1.0);

  /// The page tracks a finger (or finishes a drag's move): no curve.
  bool _dragging = false;

  /// The navigator was told a user gesture is in progress.
  bool _gestureStarted = false;

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => NeoMotion.standardSet.emphasized;

  @override
  Duration get reverseTransitionDuration => NeoMotion.standardSet.emphasized;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => GestureDetector(
    // Drag down anywhere outside the slider and the lyrics (they take their
    // own drags) to close.
    onVerticalDragStart: (_) => dragStart(),
    onVerticalDragUpdate: (details) => dragUpdate(
      details.primaryDelta ?? 0,
      MediaQuery.sizeOf(context).height,
    ),
    onVerticalDragEnd: (details) => dragEnd(details.primaryVelocity ?? 0),
    onVerticalDragCancel: () => dragEnd(0),
    child: Builder(builder: _pageBuilder),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    child = HeroMode(enabled: _heroesEnabled, child: child);
    if (MediaQuery.disableAnimationsOf(context)) return child;
    // A finger moves the page 1:1; the curve is only for the page moving by
    // itself.
    final curved = _dragging || navigator!.userGestureInProgress
        ? animation
        : CurvedAnimation(
            parent: animation,
            curve: NeoMotion.standardSet.enter,
            reverseCurve: NeoMotion.standardSet.exit,
          );
    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  }

  @override
  TickerFuture didPush() {
    final start = initialValue;
    if (start == null) return super.didPush();
    super.didPush().ignore();
    // Carry on from the preview, uncurved so it doesn't jump.
    _dragging = true;
    final settle =
        (controller!
              ..stop()
              ..value = start)
            .animateTo(
              1,
              duration: settleDuration(start),
              curve: Curves.easeOut,
            )
          ..whenCompleteOrCancel(() {
            _dragging = false;
            _heroesEnabled = true;
            changedInternalState();
          });
    return settle;
  }

  /// Begins a drag down on the open player.
  void dragStart() {
    if (!isCurrent || _gestureStarted) return;
    controller!.stop();
    _startGesture();
  }

  /// Moves the page by [delta] logical pixels (positive = down), out of a
  /// page [height] tall.
  void dragUpdate(double delta, double height) {
    if (!_gestureStarted || height <= 0) return;
    controller!.value = (controller!.value - delta / height).clamp(0.0, 1.0);
  }

  /// Ends a drag; [velocity] is in logical px/s (positive = down).
  void dragEnd(double velocity) {
    if (!_gestureStarted) return;
    final c = controller!;
    if (shouldOpen(c.value, velocity)) {
      _settle(c.animateTo(1, duration: settleDuration(c.value)));
    } else {
      // Popping runs the reverse animation from where the finger left it.
      _stopGesture();
      navigator?.pop();
    }
  }

  void _startGesture() {
    _dragging = true;
    _gestureStarted = true;
    navigator?.didStartUserGesture();
  }

  void _stopGesture() {
    _dragging = false;
    if (!_gestureStarted) return;
    _gestureStarted = false;
    final nav = navigator;
    if (nav != null && nav.mounted) nav.didStopUserGesture();
  }

  void _settle(TickerFuture future) {
    future.whenCompleteOrCancel(_stopGesture);
  }

  @override
  void dispose() {
    _stopGesture();
    super.dispose();
  }
}
