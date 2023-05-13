import 'package:oz/component.dart';
import 'package:flutter/material.dart';
import 'logic.dart';
import 'main.dart';

const BorderSide blackBorder = BorderSide(color: Colors.black);

void updateWaveformAnalyzer() {
  if (editorCanvasKey.currentState!.components.isNotEmpty &&
      probedPorts.isNotEmpty) {
    // Update current output port states
    probedPorts.forEach((key, value) {
      currentComponentStates[key] = (value.value);
      // Add the component output port if it hasn't been added to the analyzer yet
      if (!waveformAnalyzerKey.currentState!.getWaveforms().containsKey(key)) {
        waveformAnalyzerKey.currentState!.addWaveform(key);
      }
    });
    waveformAnalyzerKey.currentState!.updateWaveforms(currentComponentStates);
  }
}

class WaveformGraph extends StatelessWidget {
  final List<LogicValue> waveform;

  const WaveformGraph({
    Key? key,
    required this.waveform,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double containerWidth = 20;
    const double containerHeight = 50;
    List<Widget> stateWaves = [];
    var previousVal = waveform[0];
    for (var value in waveform) {
      bool state = false;
      if (value == LogicValue.one) {
        state = true;
      } else if (value == LogicValue.zero) {
        state = false;
      }
      BorderSide topBorderSide = state ? blackBorder : BorderSide.none;
      BorderSide bottomBorderSide = state ? BorderSide.none : blackBorder;
      BorderSide leftBorderSide;
      if (previousVal == value) {
        leftBorderSide = BorderSide.none;
      } else {
        leftBorderSide = blackBorder;
      }
      stateWaves.add(
        Container(
          width: containerWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            border: Border(
              top: topBorderSide,
              bottom: bottomBorderSide,
              left: leftBorderSide,
            ),
          ),
        ),
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
  final Map<GlobalKey<ComponentState>, List<LogicValue>> _waveforms = {};
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void addWaveform(GlobalKey<ComponentState> componentKey) {
    setState(() {
      if (_waveforms.isNotEmpty) {
        _waveforms[componentKey] = [];
        // Find the longest list
        List<LogicValue> longestList = [];
        // This breaks everything if there's only one element in _waveforms
        if (_waveforms.length > 1) {
          longestList = _waveforms.values.reduce((value, element) =>
              value.length > element.length ? value : element);
        } else {
          longestList = _waveforms.values.first;
        }

        // Fill the new component list with LogicValue.zero
        // so that the new waveform gets displayed properly
        for (int i = 0; i < longestList.length; i++) {
          _waveforms[componentKey]!.add(LogicValue.zero);
        }
      } else {
        _waveforms[componentKey] = [];
      }
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

  void updateWaveforms(Map<GlobalKey<ComponentState>, LogicValue> newStates) {
    setState(() {
      newStates.forEach((key, value) {
        _waveforms[key]?.add(value);
      });
    });
  }

  Widget getComponentName(GlobalKey<ComponentState> componentKey) {
    String name = componentKey.currentState!.module.name;
    String port = probedPorts[componentKey]!.portName;
    return SizedBox(
      height: 50,
      child: Container (
        child: Column(children: [
          Text(name, style: const TextStyle(fontSize: 16)), 
          Text(port, style: const TextStyle(fontSize: 16)),
          ],
        )
      ),
    );
  }

  int getWaveformsLength() => _waveforms.length;

  Map<GlobalKey<ComponentState>, List<LogicValue>> getWaveforms() => _waveforms;

  @override
  Widget build(BuildContext context) {
    List<Widget> waveformWidgets = [];
    List<Widget> waveformNames = [];

    int count = 0;
    _waveforms.forEach((key, value) {
      waveformWidgets.add(WaveformGraph(waveform: value));
      waveformNames.add(getComponentName(key));
      if (count < _waveforms.length - 1) {
        waveformWidgets.add(const SizedBox(height: 10));
        waveformNames.add(const SizedBox(height: 10));
      }
      count++;
    });

    //Update the position of the scrollbar must occur after the widget is updated
    // Else the bar will scroll to the second to last position instead of the end.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOutSine,
        );
      }
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
        child: ListView(
          children: [
            Row(
              children: [
                Column(children: waveformNames),
                const SizedBox(width: 10),
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children: waveformWidgets,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          ]
        )
      ),
    );
  }
}
