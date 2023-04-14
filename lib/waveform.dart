import 'package:flutter/material.dart';
import 'main.dart';

class WaveformGraph extends StatelessWidget {
  final List<bool> waveform;
  final double size;
  final Color lineColor;

  const WaveformGraph({
    Key? key,
    required this.waveform,
    required this.size,
    this.lineColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double containerWidth = size / waveform.length;
    final double containerHeight = size / 2.0;
    
    List<Container> stateWaves = [];

    var previousVal = waveform[0];
    for (var value in waveform) {
      BorderSide topBorderSide = 
        value ? BorderSide(color: lineColor) : BorderSide.none;
      BorderSide bottomBorderSide = 
        value ? BorderSide.none : BorderSide(color: lineColor);
      BorderSide leftBorderSide;
      if (previousVal == value) {
        leftBorderSide = BorderSide.none;
      } else {
        leftBorderSide = BorderSide(color: lineColor);
      }
      stateWaves.add(
        Container(
          width: containerWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            border: Border(
              top: topBorderSide,
              bottom: bottomBorderSide,
              left: leftBorderSide
            )
          ),
        )
      );
      previousVal = value;
    }
    return Row(
      children: stateWaves,

      // waveform.map((value) {
      //   final BorderSide topBorderSide =
      //       value ? BorderSide(color: lineColor) : BorderSide.none;
      //   final BorderSide bottomBorderSide =
      //       value ? BorderSide.none : BorderSide(color: lineColor);
      //   return Container(
      //     width: containerWidth,
      //     height: containerHeight,
      //     decoration: BoxDecoration(
      //       border: Border(
      //         top: topBorderSide,
      //         bottom: bottomBorderSide,
      //       ),
      //     ),
      //   );
      // }).toList(),
    
    );
  }
}



// class WaveformGraph extends StatelessWidget {
//   final List<bool> waveform;
//   final double width;
//   final double height;
//   final Color lineColor;
//   final double lineWidth;

//   WaveformGraph({
//     required this.waveform,
//     required this.width,
//     required this.height,
//     this.lineColor = Colors.black,
//     this.lineWidth = 1.0,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       size: Size(width, height),
//       painter: WaveformGraphPainter(
//         waveform: waveform,
//         lineColor: lineColor,
//         lineWidth: lineWidth,
//       ),
//     );
//   }
// }

// class WaveformGraphPainter extends CustomPainter {
//   final List<bool> waveform;
//   final Color lineColor;
//   final double lineWidth;

//   WaveformGraphPainter({
//     required this.waveform,
//     this.lineColor = Colors.black,
//     this.lineWidth = 1.0,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final double xScale = size.width / (waveform.length - 1);
//     final double yScale = size.height / 2.0;

//     // Draw the waveform rectangles
//     final Paint paint = Paint()
//       ..color = lineColor
//       ..strokeWidth = 1.0
//       ..style = PaintingStyle.stroke;
//     var previousState = waveform[0];
//     for (int i = 0; i < waveform.length; i++) {
//       double left;
//       if (previousState == waveform[i]) {
//         left = 0;
//       }  
//       else {
//         left = i * xScale;
//       }
//       previousState = waveform[i];
//       final double top = waveform[i] ? 0 : size.height / 2.0;
//       final double right = (i + 1) * xScale;
//       final double bottom = waveform[i] ? size.height / 2.0 : size.height;
//       final Rect rect = Rect.fromLTRB(left, top, right, bottom);
//       canvas.drawRect(rect, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(WaveformGraphPainter oldDelegate) =>
//       waveform != oldDelegate.waveform ||
//       lineColor != oldDelegate.lineColor ||
//       lineWidth != oldDelegate.lineWidth;
// }
