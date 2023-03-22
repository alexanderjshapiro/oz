import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rohd/rohd.dart' as rohd;

var ins = [rohd.Logic(name: 'in0'), rohd.Logic(name: 'in1')];
var xor = rohd.Xor2Gate(ins[0], ins[1]);

void main() async {
  //var clk = rohd.SimpleClockGenerator(100).clk;
  //var not = rohd.NotGate(clk);
  xor.build();
  ins[0].changed.listen((event) {
    debugPrint("in0: $event");
  });
  ins[1].changed.listen((event) {
    debugPrint("in1: $event");
  });
  //await rohd.Simulator.run();
  //xor.out.negedge.listen((event) {_toggleRightCircleColor(0);});
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool _isRunning = false;
  late Timer _timer;

  void _startSimulation() async {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        debugPrint("tick");
        rohd.Simulator.tick();
      });
    });
    /*rohd.Simulator.setMaxSimTime(100);
    await rohd.Simulator.run();
    rohd.Simulator.simulationEnded.then((value) => debugPrint("sim ended"));*/
  }

  void _stopSimulation() {
    _timer.cancel();
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

  const ComponentBox({super.key, 
    this.leftCirclesCount = 1,
    this.rightCirclesCount = 1,
  });

  @override
  ComponentBoxState createState() => ComponentBoxState();
}

class ComponentBoxState extends State<ComponentBox> {
  late List<bool> _isLeftCircleRedList;
  late List<bool> _isRightCircleRedList;

  @override
  void initState() {
    super.initState();
    _isLeftCircleRedList = List.filled(widget.leftCirclesCount, false);
    _isRightCircleRedList = List.filled(widget.rightCirclesCount, false);
    xor.out.posedge.listen((event) {
      _setRightCircleColor(0, true);
    });
    xor.out.negedge.listen((event) {
      _setRightCircleColor(0, false);
    });
  }

  void _toggleLeftCircleColor(int index) {
    setState(() {
      _isLeftCircleRedList[index] = !_isLeftCircleRedList[index];
      debugPrint("toggle element $index");
      ins[index].inject(_isLeftCircleRedList[index]);
      //rohd.Simulator.tick();
    });
  }

  void _setRightCircleColor(int index, bool status) {
    setState(() {
      _isRightCircleRedList[index] = status;
    });
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
                    backgroundColor:
                        _isLeftCircleRedList[i] ? Colors.orange[800] : Colors.deepPurple[900],
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
                  backgroundColor:
                      _isRightCircleRedList[i] ? Colors.orange[800] : Colors.deepPurple[900],
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
