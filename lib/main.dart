import 'package:flutter/material.dart';
import 'package:Oz/logic.dart' as rohd;
import 'package:flutter/services.dart';
import 'component.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'canvas.dart';

const double toolbarIconSize = 48;
const double gridSize = 40;

const bool showToolBar = true;
const bool debug = false;

Duration tickRate = const Duration(milliseconds: 20);

void main() {
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

late GlobalKey<CanvasState>
    canvasKey; // TODO: consider using callback functions instead of GlobalKey

class _MainPageState extends State<MainPage> {
  bool _showProjectExplorer = false;
  bool _isRunning = false;
  Timer? _simulationTickTimer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
    canvasKey = GlobalKey<CanvasState>();
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
                  Canvas(key: canvasKey),
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
                canvasKey.currentState!.clearComponents();
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
          ),
          SizedBox(
            height: toolbarIconSize,
            width: 1.5*toolbarIconSize,
            child: Tooltip(
              message: "Simulation Speed (ms)",
              child: TextFormField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                initialValue: "${tickRate.inMilliseconds}",
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  suffixText: "ms",
                  border: OutlineInputBorder(),
                ),
                onChanged: (String value) {
                  _stopSimulation();
                  int newtick = int.tryParse(value) ?? tickRate.inMilliseconds;
                  tickRate = Duration(milliseconds: newtick);
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _stopSimulation();
              rohd.SimulationUpdater.tick();
            },
            child: const Tooltip(
              message: "Step Simulation",
              child:
                  Icon(Icons.slow_motion_video_rounded, size: toolbarIconSize),
            ),
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
        ),
      ),
    );
  }

  void printScreen() {
    Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final doc = pw.Document();

        final image = await WidgetWrapper.fromKey(key: GlobalKey());

        doc.addPage(
          pw.Page(
            pageFormat: format,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Expanded(
                  child: pw.Image(image),
                ),
              );
            },
          ),
        );
        return doc.save();
      },
    );
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
            for (var moduleType in [
              rohd.Xor2Gate,
              rohd.Or2Gate,
              rohd.And2Gate,
              rohd.NotGate,
              rohd.FlipFlop,
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
                    canvasKey.currentState!.addComponent(
                        Component(moduleType: moduleType),
                        offset: Offset(
                            details.offset.dx - 56,
                            details.offset.dy -
                                48)); // TODO: don't manually define offset's offset
                  });
                },
              ),
          ],
        ),
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
    _simulationTickTimer = Timer.periodic(
      tickRate,
      (timer) {
        rohd.SimulationUpdater.tick();
      },
    );
  }

  void _stopSimulation() {
    _simulationTickTimer?.cancel();
    setState(
      () {
        _isRunning = false;
      },
    );
  }
}
