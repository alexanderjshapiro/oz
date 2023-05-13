import 'package:flutter/material.dart';
import 'component.dart';
import 'logic.dart';
import 'main.dart';

class EditorCanvas extends StatefulWidget {
  const EditorCanvas({Key? key}) : super(key: key);

  @override
  EditorCanvasState createState() => EditorCanvasState();
}

enum CanvasMode {
  select,
  draw,
  addProbe,
  removeProbe,
}

class EditorCanvasState extends State<EditorCanvas> {
  static const double selectedComponentBorderWidth = 1.0;
  static const Color selectedComponentColor = Colors.blue;
  static BoxDecoration selectedComponentDecoration = BoxDecoration(
      border: Border.all(
          width: selectedComponentBorderWidth, color: selectedComponentColor));

  CanvasMode mode = CanvasMode.select;

  /// Data structure: `[{'key': GlobalKey<ComponentState>, 'widget': Component, 'offset': Offset, 'selected': bool}]`
  final List<Map<String, dynamic>> _components = [];

  List<Map<String, dynamic>> get components => _components;

  /// Data structure: `[{'points': List<Offset>, 'selected': bool}]`
  final List<Map<String, dynamic>> _wires = [];

  int tilingHorizontal = 70;
  int tilingVertical = 40;

  void addComponent(Type moduleType, {Offset offset = Offset.zero}) {
    GlobalKey<ComponentState> key = GlobalKey<ComponentState>();
    setState(() {
      _components.add({
        'key': key,
        'widget': Component(moduleType: moduleType, key: key),
        'offset': _snapToGrid(offset),
        'selected': false
      });
    });
  }

  void deselectSelected() {
    for (final Map<String, dynamic> component in _components) {
      if (component['selected']) setState(() => component['selected'] = false);
    }

    for (final Map<String, dynamic> wire in _wires) {
      if (wire['selected']) setState(() => wire['selected'] = false);
    }
  }

  void removeSelected() {
    // if a wire is selected
    Map<String, dynamic>? selectedWire;
    for (final Map<String, dynamic> wire in _wires) {
      if (wire['selected']) selectedWire = wire;
    }

    if (selectedWire != null) {
      Map<String, dynamic>? componentAtFirst =
          findComponentAt(selectedWire['points'].first);
      if (componentAtFirst != null) {
        ComponentState componentState = componentAtFirst['key'].currentState!;
        int? portIndex = componentState.portIndexAt(
            selectedWire['points'].first - componentAtFirst['offset']);

        if (componentState.widget.moduleType != BinarySwitch) {
          componentState.module.ports[portIndex!]
              .connectNode(Node(componentState.module));
        }
      }

      Map<String, dynamic>? componentAtLast =
          findComponentAt(selectedWire['points'].last);
      if (componentAtLast != null) {
        ComponentState componentState = componentAtLast['key'].currentState!;
        int? portIndex = componentState.portIndexAt(
            selectedWire['points'].last - componentAtLast['offset']);

        if (componentState.widget.moduleType != BinarySwitch) {
          componentState.module.ports[portIndex!]
              .connectNode(Node(componentState.module));
        }
      }

      setState(() => _wires.removeWhere((wire) => wire['selected']));
    }

    setState(
        () => _components.removeWhere((component) => component['selected']));
  }

  void clear() {
    setState(() {
      _components.clear();
      _wires.clear();
    });
  }

  bool updateComponentPosition(GlobalKey<ComponentState> key, Offset offset) {
    int index = _components.indexWhere((component) => component['key'] == key);
    if (index != -1) {
      setState(() => _components[index]['offset'] += offset);
      return true;
    }
    return false;
  }

  Map<String, dynamic>? findComponentAt(Offset point) {
    Map<String, dynamic>? match;

    for (final Map<String, dynamic> component in _components) {
      ComponentState componentState = component['key'].currentState!;
      // get offsets of all ports
      Map<String, List<Offset>> componentPortOffsets =
          Map.from(componentState.portOffsets);
      componentPortOffsets.forEach((side, portOffsets) =>
          componentPortOffsets[side] = [
            for (final Offset portOffset in portOffsets)
              component['offset'] + portOffset
          ]);

      componentPortOffsets.forEach((String side, List<Offset> portOffsets) {
        if (portOffsets.contains(point)) match = component;
      });
    }
    return match;
  }

