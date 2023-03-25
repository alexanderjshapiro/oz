import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rohd/rohd.dart' as rohd;

const Duration tickRate = Duration(milliseconds: 50);

//var ins = [rohd.Const(0), rohd.Const(1)];
//var xor = rohd.Xor2Gate(ins[0], ins[1]);

void main() {
  /// This clock ensures that there is always one event every time step
  /// Otherwise calling Simulation.tick would advance the simulation till something changed
  /// Which is not good for a 'realtime' simulation.
  rohd.SimpleClockGenerator(2);
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

  var clk = rohd.SimpleClockGenerator(60).clk;
  List<rohd.Module> mds = [];
  MyAppState() {
    mds.add(rohd.Xor2Gate(
        rohd.Const(rohd.LogicValue.z), rohd.Const(rohd.LogicValue.z)));
    mds.add(rohd.NotGate(mds[0].outputs.values.elementAt(0)));
    mds.add(rohd.FlipFlop(clk, mds[1].outputs.values.elementAt(0)));
  }
  List<String> compNames = ["XOR", "Not", "FlipFlop"];

  void _startSimulation() {
    setState(() {
      _isRunning = true;
    });
    //Setup a timer to repeatibly call Simulator.tick();
    // Simulator.run() would probably be better, but I cant't get to work without freezing flutter
    _simulationTickTimer = Timer.periodic(tickRate, (timer) {
      setState(() {
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
          title: const Text('ROHD Simulation'),
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
  @override
  void initState() {
    super.initState();

    if (!widget.module.hasBuilt) {
      widget.module.build();
    }
  }

  _toggleInputCircleValue(int index) {
    if (widget.module.inputs.values.elementAt(index).value ==
        rohd.LogicValue.one) {
      widget.module.inputs.values.elementAt(index).inject(rohd.LogicValue.zero);
    } else {
      widget.module.inputs.values.elementAt(index).inject(rohd.LogicValue.one);
    }
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

    double boxHeight =
        (max(widget.module.inputs.length, widget.module.outputs.length) *
                circleSize) +
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
              for (int i = 0; i < widget.module.inputs.length; i++)
                GestureDetector(
                  onTap: () => _toggleInputCircleValue(i),
                  child: CircleAvatar(
                    backgroundColor: getColour(
                        widget.module.inputs.values.elementAt(i).value),
                    radius: circleSize / 2,
                  ),
                ),
            ],
          ),
          SizedBox(width: circleSpacing),
          Column(
            children: [
              for (int i = 0; i < widget.module.outputs.length; i++)
                CircleAvatar(
                  backgroundColor: getColour(
                      widget.module.outputs.values.elementAt(i).value),
                  radius: circleSize / 2,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
