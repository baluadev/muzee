import 'package:flutter/material.dart';
import 'package:muzee/design_system/components/neo_artwork.dart';
import 'package:muzee/theme/neo/neo_theme.dart';
import 'package:muzee/widgets/muzee_brand.dart';

/// Shown from the very first frame while the app starts (storage, Firebase,
/// the player…), then cross-faded into [app] once [ready] completes.
///
/// The system splash is a plain dark screen of the same colour, so the logo
/// appears once, easing in, with "now playing" bars under it while the app
/// loads. It stays up at least [minimumDuration] so a fast start doesn't
/// flash it. Reduced motion: no animation, just the logo.
class AppStartup extends StatefulWidget {
  const AppStartup({super.key, required this.ready, required this.app});

  final Future<void> ready;
  final Widget app;

  static const minimumDuration = Duration(milliseconds: 900);

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future.wait([
      widget.ready.catchError((Object _) {}),
      Future<void>.delayed(AppStartup.minimumDuration),
    ]).whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _done
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.app)
          : const SplashScreen(key: ValueKey('splash')),
    );
  }
}

/// The startup screen: the Muzee logo easing in, with bars under it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Same as the system splash (android/app/src/main/res/values/colors.xml).
  static const background = Color(0xFF0D0D0D);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduceMotion) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoIn = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),
    );
    final barsIn = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.45, 1, curve: Curves.easeOut),
    );
    // Above MaterialApp: no MediaQuery or text direction yet.
    return MediaQuery.fromView(
      view: View.of(context),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: buildNeoTheme(NeoThemeVariant.dark),
          child: ColoredBox(
            color: SplashScreen.background,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: logoIn,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.86, end: 1).animate(logoIn),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.08),
                              blurRadius: 48,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const MuzeeIcon(size: 112),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  FadeTransition(
                    opacity: barsIn,
                    child: const NeoNowPlayingBars(
                      isActive: true,
                      color: Colors.white70,
                      height: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
