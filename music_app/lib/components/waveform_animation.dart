import 'dart:math';
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> barHeights;

  WaveformPainter(this.barHeights);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final barCount = barHeights.length;
    final barWidth = size.width / (barCount * 2 - 1);

    for (int i = 0; i < barCount; i++) {
      final barHeight = barHeights[i] * size.height;
      final x = i * barWidth * 2;
      final y = size.height - barHeight;

      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.barHeights != barHeights;
  }
}

class WaveformAnimation extends StatefulWidget {
  const WaveformAnimation({super.key});

  @override
  State<WaveformAnimation> createState() => _WaveformAnimationState();
}

class _WaveformAnimationState extends State<WaveformAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _barAnimations;
  final List<double> _currentHeights = [0.4, 0.7, 0.5];
  final _random = Random();

  void _generateNewHeights() {
    for (int i = 0; i < _currentHeights.length; i++) {
      final newValue = 0.3 + _random.nextDouble() * 0.6;
      _barAnimations[i] = Tween<double>(
        begin: _currentHeights[i],
        end: newValue,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _currentHeights[i] = newValue;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _barAnimations = List.generate(3, (index) {
      return AlwaysStoppedAnimation(_currentHeights[index]);
    });

    _generateNewHeights();
    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _generateNewHeights();
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final values = _barAnimations.map((a) => a.value).toList();
        return CustomPaint(
          size: const Size(50, 60),
          painter: WaveformPainter(values),
        );
      },
    );
  }
}
