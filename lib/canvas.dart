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

  void addComponent(Component component, {Offset offset = Offset.zero}) {
    setState(() {
      _components.add(component);
      _componentPositions[component] = offset;
    });
  }

  void removeComponent(Component component) {
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
        child: Stack(children: <Widget>[
      GridPaper(
        divisions: 1,
        subdivisions: 1,
        interval: gridSize,
        color: Colors.black12,
        child: Container(),
      ),
      Stack(
        children: _components.map((component) {
          return Positioned(
            left: (_componentPositions[component]!.dx / gridSize)
                    .roundToDouble() *
                gridSize,
            top: (_componentPositions[component]!.dy / gridSize)
                    .roundToDouble() *
                gridSize,
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    // _selectedComponents.add(component); TODO
                  });
                },
                onPanUpdate: (details) {
                  updateComponentPosition(component, details.delta);
                },
                onPanEnd: (details) {
                  _snapToGrid(component);
                },
                child: component),
          );
        }).toList(),
      )
    ]));
  }
}
