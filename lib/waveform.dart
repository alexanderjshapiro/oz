import 'package:flutter/material.dart';
import 'main.dart';

const double size = 100;

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
    final double containerWidth = size;
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


class WaveformAnalyzer extends StatefulWidget {
  const WaveformAnalyzer({Key? key}) : super(key: key);

  @override
  WaveformAnalyzerState createState() => WaveformAnalyzerState();
}

class WaveformAnalyzerState extends State<WaveformAnalyzer> {
  final List<WaveformGraph> _waveforms = [];

  void addWaveform(WaveformGraph waveformGraph) {
    setState(() {
      _waveforms.add(waveformGraph);
    });
  }

  void removeWaveform(WaveformGraph waveformGraph) {
    setState(() {
      _waveforms.remove(waveformGraph);
    });
  }

  void clearWaveforms() {
    setState(() {
      _waveforms.clear();
    });
  }

  void updateWaveform(List<List<bool>> newStates) {
    setState(() {
      for(int i = 0; i < _waveforms.length; i++) {
        _waveforms[i] = WaveformGraph(waveform: newStates[i]);
      }
    });
  }

  int getWaveformsLength() {
    return _waveforms.length;
  }

  @override 
  Widget build(BuildContext context) {
    List<Widget> waveformWidgets = [];

    for (int i = 0; i < _waveforms.length; i++) {
      WaveformGraph waveformGraph = _waveforms[i];
      waveformWidgets.add(waveformGraph);

      if (i < _waveforms.length - 1) {
        waveformWidgets.add(const SizedBox(height: 10));
      }
    }

    // If the waveformWidgets array is empty, the box displays wrong so this is a workaround
    if (waveformWidgets.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.grey,
          border: Border(top: BorderSide(color: Colors.black))),
          height: 200,
          padding: const EdgeInsets.all(20),
      );
    }

    return SizedBox(
      height: 200,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.grey,
          border: Border(top: BorderSide(color: Colors.black)),
        ),
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: waveformWidgets,
            ) 
          ),
        ),
      ),
    );
  }
}

