import 'package:flutter/material.dart';
import 'main.dart';
import 'dart:math';
import 'package:rohd/rohd.dart' as rohd;

class ComponentBox extends StatefulWidget {
  final rohd.Module module; // Add module field

  const ComponentBox({
    Key? key, // Make key nullable
    required this.module, // Add module parameter
  }) : super(key: key); // Call super with nullable key

  @override
  ComponentBoxState createState() => ComponentBoxState();
}

class ComponentBoxState extends State<ComponentBox> {
  bool selected = false;
  Offset offset = dropPosition.value;//Offset.zero;

  @override
  void initState() {
    super.initState();

    if (!widget.module.hasBuilt) {
      widget.module.build();
    }

    for (int i = 0; i < widget.module.inputs.length; i++) {
      widget.module.inputs.values.elementAt(i).changed.listen((event) {
        setState(() {});
      });
    }
  }

  _toggleInputCircleValue(int index) {
    if (widget.module.inputs.values.elementAt(index).value ==
        rohd.LogicValue.one) {
      widget.module.inputs.values.elementAt(index).inject(rohd.LogicValue.zero);
    } else {
      widget.module.inputs.values.elementAt(index).inject(rohd.LogicValue.one);
    }
  }

  Color? getColour(rohd.LogicValue val) {
    if (val == rohd.LogicValue.one) {
      return Colors.orange[800];
    }
    if (val == rohd.LogicValue.zero) {
      return Colors.deepPurple[900];
    }
    if (val == rohd.LogicValue.z) {
      return Colors.amber;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    double circleSize = 40.0;
    double paddingSize = 7.5;
    double circleSpacing = 5;

    double boxWidth = (circleSize * 2) + (paddingSize * 2) + circleSpacing;

    double boxHeight =
        (max(widget.module.inputs.length, widget.module.outputs.length) *
                circleSize) +
            (paddingSize * 2) +
            ((max(widget.module.inputs.length, widget.module.outputs.length)-1) *
                circleSpacing);
    return Positioned(
      left: (offset.dx / gridSize).roundToDouble() * gridSize,
      top: (offset.dy / gridSize).roundToDouble() * gridSize,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selected = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            offset = Offset(
                offset.dx + details.delta.dx, offset.dy + details.delta.dy);
          });
        },
        child: Container(
          padding: EdgeInsets.all(paddingSize),
          width: boxWidth,
          height: boxHeight,
          decoration: BoxDecoration(
            color: Colors.teal[400],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  for (int i = 0; i < widget.module.inputs.length; i++)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleInputCircleValue(i),
                          child: CircleAvatar(
                            backgroundColor: getColour(
                                widget.module.inputs.values.elementAt(i).value),
                            radius: circleSize / 2,
                          ),
                        ),
                        if (i != widget.module.inputs.length-1) SizedBox(height: circleSpacing),
                      ],
                    )
                ],
              ),
              SizedBox(width: circleSpacing),
              Column(
                children: [
                  for (int i = 0; i < widget.module.outputs.length; i++)
                    CircleAvatar(
                      backgroundColor: getColour(
                          widget.module.outputs.values.elementAt(i).value),
                      radius: circleSize / 2,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
