import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rohd/rohd.dart' as rohd;

const Duration tickRate = Duration(milliseconds: 250);

//var ins = [rohd.Const(0), rohd.Const(1)];
//var xor = rohd.Xor2Gate(ins[0], ins[1]);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool _isRunning = false;
  Timer? _simulationTickTimer;
  var masterClk = rohd.SimpleClockGenerator(2).clk;

  var clk = rohd.SimpleClockGenerator(10).clk;

  List<rohd.Module> mds = [];
  MyAppState() {
    mds.add(rohd.Xor2Gate(
        rohd.Const(rohd.LogicValue.z), rohd.Const(rohd.LogicValue.z)));

    mds.add(rohd.NotGate(mds[0].outputs.values.elementAt(0)));
    mds.add(rohd.FlipFlop(clk, mds[1].outputs.values.elementAt(0)));
  }

  //  rohd.FlipFlop(rohd.Const(rohd.LogicValue.z), rohd.Const(rohd.LogicValue.z)),
  //  rohd.NotGate(rohd.Const(rohd.LogicValue.z)),

  List<String> compNames = ["XOR", "Not", "FlipFlop"];
  //var ins = [rohd.Const(0), rohd.Const(1)];

  void _startSimulation() {
    setState(() {
      _isRunning = true;
    });
    //Setup a timer to repeatibly call Simulator.tick();
    // Simulator.run() would probably be better, but I cant't get to work without freezing flutter
    _simulationTickTimer = Timer.periodic(tickRate, (timer) {
      setState(() {
        //debugPrint("tick");
        rohd.Simulator.tick();
      });
    });
  }

  void _stopSimulation() {
    _simulationTickTimer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROHD Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        canvasColor: Colors.blueGrey[200],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('XOR - ROHD'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < mds.length; i++)
                Column(
                  children: [
                    Text(
                      compNames[i], // Add a label for each component
                      style: const TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: ComponentBox(
                        module: mds[i],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              if (!_isRunning)
                ElevatedButton(
                  onPressed: _startSimulation,
                  child: const Text('Start Simulation'),
                )
              else
                ElevatedButton(
                  onPressed: _stopSimulation,
                  child: const Text('Stop Simulation'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComponentBox extends StatefulWidget {
  final rohd.Module module; // Add module field

  const ComponentBox({
    Key? key, // Make key nullable
    required this.module, // Add module parameter
  }) : super(key: key); // Call super with nullable key

  @override
  ComponentBoxState createState() => ComponentBoxState();
}

class ComponentBoxState extends State<ComponentBox> {
  late List<rohd.LogicValue> _inputCircleValList;
  late List<rohd.LogicValue> _outputCircleValList;
  late int leftCirclesCount;
  late int rightCirclesCount;

  @override
  void initState() {
    super.initState();

    leftCirclesCount = widget.module.inputs.length;
    rightCirclesCount = widget.module.outputs.length;

    _outputCircleValList = List.filled(rightCirclesCount, rohd.LogicValue.x);
    _inputCircleValList = List.filled(leftCirclesCount, rohd.LogicValue.z);
    if (!widget.module.hasBuilt) {
      widget.module.build();
    }
    //Create a callbacks whenever the component outputs change.
    for (int i = 0; i < widget.module.outputs.length; i++) {
      debugPrint("Registered Output $i");
      widget.module.outputs.values.elementAt(i).changed.listen((event) {
        _setRightCircleColor(i, event.newValue);
      });
    }

    //Create a callbacks whenever the component input change.
    for (int i = 0; i < widget.module.inputs.length; i++) {
      debugPrint("Registered Input $i");
      widget.module.inputs.values.elementAt(i).changed.listen((event) {
        _setLeftCircleColor(i, event.newValue);
        //_toggleLeftCircleColor(i);
        debugPrint("$event");
      });
    }
  }

  _toggleInputCircleValue(int index) {
    if (_inputCircleValList[index] == rohd.LogicValue.z) {
      _inputCircleValList[index] = rohd.LogicValue.one;
    } else if (_inputCircleValList[index] == rohd.LogicValue.x) {
      _inputCircleValList[index] = rohd.LogicValue.one;
    } else if (_inputCircleValList[index] == rohd.LogicValue.one) {
      _inputCircleValList[index] = rohd.LogicValue.zero;
    } else if (_inputCircleValList[index] == rohd.LogicValue.zero) {
      _inputCircleValList[index] = rohd.LogicValue.one;
    } else {
      throw ("error");
    }
    widget.module.inputs.values
        .elementAt(index)
        .inject(_inputCircleValList[index]);
  }

  /*void _toggleLeftCircleColor(int index) {
    setState(() {
      if (_inputCircleValList[index] == rohd.LogicValue.z) {
        _inputCircleValList[index] = rohd.LogicValue.one;
      } else if (_inputCircleValList[index] == rohd.LogicValue.x) {
        _inputCircleValList[index] = rohd.LogicValue.one;
      } else if (_inputCircleValList[index] == rohd.LogicValue.one) {
        _inputCircleValList[index] = rohd.LogicValue.zero;
      } else if (_inputCircleValList[index] == rohd.LogicValue.zero) {
        _inputCircleValList[index] = rohd.LogicValue.one;
      } else {
        throw ("error");
      }
      widget.module.inputs.values
          .elementAt(index)
          .inject(_inputCircleValList[index]);
      //ins[index].inject(_inputCircleValList[index]);
    });
  }*/

  void _setRightCircleColor(int index, rohd.LogicValue status) {
    setState(() {
      _outputCircleValList[index] = status;
    });
  }

  void _setLeftCircleColor(int index, rohd.LogicValue status) {
    setState(() {
      _inputCircleValList[index] = status;
    });
  }

  Color? getColour(rohd.LogicValue val) {
    if (val == rohd.LogicValue.one) {
      return Colors.orange[800];
    }
    if (val == rohd.LogicValue.zero) {
      return Colors.deepPurple[900];
    }
    if (val == rohd.LogicValue.z) {
      return Colors.amber;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    double circleSize = 40.0;
    double paddingSize = 10.0;
    double circleSpacing = 5;

    double boxWidth = (circleSize * 2) + (paddingSize * 2) + circleSpacing;

    double boxHeight = (max(leftCirclesCount, rightCirclesCount) * circleSize) +
        (paddingSize * 2);

    return Container(
      padding: EdgeInsets.all(paddingSize),
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        color: Colors.teal[400],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              for (int i = 0; i < leftCirclesCount; i++)
                GestureDetector(
                  onTap: () => _toggleInputCircleValue(i),
                  child: CircleAvatar(
                    backgroundColor: getColour(_inputCircleValList[i]),
                    radius: circleSize / 2,
                  ),
                ),
            ],
          ),
          SizedBox(width: circleSpacing),
          Column(
            children: [
              for (int i = 0; i < rightCirclesCount; i++)
                CircleAvatar(
                  backgroundColor: getColour(_outputCircleValList[i]),
                  radius: circleSize / 2,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