  static Offset _snapToGrid(Offset offset) {
    double dx = (offset.dx / gridSize).round() * gridSize;
    double dy = (offset.dy / gridSize).round() * gridSize;
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: gridSize * tilingHorizontal,
      height: gridSize * tilingVertical,
      child: Stack(
        children: [
          GridPaper(
            divisions: 1,
            subdivisions: 1,
            interval: gridSize,
            color: Colors.black12,
            child: Container(),
          ),
          GestureDetector(
            onTapUp: (TapUpDetails details) {
              Offset tapOffset = _snapToGrid(details.localPosition);
              switch (mode) {
                case CanvasMode.select:
                  deselectSelected();

                  // select wire if it contains tapOffset
                  for (final Map<String, dynamic> element in _wires) {
                    if (element['points'].contains(tapOffset)) {
                      setState(() => element['selected'] = true);
                    }
                  }

                  break;
                case CanvasMode.draw:
                  break;
                case CanvasMode.addProbe:
                  // Go through all the components
                  for (final Map<String, dynamic> component in _components) {
                    ComponentState componentState =
                        component['key'].currentState!;

                    // get offsets of all ports
                    Map<String, List<Offset>> componentPortOffsets =
                        Map.from(componentState.portOffsets);
                    componentPortOffsets.forEach((side, portOffsets) =>
                        componentPortOffsets[side] = [
                          for (final Offset portOffset in portOffsets)
                            component['offset'] + portOffset
                        ]);

                    // If any of the left/right port positions is equal to where we tapped,
                    // Add that component to the probedPorts map
                    if (componentPortOffsets['right']!.contains(tapOffset)) {
                      probedPorts[component['key']] = componentState
                          .module.rightPorts
                          .elementAt(componentPortOffsets['right']!
                              .indexOf(tapOffset));
                      return;
                    } else if (componentPortOffsets['left']!
                        .contains(tapOffset)) {
                      probedPorts[component['key']] =
                          componentState.module.leftPorts.elementAt(
                              componentPortOffsets['left']!.indexOf(tapOffset));
                    }
                  }
                  break;
                case CanvasMode.removeProbe:
                  // Go through all the components
                  for (final Map<String, dynamic> component in _components) {
                    if (probedPorts.containsKey(component['key'])) {
                      ComponentState componentState =
                          component['key'].currentState!;

                      // get offsets of all ports
                      Map<String, List<Offset>> componentPortOffsets =
                          Map.from(componentState.portOffsets);
                      componentPortOffsets.forEach((side, portOffsets) =>
                          componentPortOffsets[side] = [
                            for (final Offset portOffset in portOffsets)
                              component['offset'] + portOffset
                          ]);

                      // If any of the left/right port positions is equal to where we tapped,
                      // Remove the probed component from the map
                      if (componentPortOffsets['right']!.contains(tapOffset)) {
                        probedPorts.remove(component['key']);
                        waveformAnalyzerKey.currentState!
                            .removeWaveform(component['key']);
                        return;
                      } else if (componentPortOffsets['left']!
                          .contains(tapOffset)) {
                        probedPorts.remove(component['key']);
                        waveformAnalyzerKey.currentState!
                            .removeWaveform(component['key']);
                        return;
                      }
                    }
                  }
                  break;
              }
            },
            onPanStart: (DragStartDetails details) {
              Offset panStartOffset = _snapToGrid(details.localPosition);
              switch (mode) {
                case CanvasMode.select:
                  break;
                case CanvasMode.draw:
                  deselectSelected();

                  bool wireFound = false;
                  for (final Map<String, dynamic> wire in _wires) {
                    if (panStartOffset == wire['points'].last) {
                      // append to other wire
                      setState(() => wire['selected'] = true);
                      wireFound = true;
                      break;
                    } else if (panStartOffset == wire['points'].first) {
                      // reverse other wire and append to other wire
                      setState(() {
                        wire['points'] = wire['points'].reversed.toList();
                        wire['selected'] = true;
                      });
                      wireFound = true;
                      break;
                    }
                  }

                  if (!wireFound) {
                    // create new wire
                    setState(() => _wires.add({
                          'points': [panStartOffset],
                          'selected': true
                        }));
                  }

                  break;
                case CanvasMode.addProbe:
                  break;
                case CanvasMode.removeProbe:
                  break;
              }
            },
            onPanUpdate: (DragUpdateDetails details) {
              Offset panUpdateOffset = _snapToGrid(
                  Offset(details.localPosition.dx, details.localPosition.dy));
              switch (mode) {
                case CanvasMode.select:
                  break;
                case CanvasMode.draw:
                  var i = _wires.indexWhere((wire) => wire['selected']);

                  // extend wire
                  setState(() {
                    if (panUpdateOffset != _wires[i]['points'].last) {
                      _wires[i]['points'].add(panUpdateOffset);
                    }
                  });

                  break;
                case CanvasMode.addProbe:
                  break;
                case CanvasMode.removeProbe:
                  break;
              }
            },
            onPanEnd: (_) {
              switch (mode) {
                case CanvasMode.select:
                  break;
                case CanvasMode.draw:
                  final int wireIndex =
                      _wires.indexWhere((wire) => wire['selected']);

                  for (final Map<String, dynamic> wire in _wires) {
                    if (wire != _wires[wireIndex]) {
                      if (_wires[wireIndex]['points'].last ==
                          wire['points'].last) {
                        // append to other wire
                        setState(() {
                          _wires[wireIndex]['points']
                              .addAll(wire['points'].reversed.toList());
                          _wires.remove(wire);
                        });
                        break;
                      } else if (_wires[wireIndex]['points'].last ==
                          wire['points'].first) {
                        // reverse other wire and append to other wire
                        setState(() {
                          _wires[wireIndex]['points'].addAll(wire['points']);
                          _wires.remove(wire);
                        });
                        break;
                      }
                    }
                  }

                  List<Offset> points = _wires[wireIndex]['points'];

                  Node? node;
                  Map<String, dynamic>? from = findComponentAt(points.first);
                  if (from != null) {
                    ComponentState fromState = from['key'].currentState!;
                    node = fromState
                        .module
                        .ports[fromState
                            .portIndexAt(points.first - from['offset'])!]
                        .connectedNode;

                    Map<String, dynamic>? to = findComponentAt(points.last);
                    if (to != null) {
                      ComponentState toState = to['key'].currentState!;
                      if (toState.widget.moduleType == BinarySwitch) {
                        node = toState
                            .module
                            .ports[toState
                                .portIndexAt(points.last - to['offset'])!]
                            .connectedNode;
                        fromState
                            .module
                            .ports[fromState
                                .portIndexAt(points.first - from['offset'])!]
                            .connectNode(node!);
                      } else {
                        toState
                            .module
                            .ports[toState
                                .portIndexAt(points.last - to['offset'])!]
                            .connectNode(node!);
                      }
                    }
                  }

                  break;
                case CanvasMode.addProbe:
                  break;
                case CanvasMode.removeProbe:
                  break;
              }
            },
          ),
          Stack(children: [
            for (final Map<String, dynamic> component in _components)
              Positioned(
                // always visually snap to grid, especially when dragging to move Component
                left: _snapToGrid(component['offset']).dx -
                    (component['selected'] ? selectedComponentBorderWidth : 0),
                top: _snapToGrid(component['offset']).dy -
                    (component['selected'] ? selectedComponentBorderWidth : 0),
                child: GestureDetector(
                    onTap: () {
                      // deselect all other Components and wires, then select this Component
                      deselectSelected();
                      setState(() => component['selected'] = true);
                    },
                    onPanStart: (_) {
                      // deselect all other Components and wires, then select this Component
                      deselectSelected();

                      // select Component if it is dragged without already being selected
                      if (!component['selected']) {
                        setState(() => component['selected'] = true);
                      }
                    },
                    onPanUpdate: (details) {
                      // update position of Component but only visually snap to the grid
                      updateComponentPosition(component['key'], details.delta);
                    },
                    onPanEnd: (_) {
                      // commit the snapped position
                      setState(() => component['offset'] =
                          _snapToGrid(component['offset']));
                    },
                    child: Container(
                        decoration: component['selected']
                            ? selectedComponentDecoration
                            : null,
                        child: component['widget'])),
              )
          ]),
          CustomPaint(painter: MyPainter(_wires)),
        ],
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  static const double wireWidth = 2.0;
  static const Color wireColor = Colors.black;
  static const Color selectedWireColor = Colors.blue;

  final List<Map<String, dynamic>> wireMaps;

  MyPainter(this.wireMaps);

  @override
  void paint(Canvas canvas, Size size) {
    for (var wireMap in wireMaps) {
      final paint = Paint()
        ..color = wireMap['selected'] ? selectedWireColor : wireColor
        ..strokeWidth = wireWidth;

      for (int j = 0; j < wireMap['points'].length - 1; j++) {
        final startPoint = wireMap['points'][j];
        final endPoint = wireMap['points'][j + 1];
        canvas.drawLine(startPoint, endPoint, paint);
      }
    }
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    return true;
  }
}
