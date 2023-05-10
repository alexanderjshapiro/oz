import 'package:flutter/material.dart';
import 'component.dart';
import 'logic.dart';
import 'main.dart';

class EditorCanvas extends StatefulWidget {
  const EditorCanvas({Key? key}) : super(key: key);

  @override
  EditorCanvasState createState() => EditorCanvasState();
}

class EditorCanvasState extends State<EditorCanvas> {
  static const double selectedComponentBorderWidth = 1.0;

  String mode = 'select';

  final Map<GlobalKey<ComponentState>, Component> _components = {};
  final Map<GlobalKey<ComponentState>, Offset> _componentPositions = {};
  GlobalKey<ComponentState>? _selectedComponentKey;

  final List<List<Offset>> _wires = [];
  int _wireIndex = -1;
  bool validWireStart = false;
  Node? wiringNodeSelected;

  Map<GlobalKey<ComponentState>, Component> getComponents() => _components;

  void addComponent(Type moduleType, {Offset offset = Offset.zero}) {
    GlobalKey<ComponentState> componentKey = GlobalKey<ComponentState>();
    Component component = Component(
      moduleType: moduleType,
      key: componentKey,
    );
    setState(() {
      _components[componentKey] = component;
      _componentPositions[componentKey] = _snapToGrid(offset);
    });
  }

  void _removeComponent(GlobalKey<ComponentState> componentKey) {
    setState(() {
      _components.remove(componentKey);
      _componentPositions.remove(componentKey);
    });
  }

  void removeSelectedComponents() {
    if (_selectedComponentKey != null) {
      _removeComponent(_selectedComponentKey!);
      _selectedComponentKey = null;
    }
  }

  void clear() {
    setState(() {
      _components.clear();
      _componentPositions.clear();
      _selectedComponentKey = null;
      _wires.clear();
      _wireIndex = -1;
    });
  }

  void updateComponentPosition(
      GlobalKey<ComponentState> componentKey, Offset offset) {
    double dx = _componentPositions[componentKey]!.dx + offset.dx;
    double dy = _componentPositions[componentKey]!.dy + offset.dy;

    setState(() {
      _componentPositions[componentKey] = Offset(dx, dy);
    });
  }

  static Offset _snapToGrid(Offset offset) {
    double dx = (offset.dx / gridSize).round() * gridSize;
    double dy = (offset.dy / gridSize).round() * gridSize;
    return Offset(dx, dy);
  }

