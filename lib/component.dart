import 'package:flutter/material.dart';
import 'main.dart';
import 'dart:math';
import 'package:rohd/rohd.dart' as rohd;

dynamic wiringPortSelected;

class ComponentBox extends StatefulWidget {
  final Type moduleType; // Add module field
  final List? inputs;

  const ComponentBox({
    Key? key, // Make key nullable
    required this.moduleType, // Add module parameter
    this.inputs,
  }) : super(key: key); // Call super with nullable key

  @override
  ComponentBoxState createState() => ComponentBoxState();
}

class ComponentBoxState extends State<ComponentBox> {
  late rohd.Module module; // Add module field
  bool selected = false;
  Offset offset = dropPosition.value; //Offset.zero;

  @override
  void initState() {
    super.initState();
    if (widget.moduleType == rohd.Xor2Gate) {
      module = rohd.Xor2Gate(rohd.Logic(), rohd.Logic());
    } else if (widget.moduleType == rohd.And2Gate) {
      module = rohd.And2Gate(rohd.Logic(), rohd.Logic());
    } else if (widget.moduleType == rohd.FlipFlop) {
      module = rohd.FlipFlop(rohd.SimpleClockGenerator(60).clk, rohd.Logic());
    } else if (widget.moduleType == rohd.NotGate) {
      module = rohd.NotGate(rohd.Logic());
    } else {
      throw ("Not yet implemented");
    }
    if (!module.hasBuilt) {
      module.build();
    }

    for (int i = 0; i < module.inputs.length; i++) {
      module.inputs.values.elementAt(i).changed.listen((event) {
        setState(() {});
      });
    }
  }

  _toggleInputCircleValue(int index) {
    if (module.inputs.values.elementAt(index).value == rohd.LogicValue.one) {
      module.inputs.values.elementAt(index).inject(rohd.LogicValue.zero);
    } else {
      module.inputs.values.elementAt(index).inject(rohd.LogicValue.one);
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
        (max(module.inputs.length, module.outputs.length) * circleSize) +
            (paddingSize * 2) +
            ((max(module.inputs.length, module.outputs.length) - 1) *
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
                  for (int i = 0; i < module.inputs.length; i++)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleInputCircleValue(i),
                          onDoubleTap: () {
                            if (wiringPortSelected != null) {
                              var inputs = module.inputs.values.toList();
                              inputs[i] = wiringPortSelected;
                              module = rohd.And2Gate(inputs[0], inputs[1]);
                              module.build();
                              //module.inputs[module.inputs.keys.elementAt(i)] = wiringPortSelected;
                              for (int i = 0; i < module.inputs.length; i++) {
                                module.inputs.values
                                    .elementAt(i)
                                    .changed
                                    .listen((event) {
                                  setState(() {});
                                });
                              }
                              wiringPortSelected = null;
                              debugPrint("Connected Ports together");
                            }
                          },
                          child: CircleAvatar(
                            backgroundColor: getColour(
                                module.inputs.values.elementAt(i).value),
                            radius: circleSize / 2,
                          ),
                        ),
                        if (i != module.inputs.length - 1)
                          SizedBox(height: circleSpacing),
                      ],
                    )
                ],
              ),
              SizedBox(width: circleSpacing),
              Column(
                children: [
                  for (int i = 0; i < module.outputs.length; i++)
                    Column(
                      children: [
                        GestureDetector(
                          onDoubleTap: () {
                            if (wiringPortSelected == null) {
                              debugPrint("Selected Output for wiring");
                              wiringPortSelected =
                                  module.outputs.values.elementAt(i);
                            } else {
                              wiringPortSelected = null;
                              debugPrint("Deselected Output for wiring");
                            }
                          },
                          child: CircleAvatar(
                            backgroundColor: getColour(
                                module.outputs.values.elementAt(i).value),
                            radius: circleSize / 2,
                          ),
                        ),
                        if (i != module.outputs.length - 1)
                          SizedBox(height: circleSpacing),
                      ],
                    )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
