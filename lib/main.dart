import 'package:flutter/material.dart';
import 'package:rohd/rohd.dart' as rohd;
import 'component.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'editor_canvas.dart';

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

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Oz',
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<EditorCanvasState> _editorCanvasKey = GlobalKey<
      EditorCanvasState>(); // TODO: consider using callback functions instead of GlobalKey

  bool _showProjectExplorer = false;
  bool _isRunning = false;
  Timer? _simulationTickTimer;

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
                  EditorCanvas(key: _editorCanvasKey),
                  componentList(),
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
          IconButton(
            onPressed: () {
              setState(() {
                _editorCanvasKey.currentState!.mode = 'select';
              });
            },
            icon: const Icon(Icons.highlight_alt),
            iconSize: toolbarIconSize,
            tooltip: 'Select Components',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _editorCanvasKey.currentState!.mode = 'draw';
              });
            },
            icon: const Icon(Icons.mode),
            iconSize: toolbarIconSize,
            tooltip: 'Draw Wires',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _editorCanvasKey.currentState!.removeSelectedComponents();
              });
            },
            icon: const Icon(Icons.delete),
            iconSize: toolbarIconSize,
            tooltip: 'Delete',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _editorCanvasKey.currentState!.clear();
              });
            },
            icon: const Icon(Icons.restart_alt),
            iconSize: toolbarIconSize,
            tooltip: 'Reset Canvas',
          ),
          IconButton(
            onPressed: () {
              _isRunning ? _stopSimulation() : _startSimulation();
            },
            icon: _isRunning
                ? const Icon(
                    Icons.stop_circle_outlined,
                  )
                : const Icon(
                    Icons.play_circle_outline,
                  ),
            iconSize: toolbarIconSize,
            tooltip: _isRunning ? 'Stop Simulation' : 'Run Simulation',
          ),
          IconButton(
            onPressed: () {
              printScreen();
            },
            icon: const Icon(Icons.print),
            iconSize: toolbarIconSize,
            tooltip: 'Print Screen',
          ),
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

  Widget componentList() {
    const double padding = 16;

    return Container(
        width: 200,
        decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Colors.black))),
        child: Padding(
            padding: const EdgeInsets.all(padding),
            child: ListView(
              children: [
                for (final Type moduleType in [
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
                    onDragUpdate: (details) {
                      setState(() {});
                    },
                    onDragEnd: (DraggableDetails details) {
                      setState(() {
                        _editorCanvasKey.currentState!.addComponent(
                            Component(moduleType: moduleType),
                            offset: Offset(
                                details.offset.dx - 56,
                                details.offset.dy -
                                    48)); // TODO: don't manually define offset's offset
                      });
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
