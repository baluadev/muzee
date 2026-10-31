import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:muzee/services/router_service.dart';
import 'package:muzee/theme/neo/neo_colors.dart';

/// Hive `settings` key: the intro has been shown on this device.
const introShownKey = 'introShown';

/// First-launch intro: the "Muzee" wordmark drawn in from left to right on
/// Muzee's black, then Home. Tapping skips it.
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final Animation<double> _reveal = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );
  Timer? _hold;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      _hold = Timer(const Duration(milliseconds: 500), _finish);
    });
  }

  void _finish() {
    if (_left || !mounted) return;
    _left = true;
    unawaited(Hive.box('settings').put(introShownKey, true));
    context.go(NavigationManager.homePath);
  }

  @override
  void dispose() {
    _hold?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displayLarge?.copyWith(
      fontSize: 64,
      color: context.neo.onSurface,
      fontWeight: FontWeight.w700,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Scaffold(
        backgroundColor: context.neo.background,
        body: Center(
          child: AnimatedBuilder(
            animation: _reveal,
            builder: (context, child) => ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) {
                // A soft edge sweeping across the word.
                final t = _reveal.value;
                return LinearGradient(
                  colors: const [Colors.white, Colors.transparent],
                  stops: [t, (t + 0.08).clamp(0.0, 1.0)],
                ).createShader(bounds);
              },
              child: child,
            ),
            child: Text('Muzee', style: style),
          ),
        ),
      ),
    );
  }
}
