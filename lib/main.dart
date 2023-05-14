import 'package:flutter/material.dart';
import 'logic.dart';
import 'package:flutter/services.dart';
import 'component.dart';
import 'dart:async';
import 'editor_canvas.dart';
import 'waveform.dart';
import 'package:resizable_widget/resizable_widget.dart';
import 'package:flutter/foundation.dart';

const double gridSize = 40;
var colorMode = false;

const Color spartanBlue = Color.fromRGBO(0, 85, 162, 1);
const Color spartanYellow = Color.fromRGBO(229, 168, 35, 1);
const Color spartanGrayLight = Color.fromRGBO(147, 149, 151, 1);
const Color spartanGrayDark = Color.fromRGBO(83, 86, 90, 1);

Duration tickRate = const Duration(milliseconds: 1);

Map<GlobalKey<ComponentState>, LogicValue> currentComponentStates = {};
Map<GlobalKey<ComponentState>, PhysicalPort> probedPorts = {};
final FocusNode globalFocus = FocusNode();
final FocusNode timerFocus = FocusNode();

void main() {
  // If we get an uncaught exception during the program in release build the program just restarts.
  if (!kDebugMode) {
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
    return MaterialApp(
      title: 'Oz',
      theme: ThemeData(
        colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: spartanBlue,
            onPrimary: Colors.white,
            secondary: spartanYellow,
            onSecondary: Colors.black,
            error: Colors.red,
            onError: Colors.white,
            background: Colors.white,
            onBackground: Colors.black,
            surface: Colors.white,
            onSurface: Colors.black),
      ),
      home: const MainPage(),
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
  static const double toolbarHeight = toolbarIconSize * 1.5;

  bool _isRunning = false;
  Timer? _simulationTickTimer;

  bool _componentListShown = true;
  bool _componentListPreviewMode = false;

  final _scrollControllerVertical = ScrollController();
  final _scrollControllerHorizontal = ScrollController();

  @override
  void initState() {
    super.initState();
    _startSimulation();
    editorCanvasKey = GlobalKey<EditorCanvasState>();
    waveformAnalyzerKey = GlobalKey<WaveformAnalyzerState>();
    _scrollControllerHorizontal.addListener(() {
      if (_scrollControllerHorizontal.position.pixels ==
          _scrollControllerHorizontal.position.maxScrollExtent) {
        editorCanvasKey.currentState?.setState(() {
          editorCanvasKey.currentState?.tilingHorizontal += 1;
        });
      }
    });
    _scrollControllerVertical.addListener(() {
      if (_scrollControllerVertical.position.pixels ==
          _scrollControllerVertical.position.maxScrollExtent) {
        editorCanvasKey.currentState?.setState(() {
          editorCanvasKey.currentState?.tilingVertical += 1;
        });
      }
    });
    timerFocus.addListener(() {
      if (!timerFocus.hasFocus) {
        globalFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget canvas = Scrollbar(
      thumbVisibility: true,
      controller: _scrollControllerVertical,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {}),
        child: SingleChildScrollView(
          controller: _scrollControllerVertical,
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.top,
            controller: _scrollControllerHorizontal,
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(dragDevices: {}),
              child: SingleChildScrollView(
                  controller: _scrollControllerHorizontal,
                  scrollDirection: Axis.horizontal,
                  child: EditorCanvas(key: editorCanvasKey)),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
        appBar: appBar(),
        body: Container(
          color: Colors.white,
          child: Row(
            children: [
              RawKeyboardListener(
                  focusNode: globalFocus,
                  onKey: (RawKeyEvent event) {
                    if (event is RawKeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.keyD &&
                        !event.data.isControlPressed) {
                      setState(() {
                        editorCanvasKey.currentState?.deselectSelected();
                        editorCanvasKey.currentState!.mode = CanvasMode.draw;
                      });
                    } else if (event is RawKeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.keyS &&
                        !event.data.isControlPressed) {
                      setState(() => editorCanvasKey.currentState!.mode =
                          CanvasMode.select);
                    } else if (event is RawKeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.keyP &&
                        !event.data.isControlPressed) {
                      setState(() => editorCanvasKey.currentState!.mode =
                          CanvasMode.addProbe);
                    } else if (event is RawKeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.keyC &&
                        !event.data.isControlPressed) {
                      setState(() => colorMode = !colorMode);
                    }
                  },
                  child: Container()),
              Expanded(
                child: ResizableWidget(
                  isHorizontalSeparator: true,
                  separatorSize: 8.0,
                  separatorColor: Colors.black,
                  percentages: const [0.7, 0.3],
                  children: [
                    canvas,
                    WaveformAnalyzer(key: waveformAnalyzerKey),
                  ],
                ),
              ),
              if (_componentListShown) componentList(),
            ],
          ),
        ));
  }

  AppBar appBar() {
    return AppBar(
      toolbarHeight: toolbarHeight,
      actions: [
        IconButton(
          onPressed: () => setState(
              () => editorCanvasKey.currentState!.mode = CanvasMode.select),
          icon: const Icon(Icons.highlight_alt),
          iconSize: toolbarIconSize,
          tooltip: 'Select',
          color: editorCanvasKey.currentState?.mode == CanvasMode.select
              ? spartanYellow
              : null,
        ),
        IconButton(
          onPressed: () => setState(() {
            editorCanvasKey.currentState?.deselectSelected();
            editorCanvasKey.currentState!.mode = CanvasMode.draw;
          }),
          icon: const Icon(Icons.mode),
          iconSize: toolbarIconSize,
          tooltip: 'Draw Wires',
          color: editorCanvasKey.currentState?.mode == CanvasMode.draw
              ? spartanYellow
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
            _scrollControllerHorizontal.jumpTo(0);
            _scrollControllerVertical.jumpTo(0);
            editorCanvasKey.currentState!.clear();
            currentComponentStates.clear();
            waveformAnalyzerKey.currentState!.clearWaveforms();
            probedPorts.clear();
          }),
          icon: const Icon(Icons.restart_alt),
          iconSize: toolbarIconSize,
          tooltip: 'Reset Canvas',
        ),
        const SizedBox(width: toolbarIconSize),
        IconButton(
          onPressed: () => _isRunning ? _stopSimulation() : _startSimulation(),
          icon: Icon(_isRunning
              ? Icons.pause_circle_outline
              : Icons.play_circle_outline),
          iconSize: toolbarIconSize,
          tooltip: '${_isRunning ? 'Pause' : 'Start'} Simulation',
        ),
        SizedBox(
          width: toolbarIconSize * 2,
          child: Center(
            child: Tooltip(
              message: 'Simulation Speed (ms)',
              child: TextFormField(
                focusNode: timerFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                initialValue: '${tickRate.inMilliseconds}',
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 18, fontFamily: 'Courier New'),
                decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    suffixText: 'ms',
                    border: InputBorder.none),
                onChanged: (String value) {
                  _stopSimulation();
                  int newtick = int.tryParse(value) ?? tickRate.inMilliseconds;
                  tickRate = Duration(milliseconds: newtick);
                },
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            _stopSimulation();
            SimulationUpdater.tick();
          },
          icon: const Icon(Icons.slow_motion_video),
          iconSize: toolbarIconSize,
          tooltip: 'Step Simulation',
        ),
        const SizedBox(width: toolbarIconSize),
        IconButton(
          onPressed: () => setState(
              () => editorCanvasKey.currentState!.mode = CanvasMode.addProbe),
          icon: const Icon(Icons.near_me),
          iconSize: toolbarIconSize,
          tooltip: 'Add Port Waveform',
          color: editorCanvasKey.currentState?.mode == CanvasMode.addProbe
              ? spartanYellow
              : null,
        ),
        IconButton(
          onPressed: () => setState(() =>
              editorCanvasKey.currentState!.mode = CanvasMode.removeProbe),
          icon: const Icon(Icons.near_me_disabled),
          iconSize: toolbarIconSize,
          tooltip: 'Remove Port Waveform',
          color: editorCanvasKey.currentState?.mode == CanvasMode.removeProbe
              ? spartanYellow
              : null,
        ),
        const Spacer(),
        IconButton(
          onPressed: () => setState(() => colorMode = !colorMode),
          icon: const Icon(Icons.color_lens),
          iconSize: toolbarIconSize,
          tooltip: 'Color Mode',
          color: colorMode ? spartanYellow : null,
        ),
        IconButton(
          onPressed: () => setState(
              () => _componentListPreviewMode = !_componentListPreviewMode),
          icon: const Icon(Icons.preview),
          iconSize: toolbarIconSize,
          tooltip: 'Component Preview Mode',
          color: _componentListPreviewMode ? spartanYellow : null,
        ),
        IconButton(
          onPressed: () =>
              setState(() => _componentListShown = !_componentListShown),
          icon: const Icon(Icons.view_sidebar),
          iconSize: toolbarIconSize,
          tooltip: '${_componentListShown ? 'Hide' : 'Show'} Component List',
          color: _componentListShown ? spartanYellow : null,
        ),
      ],
    );
  }

  Widget componentList() {
    const double padding = 0;
    final ScrollController scrollController = ScrollController();

    Map<Type, Widget> components = {};
    for (var moduleType in gateNames.keys) {
      components[moduleType] = Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: Draggable(
          data: Component(
            moduleType: moduleType,
          ),
          feedback: DefaultTextStyle(
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.normal,
                decoration: TextDecoration.none),
            child: Component(
              moduleType: moduleType,
            ),
          ),
          childWhenDragging: _componentListPreviewMode
              ? Opacity(
                  opacity: 0.2,
                  child: DefaultTextStyle(
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none),
                    child: Component(
                      moduleType: moduleType,
                    ),
                  ),
                )
              : Text(
                  gateNames[moduleType]!,
                  style: const TextStyle(fontSize: 24, color: Colors.grey),
                ),
          child: _componentListPreviewMode
              ? DefaultTextStyle(
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none),
                  child: Component(
                    moduleType: moduleType,
                  ),
                )
              : Text(
                  gateNames[moduleType]!,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
          onDragEnd: (DraggableDetails details) {
            setState(() {
              editorCanvasKey.currentState!.addComponent(moduleType,
                  offset: Offset(
                      details.offset.dx + _scrollControllerHorizontal.offset,
                      details.offset.dy +
                          _scrollControllerVertical.offset -
                          (editorCanvasKey.currentContext?.findRenderObject()
                                  as RenderBox)
                              .localToGlobal(Offset.zero)
                              .dy));
              for (final component
                  in editorCanvasKey.currentState!.components) {
                currentComponentStates.putIfAbsent(
                    component['key'], () => LogicValue.zero);
              }
            });
          },
        ),
      );
    }

    Map<String, List<Type>> tiles = {
      'Interface': [BinarySwitch, LightBulb, HexDisplay],
      'Gates': [
        And2Gate,
        NotGate,
        Nor2Gate,
        Xor2Gate,
        BufferGate,
        TriStateBuffer,
        Nand2Gate,
        Or2Gate,
        Mux2Gate,
      ],
      'ICs': [SN74LS245, SN74LS373, SN74LS138, SRAM6116],
      'All Gates': gateNames.keys.toList(),
    };

    return Container(
      width: gridSize * 9,
      decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Colors.black))),
      padding: const EdgeInsets.all(padding),
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        controller: scrollController,
        child: ListView(
          controller: scrollController,
          children: [
            for (String tileName in tiles.keys)
              ExpansionTile(
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedAlignment: Alignment.topLeft,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(tileName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  collapsedTextColor: Colors.blueGrey,
                  children: [
                    for (var moduleType in tiles[tileName]!)
                      components[moduleType]!
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
