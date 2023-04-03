import 'package:flutter/material.dart';
import 'main.dart';

class WaveformGraph extends StatelessWidget {
  final List<bool> waveform;
  final double width;
  final double height;
  final Color lineColor;
  final double lineWidth;

  WaveformGraph({
    required this.waveform,
    required this.width,
    required this.height,
    this.lineColor = Colors.black,
    this.lineWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: WaveformGraphPainter(
        waveform: waveform,
        lineColor: lineColor,
        lineWidth: lineWidth,
      ),
    );
  }
}

class WaveformGraphPainter extends CustomPainter {
  final List<bool> waveform;
  final Color lineColor;
  final double lineWidth;

  WaveformGraphPainter({
    required this.waveform,
    this.lineColor = Colors.black,
    this.lineWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double xScale = size.width / (waveform.length - 1);
    final double yScale = size.height / 2.0;
    final Path path = Path();

    // Move to the first point
    path.moveTo(0, yScale);

    // Draw the waveform path
    for (int i = 0; i < waveform.length; i++) {
      final double x = i * xScale;
      final double y = waveform[i] ? 0 : size.height;
      path.lineTo(x, y);
    }

    // Draw the waveform path
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformGraphPainter oldDelegate) =>
      waveform != oldDelegate.waveform ||
      lineColor != oldDelegate.lineColor ||
      lineWidth != oldDelegate.lineWidth;
}