  Map<GlobalKey<ComponentState>, List<PhysicalPort>> getOutPorts() {
    Map<GlobalKey<ComponentState>, List<PhysicalPort>> keyOutPortsMap = {};

    // Get all the ports for each component key
    _components.forEach((key, value) {
      if (key.currentState != null && key.currentState!.module.ports.any((element) => element.portName.contains("Out"))) keyOutPortsMap[key] = key.currentState!.module.ports;
    });
    return keyOutPortsMap;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Stack(children: [
      GridPaper(
        divisions: 1,
        subdivisions: 1,
        interval: gridSize,
        color: Colors.black12,
        child: Container(),
      ),
      Stack(children: [
        for (final GlobalKey<ComponentState> componentKey in _components.keys)
          Positioned(
            left: _snapToGrid(_componentPositions[componentKey]!).dx -
                (_selectedComponentKey == componentKey
                    ? selectedComponentBorderWidth
                    : 0),
            top: _snapToGrid(_componentPositions[componentKey]!).dy -
                (_selectedComponentKey == componentKey
                    ? selectedComponentBorderWidth
                    : 0),
            child: GestureDetector(
                onTap: () {
                  // check if component is already selected
                  if (_selectedComponentKey == componentKey) {
                    setState(() {
                      _selectedComponentKey = null;
                    });
                  } else {
                    setState(() {
                      _selectedComponentKey = componentKey;
                    });
                  }
                },
                onPanStart: (_) {
                  // check if component is already selected
                  _selectedComponentKey = componentKey;
                },
                onPanUpdate: (details) {
                  updateComponentPosition(
                      _selectedComponentKey!, details.delta);
                },
                onPanEnd: (_) {
                  _componentPositions[_selectedComponentKey!] =
                      _snapToGrid(_componentPositions[_selectedComponentKey]!);
                },
                child: Container(
                    decoration: _selectedComponentKey == componentKey
                        ? BoxDecoration(
                            border: Border.all(
                                width: selectedComponentBorderWidth,
                                color: Colors.blue))
                        : null,
                    child: _components[componentKey]!)),
          )
      ]),
      CustomPaint(
        painter: MyPainter(
          wires: _wires,
        ),
        child: mode == 'draw'
            ? GestureDetector(
                onPanStart: (details) {
                  Offset startOffset = _snapToGrid(Offset(
                      details.localPosition.dx, details.localPosition.dy));

                  for (final GlobalKey<ComponentState> componentKey
                      in _components.keys) {
                    ComponentState componentState = componentKey.currentState!;
                    Offset componentOffset = _componentPositions[componentKey]!;
                    List<Offset> rightSideOffsets = [
                      for (int i = 0;
                          i < componentState.module.rightSide.length;
                          i++)
                        Offset(componentOffset.dx + componentState.width,
                            componentOffset.dy + (gridSize * (i + 2)))
                    ];
                    List<Offset> leftSideOffsets = [
                      for (int i = 0;
                          i < componentState.module.leftSide.length;
                          i++)
                        Offset(componentOffset.dx,
                            componentOffset.dy + (gridSize * (i + 2)))
                    ];

                    if (rightSideOffsets.contains(startOffset)) {
                      setState(() {
                        validWireStart = true;
                        _wireIndex++;
                        _wires.add([startOffset]);
                      });
                      wiringNodeSelected = componentState.module.rightSide
                          .elementAt(rightSideOffsets.indexOf(startOffset))
                          .connectedNode;
                      return;
                    } else if (leftSideOffsets.contains(startOffset)) {
                      setState(() {
                        validWireStart = true;
                        _wireIndex++;
                        _wires.add([startOffset]);
                      });
                      wiringNodeSelected = componentState.module.leftSide
                          .elementAt(leftSideOffsets.indexOf(startOffset))
                          .connectedNode;
                      return;
                    }
                  }
                },
                onPanUpdate: (details) {
                  if (validWireStart) {
                    setState(() {
                      Offset offset = _snapToGrid(Offset(
                          details.localPosition.dx, details.localPosition.dy));
                      if (offset != _wires[_wireIndex].last) {
                        _wires[_wireIndex].add(offset);
                      }
                    });
                  }
                },
                onPanEnd: (_) {
                  if (validWireStart) {
                    for (int i = 0; i < _wires.length; i++) {
                      if (_wires[i].last == _wires[_wireIndex].first) {
                        _wires[i] = _wires[i] + _wires[_wireIndex].sublist(1);
                        _wires.removeAt(_wireIndex);
                        _wireIndex--;
                      } else if (_wires[_wireIndex].last == _wires[i].first) {
                        _wires[i] = _wires[_wireIndex] + _wires[i].sublist(1);
                        _wires.removeAt(_wireIndex);
                        _wireIndex--;
                      }
                    }
                    validWireStart = false;

                    Offset endOffset = _wires[_wireIndex].last;

                    for (final GlobalKey<ComponentState> componentKey
                        in _components.keys) {
                      ComponentState componentState =
                          componentKey.currentState!;
                      Offset componentOffset =
                          _componentPositions[componentKey]!;
                      List<Offset> rightSideOffsets = [
                        for (int i = 0;
                            i < componentState.module.rightSide.length;
                            i++)
                          Offset(componentOffset.dx + componentState.width,
                              componentOffset.dy + (gridSize * (i + 2)))
                      ];
                      List<Offset> leftSideOffsets = [
                        for (int i = 0;
                            i < componentState.module.leftSide.length;
                            i++)
                          Offset(componentOffset.dx,
                              componentOffset.dy + (gridSize * (i + 2)))
                      ];
                      if (leftSideOffsets.contains(endOffset)) {
                        componentState.module.leftSide
                            .elementAt(leftSideOffsets.indexOf(endOffset))
                            .connectNode(wiringNodeSelected!);
                        return;
                      } else if (rightSideOffsets.contains(endOffset)) {
                        componentState.module.rightSide
                            .elementAt(rightSideOffsets.indexOf(endOffset))
                            .connectNode(wiringNodeSelected!);
                        return;
                      }
                    }
                  }
                },
              )
            : null,
      ),
    mode == "Probe Port"
      ? GestureDetector(
        onTapUp: (TapUpDetails details) {
          // Get the position of where you click and snap to the grid
          Offset tapOffset = _snapToGrid(Offset(
                      details.localPosition.dx, details.localPosition.dy));

          // Go through all the components 
          for (final GlobalKey<ComponentState> componentKey
                      in _components.keys) {
            ComponentState componentState = componentKey.currentState!;
            Offset componentOffset = _componentPositions[componentKey]!;
            // Make a list the right port positions
            List<Offset> rightSideOffsets = [
              for (int i = 0;
                  i < componentState.module.rightSide.length;
                  i++)
                Offset(componentOffset.dx + componentState.width,
                    componentOffset.dy + (gridSize * (i + 2)))
            ];
            // Make a list of the left port positions
            List<Offset> leftSideOffsets = [
              for (int i = 0;
                  i < componentState.module.leftSide.length;
                  i++)
                Offset(componentOffset.dx,
                    componentOffset.dy + (gridSize * (i + 2)))
            ];

            // If any of the left/right port positions is equal to where we tapped,
            // Add that component to the probedPorts map
            if (rightSideOffsets.contains(tapOffset)) {
              probedPorts[componentKey] = componentState.module.rightSide
                .elementAt(rightSideOffsets.indexOf(tapOffset));
              print("Component ports");
              print(probedPorts);
              return;
            } else if (leftSideOffsets.contains(tapOffset)) {
              probedPorts[componentKey] = componentState.module.leftSide
                .elementAt(leftSideOffsets.indexOf(tapOffset))
                .connectedNode;
            }
          }
        },
      ) : const SizedBox.shrink(),
    
    mode == "Remove Probe"
      ? GestureDetector(
        onTapUp: (TapUpDetails details) {
          // Get the position of where you click and snap to the grid
          Offset tapOffset = _snapToGrid(Offset(
                      details.localPosition.dx, details.localPosition.dy));

          // Go through all the components 
          for (final GlobalKey<ComponentState> componentKey
                      in _components.keys) {
            if (probedPorts.containsKey(componentKey)) {
              ComponentState componentState = componentKey.currentState!;
              Offset componentOffset = _componentPositions[componentKey]!;
              // Make a list the right port positions
              List<Offset> rightSideOffsets = [
                for (int i = 0;
                    i < componentState.module.rightSide.length;
                    i++)
                  Offset(componentOffset.dx + componentState.width,
                      componentOffset.dy + (gridSize * (i + 2)))
              ];
              // Make a list of the left port positions
              List<Offset> leftSideOffsets = [
                for (int i = 0;
                    i < componentState.module.leftSide.length;
                    i++)
                  Offset(componentOffset.dx,
                      componentOffset.dy + (gridSize * (i + 2)))
              ];

              // If any of the left/right port positions is equal to where we tapped,
              // Remove the probed component from the map
              if (rightSideOffsets.contains(tapOffset)) {
                probedPorts.remove(componentKey);
                waveformAnalyzerKey.currentState!.removeWaveform(componentKey);
                return;
              } else if (leftSideOffsets.contains(tapOffset)) {
                probedPorts.remove(componentKey);
                waveformAnalyzerKey.currentState!.removeWaveform(componentKey);
                return;
              }
            }   
          }
        },
      ) : const SizedBox.shrink(),
    ]));
  }
}

class MyPainter extends CustomPainter {
  final List<List<Offset>> wires;

  MyPainter({
    required this.wires,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    for (final wire in wires) {
      for (int i = 0; i < wire.length - 1; i++) {
        final startPoint = wire[i];
        final endPoint = wire[i + 1];
        canvas.drawLine(startPoint, endPoint, paint);
      }
    }
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    return true;
  }
}
