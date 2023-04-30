import 'package:flutter/material.dart';
import 'component.dart';
import 'main.dart';

class Canvas extends StatefulWidget {
  const Canvas({Key? key}) : super(key: key);

  @override
  CanvasState createState() => CanvasState();
}

class CanvasState extends State<Canvas> {
  final List<Component> _components = [];
  final Map<Component, Offset> _componentPositions = {};
  final List<Component> _selectedComponents = [];

  void _addComponent(Component component, Offset offset) {
    setState(() {
      _components.add(component);
      _componentPositions[component] = offset;
    });
  }

  void _removeComponent(Component component) {
    setState(() {
      _components.remove(component);
      _componentPositions.remove(component);
      _selectedComponents.remove(component);
    });
  }

  void clearComponents() {
    setState(() {
      _components.clear();
      _componentPositions.clear();
      _selectedComponents.clear();
    });
  }

  void _snapToGrid(Component component) {
    final x =
        (_componentPositions[component]!.dx / gridSize).round() * gridSize;
    final y =
        (_componentPositions[component]!.dy / gridSize).round() * gridSize;

    setState(() {
      _componentPositions[component] = Offset(x, y);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Stack(children: <Widget>[
      GridPaper(
        divisions: 1,
        subdivisions: 1,
        interval: gridSize,
        color: Colors.black12,
        child: Container(),
      ),
      DragTarget<Map<String, dynamic>>(
        builder: (BuildContext context,
            List<Map<String, dynamic>?> candidateData,
            List<dynamic> rejectedData) {
          return Stack(
            children: _components.map((component) {
              return Positioned(
                left: (_componentPositions[component]!.dx / gridSize).roundToDouble() * gridSize,
                top: (_componentPositions[component]!.dy / gridSize).roundToDouble() * gridSize,
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // _selectedComponents.add(component); TODO
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _componentPositions[component] = Offset(
                            _componentPositions[component]!.dx +
                                details.delta.dx,
                            _componentPositions[component]!.dy +
                                details.delta.dy);
                      });
                    },
                    onPanEnd: (details) {
                      _snapToGrid(component);
                    },
                    child: component),
              );
            }).toList(),
          );
        },
        onWillAccept: (Map<String, dynamic>? data) {
          return true;
        },
        onAccept: (Map<String, dynamic> data) {
          setState(() {
            _addComponent(data['component'], dropPosition.value);
          });
        },
      )
    ]));
  }
}
