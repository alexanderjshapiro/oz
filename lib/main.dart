import 'package:flutter/material.dart';
import 'logic.dart';
import 'package:flutter/services.dart';
import 'component.dart';
import 'dart:async';
import 'editor_canvas.dart';
import 'waveform.dart';
import 'package:resizable_widget/resizable_widget.dart';

const double toolbarIconSize = 48;
const double gridSize = 40;

const bool showToolBar = true;
const bool debug = false;

Duration tickRate = const Duration(milliseconds: 1);

Map<GlobalKey<ComponentState>, LogicValue> currentComponentStates = {};
Map<GlobalKey<ComponentState>, PhysicalPort> probedPorts = {};

void main() {
  // TODO: Enable this code section as a fail safe
  // If we get an error the program just restarts.
  // ignore: dead_code
  if (false) {
    bool goodExit = false;
    while (!goodExit) {
      try {
        runApp(const Oz());
        goodExit = true;
      } catch (e) {
        debugPrint("error: $e");
      }
    }
  } else {
    runApp(const Oz());
  }
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

late GlobalKey<EditorCanvasState>
    editorCanvasKey; // TODO: consider using callback functions instead of GlobalKey

late GlobalKey<WaveformAnalyzerState> waveformAnalyzerKey;

class _MainPageState extends State<MainPage> {
  bool _showProjectExplorer = false;
  bool _isRunning = false;
  Timer? _simulationTickTimer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
    editorCanvasKey = GlobalKey<EditorCanvasState>();
    waveformAnalyzerKey = GlobalKey<WaveformAnalyzerState>();
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
                  Expanded(
                    child: Row(
                      children: [
                        projectExplorer(),
                        Expanded(
                          child: ResizableWidget(
                            isHorizontalSeparator: true,
                            separatorSize: 4,
                            separatorColor: Colors.black,
                            percentages: const [0.7, 0.3],
                            children: [
                              EditorCanvas(key: editorCanvasKey),
                              WaveformAnalyzer(key: waveformAnalyzerKey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                editorCanvasKey.currentState!.mode = 'select';
              });
            },
            icon: const Icon(Icons.highlight_alt),
            iconSize: toolbarIconSize,
            tooltip: 'Select Components',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                editorCanvasKey.currentState!.mode = 'draw';
              });
            },
            icon: const Icon(Icons.mode),
            iconSize: toolbarIconSize,
            tooltip: 'Draw Wires',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                editorCanvasKey.currentState!.removeSelected();
              });
            },
            icon: const Icon(Icons.delete),
            iconSize: toolbarIconSize,
            tooltip: 'Remove Selected',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                editorCanvasKey.currentState!.clear();
                currentComponentStates.clear();
                waveformAnalyzerKey.currentState!.clearWaveforms();
                probedPorts.clear();
              });
            },
            icon: const Icon(Icons.restart_alt),
            iconSize: toolbarIconSize,
            tooltip: 'Reset Canvas',
          ),
          const SizedBox(width: 40),
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
          SizedBox(
            height: toolbarIconSize,
            width: 1.5 * toolbarIconSize,
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
          IconButton(
            onPressed: () {
              _stopSimulation();
              SimulationUpdater.tick();
            },
            icon: const Icon(Icons.slow_motion_video_rounded),
            iconSize: toolbarIconSize,
            tooltip: 'Step Simulation',
          ),
          const SizedBox(width: 40),
          IconButton(
            onPressed: () {
              setState(() {
                editorCanvasKey.currentState!.mode = 'Probe Port';
              });
            },
            icon: const Icon(Icons.near_me),
            iconSize: toolbarIconSize,
            tooltip: 'Add Port Waveform',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                editorCanvasKey.currentState!.mode = 'Remove Probe';
              });
            },
            icon: const Icon(Icons.near_me_disabled),
            iconSize: toolbarIconSize,
            tooltip: 'Remove Port Waveform',
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
        ),
      ),
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
            for (var moduleType in gateNames.keys)
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
                  gateNames[moduleType]!,
                  style: const TextStyle(fontSize: 24, color: Colors.grey),
                ),
                child: Text(
                  gateNames[moduleType]!,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
                onDragEnd: (DraggableDetails details) {
                  setState(() {
                    editorCanvasKey.currentState!.addComponent(moduleType,
                        offset: Offset(
                            details.offset.dx - 56,
                            details.offset.dy -
                                48)); // TODO: don't manually define offset's offset
                    editorCanvasKey.currentState!
                        .getComponents()
                        .forEach((key, value) {
                      currentComponentStates.putIfAbsent(
                          key, () => LogicValue.zero);
                    });
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
        SimulationUpdater.tick();
        debugPrint("help");
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
