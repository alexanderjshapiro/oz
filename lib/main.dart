import 'package:flutter/material.dart';
import 'logic.dart';
import 'package:flutter/services.dart';
import 'component.dart';
import 'dart:async';
import 'editor_canvas.dart';
import 'waveform.dart';
import 'package:resizable_widget/resizable_widget.dart';

const double gridSize = 40;

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
        debugPrint('error: $e');
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

late GlobalKey<EditorCanvasState> editorCanvasKey;

late GlobalKey<WaveformAnalyzerState> waveformAnalyzerKey;

class _MainPageState extends State<MainPage> {
  static const double toolbarIconSize = 48.0;

  bool _isRunning = false;
  Timer? _simulationTickTimer;

  final _scrollControllerVertical = ScrollController();
  final _scrollControllerHorizontal = ScrollController();

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
            toolbar(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: ResizableWidget(
                            isHorizontalSeparator: true,
                            separatorSize: 8.0,
                            separatorColor: Colors.black,
                            percentages: const [0.7, 0.3],
                            children: [
                              SingleChildScrollView(
                                controller: _scrollControllerVertical,
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                    controller: _scrollControllerHorizontal,
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                        width: gridSize * 100,
                                        height: gridSize * 100,
                                        child: EditorCanvas(
                                            key: editorCanvasKey))),
                              ),
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
            onPressed: () => setState(
                () => editorCanvasKey.currentState!.mode = CanvasMode.select),
            icon: const Icon(Icons.highlight_alt),
            iconSize: toolbarIconSize,
            tooltip: 'Select Components',
            color: editorCanvasKey.currentState?.mode == CanvasMode.select
                ? Colors.blue
                : null,
          ),
          IconButton(
            onPressed: () => setState(
                () => editorCanvasKey.currentState!.mode = CanvasMode.draw),
            icon: const Icon(Icons.mode),
            iconSize: toolbarIconSize,
            tooltip: 'Draw Wires',
            color: editorCanvasKey.currentState?.mode == CanvasMode.draw
                ? Colors.blue
                : null,
          ),
          IconButton(
            onPressed: () =>
                setState(() => editorCanvasKey.currentState!.removeSelected()),
            icon: const Icon(Icons.delete),
            iconSize: toolbarIconSize,
            tooltip: 'Remove Selected',
          ),
          IconButton(
            onPressed: () => setState(() {
              editorCanvasKey.currentState!.clear();
              currentComponentStates.clear();
              waveformAnalyzerKey.currentState!.clearWaveforms();
              probedPorts.clear();
            }),
            icon: const Icon(Icons.restart_alt),
            iconSize: toolbarIconSize,
            tooltip: 'Reset Canvas',
          ),
          const SizedBox(width: 40),
          IconButton(
            onPressed: () =>
                _isRunning ? _stopSimulation() : _startSimulation(),
            icon: _isRunning
                ? const Icon(Icons.stop_circle_outlined)
                : const Icon(Icons.play_circle_outline),
            iconSize: toolbarIconSize,
            tooltip: _isRunning ? 'Stop Simulation' : 'Run Simulation',
          ),
          SizedBox(
            height: toolbarIconSize,
            width: 1.5 * toolbarIconSize,
            child: Tooltip(
              message: 'Simulation Speed (ms)',
              child: TextFormField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                initialValue: '${tickRate.inMilliseconds}',
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  suffixText: 'ms',
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
            onPressed: () => setState(
                () => editorCanvasKey.currentState!.mode = CanvasMode.addProbe),
            icon: const Icon(Icons.near_me),
            iconSize: toolbarIconSize,
            tooltip: 'Add Port Waveform',
            color: editorCanvasKey.currentState?.mode == CanvasMode.addProbe
                ? Colors.blue
                : null,
          ),
          IconButton(
            onPressed: () => setState(() =>
                editorCanvasKey.currentState!.mode = CanvasMode.removeProbe),
            icon: const Icon(Icons.near_me_disabled),
            iconSize: toolbarIconSize,
            tooltip: 'Remove Port Waveform',
            color: editorCanvasKey.currentState?.mode == CanvasMode.removeProbe
                ? Colors.blue
                : null,
          )
        ],
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
            ExpansionTile(
                title: const Text('Interface',
                    style: TextStyle(
                      fontSize: 24,
                    )),
                collapsedTextColor: Colors.blueGrey,
                children: [
                  for (var moduleType in [BinarySwitch, HexDisplay])
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
                        style:
                            const TextStyle(fontSize: 24, color: Colors.grey),
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
                                  details.offset.dx +
                                      _scrollControllerHorizontal.offset,
                                  details.offset.dy +
                                      _scrollControllerVertical.offset -
                                      toolbarIconSize));
                          for (final component
                              in editorCanvasKey.currentState!.components) {
                            currentComponentStates.putIfAbsent(
                                component['key'], () => LogicValue.zero);
                          }
                        });
                      },
                    ),
                ]),
            ExpansionTile(
                title: const Text('Gates',
                    style: TextStyle(
                      fontSize: 24,
                    )),
                collapsedTextColor: Colors.blueGrey,
                children: [
                  for (var moduleType in [
                    And2Gate,
                    NotGate,
                    Nor2Gate,
                    Xor2Gate,
                    BufferGate,
                    TriStateBuffer,
                    Nand2Gate,
                    Or2Gate,
                    Mux2Gate,
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
                        gateNames[moduleType]!,
                        style:
                            const TextStyle(fontSize: 24, color: Colors.grey),
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
                                  details.offset.dx +
                                      _scrollControllerHorizontal.offset,
                                  details.offset.dy +
                                      _scrollControllerVertical.offset -
                                      toolbarIconSize));
                          for (final component
                              in editorCanvasKey.currentState!.components) {
                            currentComponentStates.putIfAbsent(
                                component['key'], () => LogicValue.zero);
                          }
                        });
                      },
                    ),
                ]),
            ExpansionTile(
                title: const Text('ICs',
                    style: TextStyle(
                      fontSize: 24,
                    )),
                collapsedTextColor: Colors.blueGrey,
                children: [
                  for (var moduleType in [SN74LS245, SN74LS373, SN74LS138, SRAM6116])
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
                        style:
                            const TextStyle(fontSize: 24, color: Colors.grey),
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
                                  details.offset.dx +
                                      _scrollControllerHorizontal.offset,
                                  details.offset.dy +
                                      _scrollControllerVertical.offset -
                                      toolbarIconSize));
                          for (final component
                              in editorCanvasKey.currentState!.components) {
                            currentComponentStates.putIfAbsent(
                                component['key'], () => LogicValue.zero);
                          }
                        });
                      },
                    ),
                ]),
            ExpansionTile(
                title: const Text('All Gates',
                    style: TextStyle(
                      fontSize: 24,
                    )),
                collapsedTextColor: Colors.blueGrey,
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
                        style:
                            const TextStyle(fontSize: 24, color: Colors.grey),
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
                                  details.offset.dx +
                                      _scrollControllerHorizontal.offset,
                                  details.offset.dy +
                                      _scrollControllerVertical.offset -
                                      toolbarIconSize));
                          for (final component
                              in editorCanvasKey.currentState!.components) {
                            currentComponentStates.putIfAbsent(
                                component['key'], () => LogicValue.zero);
                          }
                        });
                      },
                    ),
                ]),
          ],
        ),
      ),
    );
  }

  void _startSimulation() {
    setState(() => _isRunning = true);

    // Setup a timer to repeatedly call Simulator.tick();
    _simulationTickTimer = Timer.periodic(
      tickRate,
      (_) => SimulationUpdater.tick(),
    );
  }

  void _stopSimulation() {
    _simulationTickTimer?.cancel();
    setState(() => _isRunning = false);
  }
}
