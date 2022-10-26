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
  Offset offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return
      // widget.icon;
      Positioned(
        left: (offset.dx/gridSize).roundToDouble()*gridSize,
        top: (offset.dy/gridSize).roundToDouble()*gridSize,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              offset = Offset(offset.dx + details.delta.dx, offset.dy + details.delta.dy);
            });
          },
          child: Container(height: 100, width: 100, color: widget.color)
        ),
      );
  }
}