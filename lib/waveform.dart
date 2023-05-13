import 'package:oz/component.dart';
import 'package:flutter/material.dart';
import 'logic.dart';
import 'main.dart';

const Color backgroundColor = Color.fromARGB(255, 240, 239, 239);

const BorderSide blackBorder = BorderSide(color: Colors.black, width: 2);
const BorderSide zBorder = BorderSide(color: Colors.red);
const BorderSide xBorder = BorderSide(color: Colors.grey);

void newUpdateWaveformAnalyzer() {
  if (editorCanvasKey.currentState!.components.isNotEmpty &&
      newProbedPorts.isNotEmpty) {
    // Update current output port states
    newProbedPorts.forEach((componentKey, probedPortKeyList) {
      List<PhysicalPort> modulePorts = componentKey.currentState!.module.ports;
      for (String portKey in probedPortKeyList) {
        PhysicalPort probedPort = modulePorts.firstWhere((port) => port.key == portKey);
        newCurrentPortStates[portKey] = probedPort.value;
      }
    });
    debugPrint('updating analyzer');
    waveformAnalyzerKey.currentState!.newUpdateWaveforms(newCurrentPortStates);
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
      late BorderSide topBorderSide;
      late BorderSide bottomBorderSide;
      late BorderSide leftBorderSide;
      if (value == LogicValue.one) {
        topBorderSide = blackBorder;
        bottomBorderSide = BorderSide.none;
      } else if (value == LogicValue.zero) {
        topBorderSide = BorderSide.none;
        bottomBorderSide = blackBorder;
      } else if (value == LogicValue.z) {
        topBorderSide = BorderSide.none;
        bottomBorderSide = zBorder;
      } else {
        topBorderSide = BorderSide.none;
        bottomBorderSide = xBorder;
      }

      if (previousVal == value) {
        leftBorderSide = BorderSide.none;
      } else if (value == LogicValue.zero && [LogicValue.x, LogicValue.z].contains(previousVal)) {
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
  final Map<GlobalKey<ComponentState>, Map<String, List<LogicValue>>> _newWaveforms = {};
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void newAddWaveform(GlobalKey<ComponentState> componentKey, String portKey) {
    setState(() {
      if (_newWaveforms.isNotEmpty) {
        _newWaveforms[componentKey]?[portKey] = [];
        // Find the longest list
        List<LogicValue> longestList = [];
        int maxLength = 0;
        if (_newWaveforms.length > 1) {
        for (var componentData in _newWaveforms.values) {
          for (var list in componentData.values) {
            if (list.length > maxLength) {
              maxLength = list.length;
              longestList = list;
            }
          }
        }
        } else {
        _newWaveforms[componentKey]?.values.first;
        }

        // Fill the new component list with LogicValue.zero
        // so that the new waveform gets displayed properly
        for (int i = 0; i < longestList.length; i++) {
          _newWaveforms[componentKey]?[portKey]?.add(LogicValue.x);
        }
      } else {
        _newWaveforms[componentKey]?[portKey] = [];
      }
    });
  }

  void newRemoveWaveforms(GlobalKey<ComponentState> componentKey, String portKey) {
    setState(() {
      _newWaveforms[componentKey]?.remove(portKey);
      bool waveformsIsEmpty = _newWaveforms[componentKey]?.isEmpty ?? false;
      if (waveformsIsEmpty) {
        _newWaveforms.remove(componentKey);
      }
    });
  }

  void clearWaveforms() {
    setState(() {
      _waveforms.clear();
    });
  }

  void newUpdateWaveforms(Map<String, LogicValue> newStates) {
    setState(() {
      _newWaveforms.forEach((componentKey, ports) {
        ports.forEach((portKey, _) {
          LogicValue newState = newStates[portKey] ?? LogicValue.x;
          _newWaveforms[componentKey]![portKey]?.add(newState);
        });
      });
    });
  }

  Widget newGetComponetName(GlobalKey<ComponentState> componentKey, String portKey) {
    String name = componentKey.currentState!.module.name;
    List<PhysicalPort> ports = componentKey.currentState!.module.ports;
    PhysicalPort port = ports.firstWhere((port) => port.key == portKey);
    String portName = port.portName;
    return SizedBox(
      height: 50,
      child: Container (
        child: Column(children: [
          Text(name, style: const TextStyle(fontSize: 16)), 
          Text(portName, style: const TextStyle(fontSize: 16)),
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
    _newWaveforms.forEach((componentKey, portStates) {
      portStates.forEach((portKey, states) {
        waveformWidgets.add(WaveformGraph(waveform: states));
        waveformNames.add(newGetComponetName(componentKey, portKey));
        if (count < _newWaveforms.length - 1) {
          waveformWidgets.add(const SizedBox(height: 10));
          waveformNames.add(const SizedBox(height: 10));
        }
        count++;
      });
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
            color: backgroundColor,
            border: Border(top: BorderSide(color: Colors.black))),
        height: 200,
        padding: const EdgeInsets.all(20),
      );
    }

    return SizedBox(
      height: 200,
      child: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: Colors.black)),
        ),
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            Row(
              children: [
                Column(children: waveformNames),
                const SizedBox(width: 20),
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
