import 'package:flutter/material.dart';
import 'main.dart';
import 'dart:math';
import 'package:Oz/logic.dart' as rohd;

rohd.Logic? wiringPortSelected;

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

// Preview of a component when dragging and dropping onto the canvas
class ComponentPreview extends StatelessWidget {
  final Component component;

  const ComponentPreview({Key? key, required this.component}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.5,
        child: RepaintBoundary(
          child: Component(
            moduleType: component.moduleType,
          ),
        ),
      ),
    );
  }
}

class ComponentState extends State<Component> {
  late rohd.Module module; // Add module field

  @override
  void initState() {
    super.initState();
    if (widget.moduleType == rohd.Xor2Gate) {
    module = rohd.Xor2Gate();
    }else if (widget.moduleType == rohd.And2Gate) {
      module = rohd.And2Gate();
    } else if (widget.moduleType == rohd.FlipFlop) {
      module = rohd.FlipFlop();
    } else if (widget.moduleType == rohd.NotGate) {
      module = rohd.NotGate();
    } else if (widget.moduleType == rohd.Or2Gate) {
      module = rohd.Or2Gate();
    }else if (widget.moduleType == rohd.SN74LS373) {
      module = rohd.SN74LS373();
    }else {
      debugPrint("${widget.moduleType}");
      throw ("Not yet implemented");
    }

    module.callback = () {
      setState(() {});
    };
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
    TextSpan span = TextSpan(
        style: const TextStyle(fontSize: componentNameSize), text: module.name);
    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    double nameWidth = tp.width;
    double nameHeight = tp.height;

    double portNameHeight = 0; // Height of longest input or output name

    double inputNameWidth = 0; // Width of longest input name
    for (var input in module.inputs) {
      TextSpan span = TextSpan(
          style: const TextStyle(
            fontSize: portNameSize,
            fontFamily: 'Courier New',
          ),
          text: input.item1);
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr);
      tp.layout();
      if (tp.width > inputNameWidth) inputNameWidth = tp.width;
      if (tp.height > portNameHeight) portNameHeight = tp.height;
    }

    double outputNameWidth = 0; // Width of longest output name
    for (var output in module.outputs) {
      TextSpan span = TextSpan(
          style: const TextStyle(
            fontSize: portNameSize,
            fontFamily: 'Courier New',
          ),
          text: output.item1);
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr);
      tp.layout();
      if (tp.width > outputNameWidth) outputNameWidth = tp.width;
      if (tp.height > portNameHeight) portNameHeight = tp.height;
    }

    double minComponentWidth = ((borderSize + paddingSize) * 2) +
        max((inputNameWidth + minCenterPadding + outputNameWidth), nameWidth);
    double componentWidth =
        alignSizeToGrid(minComponentWidth); // round up to next grid division

    double minNameAreaHeight = nameHeight;
    double nameAreaHeight = alignSizeToGrid(minNameAreaHeight, div: 2) +
        (gridSize / 2); // round up to next half-grid division

    double minPortHeight = portNameHeight;
    double portHeight = alignSizeToGrid(minPortHeight);
    int numLines = max(module.inputs.length, module.outputs.length);
    double minPortAreaHeight = (portHeight * numLines);
    double portAreaHeight = alignSizeToGrid(minPortAreaHeight, div: 2);

    double componentHeight = nameAreaHeight + portAreaHeight;

    return GestureDetector(
      onSecondaryTap: () {
        // TODO fix delete to work right
        debugPrint("deleting Gate");
        module.release();
        canvasKey.currentState!.removeComponent(widget);
      },
      child: Container(
        padding: const EdgeInsets.all(paddingSize),
        width: componentWidth,
        height: componentHeight,
        decoration: BoxDecoration(
            color: Colors.white, border: Border.all(width: borderSize)),
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
                      for (var input in module.inputs)
                        SizedBox(
                          height: portHeight,
                          child: Center(
                            child: GestureDetector(
                              onTap: () => _toggleInputValue(input.item2),
                              onDoubleTap: () {
                                if (wiringPortSelected != null) {
                                  debugPrint(
                                      "Connected $wiringPortSelected to ${input.item1}");
                                  module.swapInputs(wiringPortSelected!,input.item2);
                                  module.callback?.call();
                                }
                                wiringPortSelected = null;
                              },
                              child: Text(input.item1,
                                  style: TextStyle(
                                      fontSize: portNameSize,
                                      fontFamily: 'Courier New',
                                      color: getColor(input.item2.value))),
                            ),
                          ),
                        )
                    ],
                  ),
                  // Output column
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var output in module.outputs)
                        SizedBox(
                          height: portHeight,
                          child: Center(
                            child: GestureDetector(
                              onDoubleTap: () {
                                if (wiringPortSelected == null) {
                                  debugPrint("Selected Output for wiring");
                                  wiringPortSelected = output.item2;
                                } else {
                                  wiringPortSelected = null;
                                  debugPrint("Deselected Output for wiring");
                                }
                              },
                              child: Text(output.item1,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: portNameSize,
                                      fontFamily: 'Courier New',
                                      color: getColor(output.item2.value))),
                            ),
                          ),
                        )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
