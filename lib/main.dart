import 'package:flutter/material.dart';
import 'package:rohd/rohd.dart' as rohd;
import 'component.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


const double toolbarIconSize = 48;
const double gridSize = 20;

const bool showToolBar = true;
const bool showDebugBar = false;

const Duration tickRate = Duration(milliseconds: 50);

void main() {
  rohd.SimpleClockGenerator(2);
  runApp(const Oz());
}

class Oz extends StatelessWidget {
  const Oz({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isRunning = false;
  Timer? _simulationTickTimer;

  List<ComponentBox> components = [];
  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            if (showToolBar) toolBar(),
            Expanded(
              child: Row(
                children: [
                  workSpace(),
                  sidebar(),
                ],
              ),
            ),
            if (showDebugBar) debugBar(),
          ],
        ),
      ),
    );
  }

  Widget workSpace() {
    return Expanded(
        child: Stack(children: <Widget>[
      GridPaper(
        divisions: 1,
        subdivisions: 1,
        interval: gridSize,
        color: Colors.black12,
        child: Container(),
      ),
      DragTarget<ComponentBox>(
        builder: (BuildContext context, List candidate, List rejected) {
          return Stack(children: components);
        },
        onWillAccept: (data) {
          return true;
        },
        onAccept: (data) {
          setState(() {
            components.add(data);
          });
        },
      )
    ]));
  }

  Widget toolBar() {
    return Container(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black))),
      child: Row(
        children: [
          const Icon(Icons.save, size: toolbarIconSize),
          GestureDetector(
            onTap: () {
              printScreen();
            },
            child: const Icon(Icons.print, size: toolbarIconSize),
          ),
          GestureDetector(
            onTap: () {
              _isRunning ? _stopSimulation() : _startSimulation();
            },
            child: _isRunning
                ? const Icon(Icons.stop_circle_outlined, size: toolbarIconSize)
                : const Icon(Icons.play_circle_outline, size: toolbarIconSize),
          )
        ],
      ),
    );
  }

void printScreen() {
    Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
      final doc = pw.Document();

      final image = await WidgetWrapper.fromKey(key: GlobalKey()); 

      doc.addPage(pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Expanded(
                child: pw.Image(image),
              ),
            );
          }));

      return doc.save();
    });
  }


  Widget sidebar() {
    return Container(
      width: 100,
      color: Colors.brown[100],
      child: ListView.builder(
        itemCount: sidebarWidgets.length,
        itemBuilder: (BuildContext context, int index) {
          return sidebarWidgets[index];
        },

      ),
    );
  }

  Widget debugBar() {
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black))),
      child: Row(
        children: [
          const Text('Status:'),
          const Spacer(),
          Text('Last State Update: ${DateTime.now()}')
        ],
      ),
    );
  }

  void _startSimulation() {
    setState(() {
      _isRunning = true;
    });
    //Setup a timer to repeatibly call Simulator.tick();
    // Simulator.run() would probably be better, but I cant't get to work without freezing flutter
    _simulationTickTimer = Timer.periodic(tickRate, (timer) {
      rohd.Simulator.tick();
    });
  }

  void _stopSimulation() {
    _simulationTickTimer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }
}

ValueNotifier<Offset> dropPosition = ValueNotifier(Offset.zero);

List<Draggable> sidebarWidgets = [
  // XOR
  Draggable(
    data: ComponentBox(
      module: rohd.Xor2Gate(rohd.Logic(), rohd.Logic()),
    ),
    feedback: ComponentBox(
      module: rohd.Xor2Gate(rohd.Logic(), rohd.Logic()),
    ),
    childWhenDragging: Container(
      width: 100,
      height: 50,
      color: Colors.redAccent,
      child: const Center(
        child: Text(
          'XOR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
    child: Container(
      width: 100,
      height: 50,
      color: Colors.red,
      child: const Center(
        child: Text(
          'XOR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
    onDragEnd: (DraggableDetails details) {
      dropPosition.value = details.offset;
    },
  ),

  // And
  Draggable(
    data: ComponentBox(
      module: rohd.And2Gate(rohd.Logic(), rohd.Logic()),
    ),
    feedback: ComponentBox(
      module: rohd.And2Gate(rohd.Logic(), rohd.Logic()),
    ),
    childWhenDragging: Container(
      width: 100,
      height: 50,
      color: Colors.redAccent,
      child: const Center(
        child: Text(
          'AND',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
    child: Container(
      width: 100,
      height: 50,
      color: Colors.red,
      child: const Center(
        child: Text(
          'AND',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
    onDragEnd: (DraggableDetails details) {
      dropPosition.value = details.offset;
    },
  ),

  //Flip Flop
  Draggable(
    data: ComponentBox(
      module: rohd.FlipFlop(rohd.SimpleClockGenerator(60).clk, rohd.Logic()),
    ),
    feedback: ComponentBox(
      module: rohd.FlipFlop(rohd.Logic(), rohd.Logic()),
    ),
    childWhenDragging: Container(
      width: 100,
      height: 50,
      color: Colors.redAccent,
      child: const Center(
        child: Text(
          'FlipFlop',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
    child: Container(
      width: 100,
      height: 50,
      color: Colors.red,
      child: const Center(
        child: Text(
          'FlipFlop',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
    onDragEnd: (DraggableDetails details) {
      dropPosition.value = details.offset;
    },
  ),
];
