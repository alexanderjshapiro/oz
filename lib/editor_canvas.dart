import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oz/waveform.dart';
import 'component.dart';
import 'logic.dart';
import 'main.dart';
import 'dart:math';

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

  /// Data structure: `[{'points': List<Offset>, 'selected': bool, 'color': Color}]`
  final List<Map<String, dynamic>> _wires = [];

  int tilingHorizontal = 70;
  int tilingVertical = 40;

  GlobalKey<ComponentState> addComponent(Type moduleType,
      {Offset offset = Offset.zero, bool selected = false}) {
    GlobalKey<ComponentState> key = GlobalKey<ComponentState>();
    setState(() {
      _components.add({
        'key': key,
        'widget':
            Component(moduleType: moduleType, key: key, selected: selected),
        'offset': _snapToGrid(offset),
        'selected': selected
      });
    });

    return key;
  }

  void deselectSelected() {
    for (final Map<String, dynamic> component in _components) {
      if (component['selected']) {
        setState(() {
          component['selected'] = false;
          component['key'].currentState?.selected = false;
        });
      }
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

        componentState.module.ports[portIndex!].connectedNode =
            Node(componentState.module, LogicValue.z);
      }

      Map<String, dynamic>? componentAtLast =
          findComponentAt(selectedWire['points'].last);
      if (componentAtLast != null) {
        ComponentState componentState = componentAtLast['key'].currentState!;
        int? portIndex = componentState.portIndexAt(
            selectedWire['points'].last - componentAtLast['offset']);

        componentState.module.ports[portIndex!].connectedNode =
            Node(componentState.module, LogicValue.z);
      }

      setState(() => _wires.removeWhere((wire) => wire['selected']));
    }

    setState(() {
      _components.where((component) => component['selected']).forEach(
          (component) => component['key'].currentState!.module.delete());
      _components.removeWhere((component) => component['selected']);
    });
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

  Offset _snapToGrid(Offset offset) {
    double dx = ((offset.dx / gridSize).round() * gridSize)
        .clamp(0, gridSize * tilingHorizontal);
    double dy = ((offset.dy / gridSize).round() * gridSize)
        .clamp(0, gridSize * tilingVertical);

    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: gridSize * tilingHorizontal,
      height: gridSize * tilingVertical,
      child: RawKeyboardListener(
        focusNode: globalFocus,
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            removeSelected();
          } else if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.keyD &&
              event.data.isControlPressed) {
            // Put clone tool code here
            Map<String, dynamic>? toClone;
            for (final Map<String, dynamic> component in _components) {
              if (component['selected']) toClone = component;
            }
            if (toClone == null) return;
            setState(() {
              deselectSelected();
              GlobalKey<ComponentState> newComponentKey = addComponent(
                  toClone?['widget'].moduleType,
                  offset: Offset(toClone?['offset'].dx + gridSize,
                      toClone?['offset'].dy + gridSize),
                  selected: true);
              Map<String, dynamic> newComponent = components.singleWhere(
                  (component) => component['key'] == newComponentKey);
              newComponent['selected'] = true;
            });
          }
        },
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
                    Offset tapOffset = _snapToGrid(Offset(
                        details.localPosition.dx, details.localPosition.dy));
                    Map<String, dynamic>? component =
                        findComponentAt(tapOffset);
                    ComponentState componentState =
                        component?['key'].currentState!;
                    int portIndex = componentState
                            .portIndexAt(tapOffset - component?['offset']) ??
                        0;
                    bool probesListIsEmpty =
                        probedPorts[component?['key']]?.isEmpty ?? true;
                    String portKey = componentState.module.ports[portIndex].key;
                    if (probesListIsEmpty) {
                      probedPorts[component?['key']] = [portKey];
                    } else {
                      probedPorts[component?['key']]?.add(portKey);
                    }
                    updateWaveformAnalyzer();
                    break;
                  case CanvasMode.removeProbe:
                    Offset tapOffset = _snapToGrid(Offset(
                        details.localPosition.dx, details.localPosition.dy));
                    Map<String, dynamic>? component =
                        findComponentAt(tapOffset);
                    ComponentState componentState =
                        component?['key'].currentState!;
                    int portIndex = componentState
                            .portIndexAt(tapOffset - component?['offset']) ??
                        0;
                    String portKey = componentState.module.ports[portIndex].key;

                    removePort(component?['key'], portKey);
                    waveformAnalyzerKey.currentState!
                        .removeWaveforms(component?['key'], portKey);
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
                            'selected': true,
                            'color': Color.fromARGB(
                              255,
                              Random().nextInt(256),
                              Random().nextInt(256),
                              Random().nextInt(256),
                            ),
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

                    //TODO this will probably cause a problem at some point, but it fixes when you try to connect wires end to end.
                    List<Offset> points = wireIndex < _wires.length
                        ? _wires[wireIndex]['points']
                        : _wires[wireIndex - 1]['points'];

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
                  left: _snapToGrid(component['offset']).dx,
                  top: _snapToGrid(component['offset']).dy,
                  child: GestureDetector(
                      onTap: () {
                        // deselect all other Components and wires, then select this Component
                        deselectSelected();
                        if (mode == CanvasMode.select) {
                          setState(() {
                            component['selected'] = true;
                            component['key'].currentState!.selected = true;
                          });
                        }
                      },
                      onPanStart: (_) {
                        // deselect all other Components and wires, then select this Component
                        deselectSelected();

                        // select Component if it is dragged without already being selected
                        if (mode == CanvasMode.select &&
                            !component['selected']) {
                          setState(() {
                            component['selected'] = true;
                            component['key'].currentState!.selected = true;
                          });
                        }
                      },
                      onPanUpdate: (details) {
                        component['key'].currentState!.module.ports.forEach(
                            (port) => debugPrint(
                                'Modules connected to port: ${port.connectedNode.connectedModules.length}'));
                        // update position of Component but only visually snap to the grid
                        if (mode == CanvasMode.select &&
                            component['key'].currentState!.module.ports.every(
                                (port) =>
                                    port.connectedNode.connectedModules
                                        .length ==
                                    1)) {
                          updateComponentPosition(
                              component['key'], details.delta);
                        }
                      },
                      onPanEnd: (_) {
                        // commit the snapped position
                        if (mode == CanvasMode.select) {
                          setState(() => component['offset'] =
                              _snapToGrid(component['offset']));
                        }
                      },
                      child: component['widget']),
                )
            ]),
            CustomPaint(painter: MyPainter(_wires)),
          ],
        ),
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
        ..color = wireMap['selected'] ? selectedWireColor : (colorMode ? wireMap['color']! : wireColor)
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
