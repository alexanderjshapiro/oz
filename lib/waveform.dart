import 'package:flutter/material.dart';
import 'main.dart';

const size = 200;

class WaveformGraph extends StatelessWidget {
  final List<bool> waveform;
  final Color lineColor;

  const WaveformGraph({
    Key? key,
    required this.waveform,
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
    );
  }
}

// class WaveformGraph extends StatefulWidget {
//   List<bool> waveform;
//   double size;
//   final Color lineColor;

//   WaveformGraph({
//     Key? key,
//     required this.waveform,
//     required this.size,
//     this.lineColor = Colors.black,
//   }) : super(key: key);

//   @override
//   _WaveformGraphState createState() => _WaveformGraphState();
// }

// class _WaveformGraphState extends State<WaveformGraph> {
//   late List<Container> _waveformContainers;

//   @override
//   void initState() {
//     super.initState();
//     _generateWaveformContainers();
//   }

//   void _generateWaveformContainers() {
//     final double containerWidth = widget.size / widget.waveform.length;
//     final double containerHeight = widget.size / 2.0;
//     var previousVal = widget.waveform[0];
//     final List<Container> waveformContainers = [];
//     for (var value in widget.waveform) {
//       BorderSide topBorderSide =
//           value ? BorderSide(color: widget.lineColor) : BorderSide.none;
//       BorderSide bottomBorderSide =
//           value ? BorderSide.none : BorderSide(color: widget.lineColor);
//       BorderSide leftBorderSide;
//       if (previousVal == value) {
//         leftBorderSide = BorderSide.none;
//       } else {
//         leftBorderSide = BorderSide(color: widget.lineColor);
//       }
//       waveformContainers.add(Container(
//         width: containerWidth,
//         height: containerHeight,
//         decoration: BoxDecoration(
//           border: Border(
//             top: topBorderSide,
//             bottom: bottomBorderSide,
//             left: leftBorderSide,
//           ),
//         ),
//       ));
//       previousVal = value;
//     }
//     _waveformContainers = waveformContainers;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: _waveformContainers,
//     );
//   }
// }
