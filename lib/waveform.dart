import 'package:Oz/component.dart';
import 'package:flutter/material.dart';
import 'logic.dart';
import 'main.dart';

const double size = 100;

class WaveformGraph extends StatelessWidget {
  final List<LogicValue> waveform;
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
      bool state = false;
      if (value == LogicValue.one)
        state = true;
      else if (value == LogicValue.zero)
        state = false;
      BorderSide topBorderSide = 
        state ? BorderSide(color: lineColor) : BorderSide.none;
      BorderSide bottomBorderSide = 
        state ? BorderSide.none : BorderSide(color: lineColor);
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
  final Map<GlobalKey<ComponentState>, WaveformGraph> _waveforms = {};

  void addWaveform(GlobalKey<ComponentState> componentKey, WaveformGraph waveformGraph) {
    setState(() {
      _waveforms[componentKey] = waveformGraph;
    });
  }

  void removeWaveform(GlobalKey<ComponentState> componentKey) {
    setState(() {
      _waveforms.remove(componentKey);
    });
  }

  void clearWaveforms() {
    setState(() {
      _waveforms.clear();
    });
  }

  void updateWaveform(Map<GlobalKey<ComponentState>, List<LogicValue>> newStates) {
    setState(() {
      newStates.forEach((key, value) {
        _waveforms[key] = WaveformGraph(waveform: value);
      });
    });
  }

  int getWaveformsLength() {
    return _waveforms.length;
  }

  @override 
  Widget build(BuildContext context) {
    List<Widget> waveformWidgets = [];

    int count = 0;
    _waveforms.forEach((key, value) {
      waveformWidgets.add(value);
      if (count < _waveforms.length - 1) {
        waveformWidgets.add(const SizedBox(height: 10));
      }
      count++;
    });

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
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: waveformWidgets,
            ),
          )
        ),
      ),
    );
  }
}

