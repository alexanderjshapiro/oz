import 'package:flutter/material.dart';
import 'main.dart';

class WaveformGraph extends StatefulWidget {
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
  _WaveformGraphState createState() => _WaveformGraphState();
}

class _WaveformGraphState extends State<WaveformGraph> {
  late List<Container> _waveformContainers;

  @override
  void initState() {
    super.initState();
    _generateWaveformContainers();
  }

  void _generateWaveformContainers() {
    final double containerWidth = widget.size / widget.waveform.length;
    final double containerHeight = widget.size / 2.0;
    var previousVal = widget.waveform[0];
    final List<Container> waveformContainers = [];
    for (var value in widget.waveform) {
      BorderSide topBorderSide =
          value ? BorderSide(color: widget.lineColor) : BorderSide.none;
      BorderSide bottomBorderSide =
          value ? BorderSide.none : BorderSide(color: widget.lineColor);
      BorderSide leftBorderSide;
      if (previousVal == value) {
        leftBorderSide = BorderSide.none;
      } else {
        leftBorderSide = BorderSide(color: widget.lineColor);
      }
      waveformContainers.add(Container(
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          border: Border(
            top: topBorderSide,
            bottom: bottomBorderSide,
            left: leftBorderSide,
          ),
        ),
      ));
      previousVal = value;
    }
    _waveformContainers = waveformContainers;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _waveformContainers,
    );
  }
}
