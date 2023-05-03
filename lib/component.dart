import 'package:flutter/material.dart';
import 'main.dart';
import 'dart:math';
import 'package:Oz/logic.dart' as rohd;

rohd.Logic? wiringPortSelected;

// This should allow us to import in new modules during runtime
Map<String, Function> gateTypes = {
  'Xor2Gate': () => rohd.Xor2Gate(),
  'And2Gate': () => rohd.And2Gate(),
  'FlipFlop': () => rohd.FlipFlop(),
  'NotGate': () => rohd.NotGate(),
  'Or2Gate': () => rohd.Or2Gate(),
  'SN74LS373': () => rohd.SN74LS373(),
  'BinarySwitch': () => rohd.BinarySwitch(),
  'HexDisplay': () => rohd.HexDisplay(),
};

class Component extends StatefulWidget {
  final Type moduleType; // Add module field

  const Component({
    Key? key, // Make key nullable
    required this.moduleType, // Add module parameter
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
    module = gateTypes[widget.moduleType.toString()]!.call();
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
    if (widget.moduleType == rohd.BinarySwitch) {
      return buttonBuildOverride();
    }

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

    if (widget.moduleType == rohd.HexDisplay) {
      // TODO: clean up code
      return GestureDetector(
        onSecondaryTap: () {
          // TODO fix delete to work right
          debugPrint("deleting Gate");
          module.release();
          canvasKey.currentState!.removeComponent(widget);
        },
        child: Container(
          padding: const EdgeInsets.all(paddingSize),
          width: alignSizeToGrid(minComponentWidth =
              ((borderSize + paddingSize) * 2) +
                  max((inputNameWidth + minCenterPadding + 150), nameWidth)),
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
                                //onTap: () => _toggleInputValue(input.item2),
                                onDoubleTap: () {
                                  if (wiringPortSelected != null) {
                                    debugPrint(
                                        "Connected $wiringPortSelected to ${input.item1}");
                                    module.swapInputs(
                                        wiringPortSelected!, input.item2);
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
                    Container(
                      width: 150,
                      height: portAreaHeight,
                      color: Colors.black,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Stack(
                          children: [
                            //Creates a hex display/ nixie tube type effect
                            for (var char in "1234567890ABCDEF".characters)
                              Opacity(
                                opacity: 0.05,
                                child: Text(
                                  char,
                                  style: const TextStyle(
                                    fontSize: 1000,
                                    fontFamily: 'Consolas',
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            Text(
                              ((module.inputs[0].item2.value ==
                                              rohd.LogicValue.one
                                          ? 8
                                          : 0) +
                                      (module.inputs[1].item2.value ==
                                              rohd.LogicValue.one
                                          ? 4
                                          : 0) +
                                      (module.inputs[2].item2.value ==
                                              rohd.LogicValue.one
                                          ? 2
                                          : 0) +
                                      (module.inputs[3].item2.value ==
                                              rohd.LogicValue.one
                                          ? 1
                                          : 0))
                                  .toRadixString(16)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 1000,
                                  fontFamily: 'Consolas',
                                  color: Colors.amber,
                                  shadows: [
                                    Shadow(blurRadius: 12, color: Colors.red)
                                  ]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      );
    }

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
                              //onTap: () => _toggleInputValue(input.item2),
                              onDoubleTap: () {
                                if (wiringPortSelected != null) {
                                  debugPrint(
                                      "Connected $wiringPortSelected to ${input.item1}");
                                  module.swapInputs(
                                      wiringPortSelected!, input.item2);
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

  Widget buttonBuildOverride() {
    //TODO Figure out a better way render Button component
    return GestureDetector(
      onSecondaryTap: () {
        // TODO fix delete to work right
        debugPrint("deleting Gate");
        module.release();
        canvasKey.currentState!.removeComponent(widget);
      },
      child: Stack(
        children: [
          Container(
            width: alignSizeToGrid(50),
            height: alignSizeToGrid(50),
            color: Colors.blueGrey,
          ),
          Positioned.fill(
            top: 5,
            bottom: 5,
            left: 5,
            right: 5,
            child: GestureDetector(
              onTap: () {
                _toggleInputValue(module.inputs[0].item2);
              },
              onDoubleTap: () {
                if (wiringPortSelected == null) {
                  debugPrint("Selected Output for wiring");
                  wiringPortSelected = module.outputs[0].item2;
                } else {
                  wiringPortSelected = null;
                  debugPrint("Deselected Output for wiring");
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: getColor(module.outputs[0].item2.value),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
