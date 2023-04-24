import 'package:flutter/material.dart';
import 'package:rohd/rohd.dart' as rohd;
import 'component.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const double toolbarIconSize = 48;
const double gridSize = 40;

const bool showToolBar = true;
const bool debug = false;

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
      debugShowCheckedModeBanner: debug,
      title: 'Oz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _showProjectExplorer = false;
  bool _isRunning = false;
  Timer? _simulationTickTimer;

  List<Component> components = [];

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
            if (showToolBar) toolbar(),
            Expanded(
              child: Row(
                children: [
                  projectExplorer(),
                  canvas(),
                  sidebar(),
                ],
              ),
            ),
            if (debug) debugBar(),
          ],
        ),
      ),
    );
  }

  Widget toolbar() {
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
              setState(() {
                components = [];
              });
            },
            child: const Tooltip(
              message: "Reset Canvas",
              child: Icon(Icons.restart_alt_rounded, size: toolbarIconSize),
            ),
          ),
          GestureDetector(
            onTap: () {
              _isRunning ? _stopSimulation() : _startSimulation();
            },
            child: Tooltip(
              message: _isRunning ? "Stop Simulation" : "Run Simultation",
              child: _isRunning
                  ? const Icon(Icons.stop_circle_outlined,
                      size: toolbarIconSize)
                  : const Icon(Icons.play_circle_outline,
                      size: toolbarIconSize),
            ),
          )
        ],
      ),
    );
  }

  Widget projectExplorer() {
    const double iconSize = 50;
    const double padding = 16;
    const double shownWidth = 400;
    const double hiddenWidth = iconSize + padding;

    return SizedBox(
      width: _showProjectExplorer ? shownWidth : hiddenWidth,
      child: Container(
          decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.black))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.folder),
                iconSize: iconSize,
                onPressed: () {
                  setState(() {
                    _showProjectExplorer = !_showProjectExplorer;
                  });
                },
              ),
              if (_showProjectExplorer)
                const Padding(
                  padding: EdgeInsets.all(padding),
                  child: Text(
                    'Project Explorer',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
            ],
          )),
    );
  }

  Widget canvas() {
    return Expanded(
        child: Stack(children: <Widget>[
      GridPaper(
        divisions: 1,
        subdivisions: 1,
        interval: gridSize,
        color: Colors.black12,
        child: Container(),
      ),
      DragTarget<Component>(
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
    const double padding = 16;

    return Container(
        width: 200,
        decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Colors.black))),
        child: Padding(
            padding: const EdgeInsets.all(padding),
            child: ListView(
              children: [
                for (var moduleType in [
                  rohd.Xor2Gate,
                  rohd.Or2Gate,
                  rohd.And2Gate,
                  rohd.NotGate
                ])
                  Draggable(
                    data: Component(
                      moduleType: moduleType,
                    ),
                    feedback: DefaultTextStyle(
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                            decoration: TextDecoration.none),
                        child: ComponentPreview(
                          component: Component(
                            moduleType: moduleType,
                          ),
                        )),
                    childWhenDragging: Text(
                      moduleType.toString(),
                      style: const TextStyle(fontSize: 24, color: Colors.grey),
                    ),
                    child: Text(
                      moduleType.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    onDragEnd: (DraggableDetails details) {
                      dropPosition.value = details.offset;
                    },
                  ),
              ],
            )));
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
