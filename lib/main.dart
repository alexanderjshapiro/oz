import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rohd/rohd.dart' as rohd;

var ins = [rohd.Logic(name: 'in0'), rohd.Logic(name: 'in1')];
var xor = rohd.Xor2Gate(ins[0], ins[1]);

void main() {
  //var clk = rohd.SimpleClockGenerator(100).clk;
  //var not = rohd.NotGate(clk);
  xor.build();
  ins[0].changed.listen((event) {
    debugPrint("in0: $event");
  });
  ins[1].changed.listen((event) {
    debugPrint("in1: $event");
  });
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

  void _startSimulation() {
    setState(() {
      _isRunning = true;
    });
    //Setup a timer to repeatibly call Simulator.tick();
    // Simulator.run() would probably be better, but I cant't get to work without freezing flutter
    _simulationTickTimer =
        Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        debugPrint("tick");
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
              const ComponentBox(
                leftCirclesCount: 2,
                rightCirclesCount: 1,
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
  final int leftCirclesCount;
  final int rightCirclesCount;

  const ComponentBox({
    super.key,
    this.leftCirclesCount = 1,
    this.rightCirclesCount = 1,
  });

  @override
  ComponentBoxState createState() => ComponentBoxState();
}

class ComponentBoxState extends State<ComponentBox> {
  late List<rohd.LogicValue> _inputCircleValList;
  late List<rohd.LogicValue> _outputCircleValList;

  @override
  void initState() {
    super.initState();
    _outputCircleValList =
        List.filled(widget.rightCirclesCount, rohd.LogicValue.x);
    _inputCircleValList =
        List.filled(widget.leftCirclesCount, rohd.LogicValue.z);

    //Create a callback whenever the component outputs change.
    xor.out.changed.listen((event) {
      _setRightCircleColor(0, event.newValue);
    });
  }

  void _toggleLeftCircleColor(int index) {
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
      ins[index].inject(_inputCircleValList[index]);
    });
  }

  void _setRightCircleColor(int index, rohd.LogicValue status) {
    setState(() {
      _outputCircleValList[index] = status;
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

    double boxWidth = (circleSize * 2) +
        (paddingSize * 3) +
        (widget.leftCirclesCount + widget.rightCirclesCount - 2) * paddingSize;

    double boxHeight = circleSize * widget.leftCirclesCount +
        paddingSize * (widget.leftCirclesCount - 1) +
        10;

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
              for (int i = 0; i < widget.leftCirclesCount; i++)
                GestureDetector(
                  onTap: () => _toggleLeftCircleColor(i),
                  child: CircleAvatar(
                    backgroundColor: getColour(_inputCircleValList[i]),
                    radius: circleSize / 2,
                  ),
                ),
            ],
          ),
          SizedBox(width: paddingSize),
          Column(
            children: [
              for (int i = 0; i < widget.rightCirclesCount; i++)
                CircleAvatar(
                  backgroundColor: getColour(_outputCircleValList[i]),
                  radius: circleSize / 2,
                ),
              SizedBox(height: paddingSize),
            ],
          ),
        ],
      ),
    );
  }
}
