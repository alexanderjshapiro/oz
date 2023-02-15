import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class Component extends StatefulWidget {
  const Component({super.key, required String name, required this.color});

  final Color color;

  @override
  State<StatefulWidget> createState() => _ComponentState();
}

class _ComponentState extends State<Component> {
  bool selected = false;
  Offset offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return
      Positioned(
        left: (offset.dx/gridSize).roundToDouble()*gridSize,
        top: (offset.dy/gridSize).roundToDouble()*gridSize,
        child: GestureDetector(
          onTap: () {
            setState(() {
              selected = true;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              offset = Offset(offset.dx + details.delta.dx, offset.dy + details.delta.dy);
            });
          },
          child: Container(height: 100, width: 100, decoration: selected ? BoxDecoration(color: widget.color, border: Border.all(width: 5, color: Colors.pink),) : BoxDecoration(color: widget.color))
        ),
      );
  }
}