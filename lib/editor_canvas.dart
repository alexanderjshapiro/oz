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
  final Map<Component, Offset> _componentPositions = {};
  final List<Component> _selectedComponents = [];

  final List<List<Offset>> _wires = [];
  int _wireIndex = -1;
  bool validWireStart = false;

  void addComponent(Type moduleType, {Offset offset = Offset.zero}) {
    GlobalKey<ComponentState> componentKey = GlobalKey<ComponentState>();
    Component component = Component(
      moduleType: moduleType,
      key: componentKey,
    );
    setState(() {
      _components[componentKey] = component;
      _componentPositions[component] = offset;
    });
  }

  void _removeComponent(Component component) {
    setState(() {
      _components.remove(component);
      _componentPositions.remove(component);
    });
  }

  void removeSelectedComponents() {
    setState(() {
      for (final Component component in _selectedComponents) {
        _removeComponent(component);
      }
      _selectedComponents.clear();
    });
  }

  void clear() {
    setState(() {
      _components.clear();
      _componentPositions.clear();
      _selectedComponents.clear();
      _wires.clear();
      _wireIndex = -1;
    });
  }

  void updateComponentPosition(Component component, Offset offset) {
    setState(() {
      _componentPositions[component] = Offset(
          _componentPositions[component]!.dx + offset.dx,
          _componentPositions[component]!.dy + offset.dy);
    });
  }

  void _snapToGrid(Component component) {
    setState(() {
      _componentPositions[component] = Offset(
          (_componentPositions[component]!.dx / gridSize).round() * gridSize,
          (_componentPositions[component]!.dy / gridSize).round() * gridSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: GestureDetector(
            onTap: () {
              setState(() {
                debugPrint('clearing selected components');
                _selectedComponents.clear();
              });
            },
            child: Stack(children: [
              GridPaper(
                divisions: 1,
                subdivisions: 1,
                interval: gridSize,
                color: Colors.black12,
                child: Container(),
              ),
              Stack(children: [
                for (final GlobalKey componentKey in _components.keys)
                  Positioned(
                    left: (_componentPositions[_components[componentKey]]!.dx /
                                    gridSize)
                                .roundToDouble() *
                            gridSize -
                        (_selectedComponents.contains(_components[componentKey])
                            ? selectedComponentBorderWidth
                            : 0),
                    top: (_componentPositions[_components[componentKey]]!.dy /
                                    gridSize)
                                .roundToDouble() *
                            gridSize -
                        (_selectedComponents.contains(_components[componentKey])
                            ? selectedComponentBorderWidth
                            : 0),
                    child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedComponents.add(_components[componentKey]!);
                          });
                        },
                        onPanUpdate: (details) {
                          for (final Component component
                              in _selectedComponents) {
                            updateComponentPosition(component, details.delta);
                          }
                        },
                        onPanEnd: (_) {
                          for (final Component component
                              in _selectedComponents) {
                            _snapToGrid(component);
                          }
                        },
                        child: Container(
                            decoration: _selectedComponents
                                    .contains(_components[componentKey]!)
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
                          Offset startOffset = MyPainter._snapToGrid(Offset(
                              details.localPosition.dx,
                              details.localPosition.dy));

                          for (final GlobalKey<ComponentState> componentKey
                              in _components.keys) {
                            ComponentState componentState =
                                componentKey.currentState!;
                            Offset componentOffset =
                                _componentPositions[_components[componentKey]]!;
                            List<Offset> rightSideOffsets = [
                              for (int i = 0;
                                  i < componentState.module.rightSide.length;
                                  i++)
                                Offset(componentOffset.dx,
                                    componentOffset.dy + (gridSize * (i + 2)))
                            ];
                            if (rightSideOffsets.contains(startOffset)) {
                              debugPrint(
                                  'found valid wire start at ${startOffset / gridSize} on component ${componentState.widget.moduleType} port ${rightSideOffsets.indexOf(startOffset)}');
                              setState(() {
                                validWireStart = true;
                                _wireIndex++;
                                _wires.add([startOffset]);
                              });
                              return;
                            }
                          }
                        },
                        onPanUpdate: (details) {
                          if (validWireStart) {
                            setState(() {
                              Offset offset = MyPainter._snapToGrid(Offset(
                                  details.localPosition.dx,
                                  details.localPosition.dy));
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
                                _wires[i] =
                                    _wires[i] + _wires[_wireIndex].sublist(1);
                                _wires.removeAt(_wireIndex);
                                _wireIndex--;
                              } else if (_wires[_wireIndex].last ==
                                  _wires[i].first) {
                                _wires[i] =
                                    _wires[_wireIndex] + _wires[i].sublist(1);
                                _wires.removeAt(_wireIndex);
                                _wireIndex--;
                              }
                            }
                            validWireStart = false;
                          }

                          debugPrint(_wires.length.toString());
                        },
                      )
                    : null,
              ),
            ])));
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

  static Offset _snapToGrid(Offset point) {
    final dx = (point.dx / gridSize).round() * gridSize;
    final dy = (point.dy / gridSize).round() * gridSize;
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    return true;
  }
}
