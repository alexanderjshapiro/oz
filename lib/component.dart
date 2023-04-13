import 'package:flutter/material.dart';
import 'main.dart';
import 'dart:math';
import 'package:rohd/rohd.dart' as rohd;

dynamic wiringPortSelected;

class Component extends StatefulWidget {
  final Type moduleType; // Add module field
  final List? inputs;

  const Component({
    Key? key, // Make key nullable
    required this.moduleType, // Add module parameter
    this.inputs,
  }) : super(key: key); // Call super with nullable key

  @override
  ComponentState createState() => ComponentState();
}

class ComponentState extends State<Component> {
  late rohd.Module module; // Add module field
  bool _selected = false;
  Offset _offset = dropPosition.value; //Offset.zero;

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
    } else if (widget.moduleType == rohd.Or2Gate) {
      module = rohd.Or2Gate(rohd.Logic(), rohd.Logic());
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

  _toggleInputValue(rohd.Logic input) {
    if (input.value == rohd.LogicValue.one) {
      input.inject(rohd.LogicValue.zero);
    } else {
      input.inject(rohd.LogicValue.one);
    }
  }

  Color getColor(rohd.LogicValue val) {
    if (val == rohd.LogicValue.zero) return Colors.red;
    if (val == rohd.LogicValue.one) return Colors.green;
    if (val == rohd.LogicValue.z) return Colors.yellow;
    return Colors.grey;
  }

  double alignSizeToGrid(double size, {double div = 1}) {
    return size + ((gridSize / div) - (size % (gridSize / div)));
  }

  @override
  Widget build(BuildContext context) {
    const double componentNameSize = 28;
    const double portNameSize = 24;
    const double paddingSize = 8; // around edge of component
    const double borderSize = 2;
    const double minCenterPadding = 16; // between input and output columns

    // Component Sizing
    TextSpan span = TextSpan(style: const TextStyle(fontSize: componentNameSize), text: module.name);
    TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    tp.layout();
    double nameWidth = tp.width;
    double nameHeight = tp.height;

    double portNameHeight = 0; // Height of longest input or output name

    double inputNameWidth = 0; // Width of longest input name
    for (var input in module.inputs.values) {
      TextSpan span = TextSpan(
          style: const TextStyle(
            fontSize: portNameSize,
            fontFamily: 'Courier New',
          ),
          text: input.name);
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      tp.layout();
      if (tp.width > inputNameWidth) inputNameWidth = tp.width;
      if (tp.height > portNameHeight) portNameHeight = tp.height;
    }

    double outputNameWidth = 0; // Width of longest output name
    for (var output in module.outputs.values) {
      TextSpan span = TextSpan(
          style: const TextStyle(
            fontSize: portNameSize,
            fontFamily: 'Courier New',
          ),
          text: output.name);
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
      tp.layout();
      if (tp.width > outputNameWidth) outputNameWidth = tp.width;
      if (tp.height > portNameHeight) portNameHeight = tp.height;
    }

    double minComponentWidth = ((borderSize + paddingSize) * 2) + max((inputNameWidth + minCenterPadding + outputNameWidth), nameWidth);
    double componentWidth = alignSizeToGrid(minComponentWidth); // round up to next grid division

    double minNameAreaHeight = nameHeight;
    double nameAreaHeight = alignSizeToGrid(minNameAreaHeight, div: 2) + (gridSize / 2); // round up to next half-grid division

    double minPortHeight = portNameHeight;
    double portHeight = alignSizeToGrid(minPortHeight);
    int numLines = max(module.inputs.length, module.outputs.length);
    double minPortAreaHeight = (portHeight * numLines);
    double portAreaHeight = alignSizeToGrid(minPortAreaHeight, div: 2);

    double componentHeight = nameAreaHeight + portAreaHeight;

    return Positioned(
      left: (_offset.dx / gridSize).roundToDouble() * gridSize,
      top: (_offset.dy / gridSize).roundToDouble() * gridSize,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selected = !_selected;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _offset = Offset(_offset.dx + details.delta.dx, _offset.dy + details.delta.dy);
              });
            },
            child: Container(
                padding: const EdgeInsets.all(paddingSize),
                width: componentWidth,
                height: componentHeight,
                decoration:
                    BoxDecoration(color: Colors.white, border: _selected ? Border.all(width: borderSize, color: Colors.blue) : Border.all(width: borderSize)),
                child: Column(
                  children: [
                    // Component Name
                    SizedBox(
                      height: nameAreaHeight - (borderSize + paddingSize),
                      child: Text(
                        module.name,
                        style: const TextStyle(
                          fontSize: componentNameSize,
                        ),
                      ),
                    ),
                    // Inputs and Outputs
                    SizedBox(
                      height: portAreaHeight - (borderSize + paddingSize),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Input column
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var input in module.inputs.values)
                                SizedBox(
                                    height: portHeight,
                                    child: Center(
                                      child: GestureDetector(
                                        onTap: () => _toggleInputValue(input),
                                        onDoubleTap: () {
                                          if (wiringPortSelected != null) {
                                            debugPrint("${wiringPortSelected.dstConnections}");
                                            try {
                                              wiringPortSelected.gets(module.inputs[input.name]);
                                              debugPrint("Connected Ports together");
                                            } catch (A) {
                                              debugPrint("Could not connect Inputs: $A");
                                            }
                                          }
                                          wiringPortSelected = null;
                                        },
                                        child:
                                            Text(input.name, style: TextStyle(fontSize: portNameSize, fontFamily: 'Courier New', color: getColor(input.value))),
                                      ),
                                    ))
                            ],
                          ),
                          // Output column
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var output in module.outputs.values)
                                SizedBox(
                                    height: portHeight,
                                    child: Center(
                                      child: GestureDetector(
                                        onDoubleTap: () {
                                          if (wiringPortSelected == null) {
                                            debugPrint("Selected Output for wiring");
                                            wiringPortSelected = output;
                                          } else {
                                            wiringPortSelected = null;
                                            debugPrint("Deselected Output for wiring");
                                          }
                                        },
                                        child: Text(output.name,
                                            textAlign: TextAlign.right,
                                            style: TextStyle(fontSize: portNameSize, fontFamily: 'Courier New', color: getColor(output.value))),
                                      ),
                                    ))
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                )),
          ),
        ],
      ),
    );
  }
}
