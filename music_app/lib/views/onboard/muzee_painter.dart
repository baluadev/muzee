import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class MuzeeAnimation extends StatefulWidget {
  const MuzeeAnimation({super.key});

  @override
  State<MuzeeAnimation> createState() => _MuzeeAnimationState();
}

class _MuzeeAnimationState extends State<MuzeeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: false);

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        painter: MuzeePainter(progress: _progress),
        size: const Size(300, 100),
      ),
    );
  }
}

class MuzeePainter extends CustomPainter {
  final Animation<double> progress;

  MuzeePainter({required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paragraphStyle = ui.ParagraphStyle(
      fontSize: 60,
      fontWeight: FontWeight.bold,
      textAlign: TextAlign.center,
    );

    final textStyle = ui.TextStyle(
      color: Colors.white,
    );

    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText('Muzee');

    final constraints = ui.ParagraphConstraints(width: size.width);

    final paragraph = paragraphBuilder.build();
    paragraph.layout(constraints);

    // Draw text as path
    final path = paragraph.getBoxesForRange(0, 'Muzee'.length).isNotEmpty
        ? paragraphToPath(paragraph, Offset.zero)
        : Path();

    // Center path in canvas
    final bounds = path.getBounds();
    final dx = (size.width - bounds.width) / 2 - bounds.left;
    final dy = (size.height - bounds.height) / 2 - bounds.top;
    final matrix = Matrix4.translationValues(dx, dy, 0).storage;
    path.transform(matrix);

    final pathMetrics = path.computeMetrics().toList();

    final drawPath = Path();

    double totalLength = pathMetrics.fold<double>(
      0.0,
      (prev, metric) => prev + metric.length,
    );

    double currentLength = totalLength * progress.value;
    double drawn = 0.0;

    for (final metric in pathMetrics) {
      final remain = currentLength - drawn;
      if (remain <= 0) break;

      final length = remain < metric.length ? remain : metric.length;
      final extract = metric.extractPath(0, length);
      drawPath.addPath(extract, Offset.zero);

      drawn += length;
    }

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(drawPath, paint);
  }

  @override
  bool shouldRepaint(covariant MuzeePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Convert Paragraph to Path
Path paragraphToPath(ui.Paragraph paragraph, Offset offset) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.translate(offset.dx, offset.dy);
  canvas.drawParagraph(paragraph, Offset.zero);

  // final picture = recorder.endRecording();
  // final image = picture.toImageSync(
  //   paragraph.maxIntrinsicWidth.ceil(),
  //   paragraph.height.ceil(),
  // );

  // final bytes = image.toByteData(format: ui.ImageByteFormat.png);

  // Unfortunately, Paragraph → path conversion isn't direct in Flutter.
  // For precise vector paths, you’d need external tools like SVG to Path.
  //
  // For demo purposes, let's return an approximate rectangle path instead.
  //
  // => For production, you should convert text to SVG paths externally.

  return Path()..addRect(Rect.fromLTWH(0, 0, paragraph.maxIntrinsicWidth, paragraph.height));
}
