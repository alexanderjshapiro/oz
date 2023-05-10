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

  bool drawMode = false;

  final Map<GlobalKey<ComponentState>, Component> _components = {};
  final Map<GlobalKey<ComponentState>, Offset> _componentPositions = {};
  GlobalKey<ComponentState>? _selectedComponentKey;

  final List<List<Offset>> _wires = [];
  int? _wireIndex;
  bool validWireStart = false;
  Node? wiringNodeSelected;
  int? _selectedWireIndex;
  bool somethingWasSelected = false;

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

  void removeSelected() {
    if (_selectedComponentKey != null) {
      _removeComponent(_selectedComponentKey!);
      _selectedComponentKey = null;
    }

    if (_selectedWireIndex != null) {
      _wires.removeAt(_selectedWireIndex!);
      _selectedWireIndex = null;
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

  void updateComponentPosition(GlobalKey<ComponentState> componentKey, Offset offset) {
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
      GestureDetector(
        onTapUp: (TapUpDetails details) {
          if (!drawMode) {
            Offset offset = _snapToGrid(details.localPosition);
            for (var i = 0; i < _wires.length; i++) {
              if (_wires[i].contains(offset)) {
                setState(() {
                  _selectedComponentKey = null;
                  _selectedWireIndex = i;
                });
                return;
              }
            }

            setState(() {
              _selectedComponentKey = null;
              _selectedWireIndex = null;
            });
          }
        },
        onPanStart: (DragStartDetails details) {
          if (drawMode) {
            Offset startOffset = _snapToGrid(Offset(details.localPosition.dx, details.localPosition.dy));

            for (final GlobalKey<ComponentState> componentKey in _components.keys) {
              ComponentState componentState = componentKey.currentState!;
              Offset componentOffset = _componentPositions[componentKey]!;
              List<Offset> rightSideOffsets = [for (int i = 0; i < componentState.module.rightSide.length; i++) Offset(componentOffset.dx + componentState.width, componentOffset.dy + (gridSize * (i + 2)))];
              List<Offset> leftSideOffsets = [for (int i = 0; i < componentState.module.leftSide.length; i++) Offset(componentOffset.dx, componentOffset.dy + (gridSize * (i + 2)))];

              if (rightSideOffsets.contains(startOffset)) {
                setState(() {
                  validWireStart = true;
                  _wires.add([startOffset]);
                  _wireIndex = _wires.length - 1;
                });
                wiringNodeSelected = componentState.module.rightSide.elementAt(rightSideOffsets.indexOf(startOffset)).connectedNode;
                return;
              } else if (leftSideOffsets.contains(startOffset)) {
                setState(() {
                  validWireStart = true;
                  _wires.add([startOffset]);
                  _wireIndex = _wires.length - 1;
                });
                wiringNodeSelected = componentState.module.leftSide.elementAt(leftSideOffsets.indexOf(startOffset)).connectedNode;
                return;
              } else {
                for (var wire in _wires) {
                  if (startOffset == wire.last) {
                    validWireStart = true;
                    _wireIndex = _wires.indexOf(wire);
                  }
                }
              }
            }
          }
        },
        onPanUpdate: (DragUpdateDetails details) {
          if (drawMode) {
            if (validWireStart) {
              setState(() {
                Offset offset = _snapToGrid(Offset(details.localPosition.dx, details.localPosition.dy));
                if (offset != _wires[_wireIndex!].last) {
                  _wires[_wireIndex!].add(offset);
                }
              });
            }
          }
        },
        onPanEnd: (_) {
          if (drawMode) {
            if (validWireStart) {
              for (int i = 0; i < _wires.length; i++) {
                if (_wires[i].last == _wires[_wireIndex!].first) {
                  _wires[i] = _wires[i] + _wires[_wireIndex!].sublist(1);
                  _wires.removeAt(_wireIndex!);
                } else if (_wires[_wireIndex!].last == _wires[i].first) {
                  _wires[i] = _wires[_wireIndex!] + _wires[i].sublist(1);
                  _wires.removeAt(_wireIndex!);
                }
              }
              validWireStart = false;

              Offset endOffset = _wires[_wireIndex!].last;

              for (final GlobalKey<ComponentState> componentKey in _components.keys) {
                ComponentState componentState = componentKey.currentState!;
                Offset componentOffset = _componentPositions[componentKey]!;
                List<Offset> rightSideOffsets = [for (int i = 0; i < componentState.module.rightSide.length; i++) Offset(componentOffset.dx + componentState.width, componentOffset.dy + (gridSize * (i + 2)))];
                List<Offset> leftSideOffsets = [for (int i = 0; i < componentState.module.leftSide.length; i++) Offset(componentOffset.dx, componentOffset.dy + (gridSize * (i + 2)))];
                if (leftSideOffsets.contains(endOffset)) {
                  componentState.module.leftSide.elementAt(leftSideOffsets.indexOf(endOffset)).connectNode(wiringNodeSelected!);
                  return;
                } else if (rightSideOffsets.contains(endOffset)) {
                  componentState.module.rightSide.elementAt(rightSideOffsets.indexOf(endOffset)).connectNode(wiringNodeSelected!);
                  return;
                }
              }

              _wireIndex = null;
            }
          }
        },
      ),
      Stack(children: [
        for (final GlobalKey<ComponentState> componentKey in _components.keys)
          Positioned(
            left: _snapToGrid(_componentPositions[componentKey]!).dx - (_selectedComponentKey == componentKey ? selectedComponentBorderWidth : 0),
            top: _snapToGrid(_componentPositions[componentKey]!).dy - (_selectedComponentKey == componentKey ? selectedComponentBorderWidth : 0),
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedComponentKey = componentKey;
                    _selectedWireIndex = null;
                  });
                },
                onPanStart: (_) {
                  // check if component is already selected
                  _selectedComponentKey = componentKey;
                },
                onPanUpdate: (details) {
                  updateComponentPosition(_selectedComponentKey!, details.delta);
                },
                onPanEnd: (_) {
                  _componentPositions[_selectedComponentKey!] = _snapToGrid(_componentPositions[_selectedComponentKey]!);
                },
                child: Container(decoration: _selectedComponentKey == componentKey ? BoxDecoration(border: Border.all(width: selectedComponentBorderWidth, color: Colors.blue)) : null, child: _components[componentKey]!)),
          )
      ]),
      CustomPaint(
        painter: MyPainter(wires: _wires, selectedWireIndex: _selectedWireIndex),
      ),
    ]));
  }
}

class MyPainter extends CustomPainter {
  final List<List<Offset>> wires;
  int? selectedWireIndex;

  MyPainter({required this.wires, required this.selectedWireIndex});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < wires.length; i++) {
      final paint = Paint()
        ..color = i == selectedWireIndex ? Colors.blue : Colors.black
        ..strokeWidth = 2.0;

      for (int j = 0; j < wires[i].length - 1; j++) {
        final startPoint = wires[i][j];
        final endPoint = wires[i][j + 1];
        canvas.drawLine(startPoint, endPoint, paint);
      }
    }
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    return true;
  }
}
