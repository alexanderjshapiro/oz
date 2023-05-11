import 'package:flutter/material.dart';
import 'main.dart';
import 'dart:math';
import 'logic.dart';

//Logic? wiringPortSelected;
Node? wiringNodeSelected;

// This should allow us to import in new modules during runtime
Map<String, Function> gateTypes = {
  'BinarySwitch': () => BinarySwitch(),
  'HexDisplay': () => HexDisplay(),
  'NotGate': () => NotGate(),
  'Nor2Gate': () => Nor2Gate(),
  'Xor2Gate': () => Xor2Gate(),
  'SN74LS373': () => SN74LS373(),
  'SN74LS245': () => SN74LS245(),
  'SRAM6116': () => SRAM6116(),
};

Map<Type, String> gateNames = {
  BinarySwitch: "BinarySwitch",
  HexDisplay: "HexDisplay",
  NotGate: "NotGate",
  Nor2Gate: "Nor2Gate",
  Xor2Gate: "Xor2Gate",
  SN74LS373: "SN74LS373",
  SN74LS245: "SN74LS245",
  SRAM6116: "SRAM6116",
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
  late Module module; // Add module field
  late double height;
  late double width;

  @override
  void initState() {
    super.initState();
    module = gateTypes[gateNames[widget.moduleType]]!.call();
    module.guiUpdateCallback = () {
      if (mounted) {
        setState(() {});
      } else {
        module.delete();
        debugPrint("Uh Oh, Someone has a bug in the code");
      }
    };
  }

  void test() {}

  _toggleInputValue(PhysicalPort port) {
    if (port.value == LogicValue.zero) {
      SimulationUpdater.queue.addFirst([
        () => port.connectedNode!
            .drive(portKey: port.key, driveValue: LogicValue.one)
      ]);
    } else {
      SimulationUpdater.queue.addFirst([
        () => port.connectedNode!
            .drive(portKey: port.key, driveValue: LogicValue.zero)
      ]);
    }
  }

  Color getColor(LogicValue val) {
    if (val == LogicValue.zero) return Colors.red;
    if (val == LogicValue.one) return Colors.green;
    if (val == LogicValue.z) return Colors.yellow;
    return Colors.grey;
  }

  double alignSizeToGrid(double size, {double div = 1}) {
    return size + ((gridSize / div) - (size % (gridSize / div)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moduleType == BinarySwitch) {
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
    for (final input in module.leftSide) {
      TextSpan span = TextSpan(
          style: const TextStyle(
            fontSize: portNameSize,
            fontFamily: 'Courier New',
          ),
          text: input.portName);
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr);
      tp.layout();
      if (tp.width > inputNameWidth) inputNameWidth = tp.width;
      if (tp.height > portNameHeight) portNameHeight = tp.height;
    }

    double outputNameWidth = 0; // Width of longest output name
    for (final output in module.rightSide) {
      TextSpan span = TextSpan(
          style: const TextStyle(
            fontSize: portNameSize,
            fontFamily: 'Courier New',
          ),
          text: output.portName);
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
    int numLines = max(module.leftSide.length, module.rightSide.length);
    double minPortAreaHeight = (portHeight * numLines);
    double portAreaHeight = alignSizeToGrid(minPortAreaHeight, div: 2);

    double componentHeight = nameAreaHeight + portAreaHeight;

    height = componentHeight;
    width = componentWidth;

    if (widget.moduleType == HexDisplay) {
      return Container(
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
                      for (var port in module.ports)
                        SizedBox(
                          height: portHeight,
                          child: Center(
                            child: GestureDetector(
                              onDoubleTap: () {
                                if (wiringNodeSelected == null) {
                                  debugPrint("Selected Output for wiring");
                                  wiringNodeSelected = port.connectedNode;
                                } else if (wiringNodeSelected ==
                                    port.connectedNode) {
                                  debugPrint("Cannot connect wire to itself");
                                  wiringNodeSelected = null;
                                } else {
                                  port.connectNode(wiringNodeSelected!);
                                  wiringNodeSelected = null;
                                  debugPrint("Connected wire");
                                }
                              },
                              child: Text(port.portName,
                                  style: TextStyle(
                                      fontSize: portNameSize,
                                      fontFamily: 'Courier New',
                                      color: getColor(port.value))),
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
                            (module.leftSide.any(
                                    (element) => element.value == LogicValue.x)
                                ? "?"
                                : ((module.ports[0].value == LogicValue.one
                                            ? 8
                                            : 0) +
                                        (module.ports[1].value == LogicValue.one
                                            ? 4
                                            : 0) +
                                        (module.ports[2].value == LogicValue.one
                                            ? 2
                                            : 0) +
                                        (module.ports[3].value == LogicValue.one
                                            ? 1
                                            : 0))
                                    .toRadixString(16)
                                    .toUpperCase()),
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
      );
    }

    return Container(
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
                // Left side column (Normally inputs)
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var port in module.leftSide)
                      SizedBox(
                        height: portHeight,
                        child: Center(
                          child: GestureDetector(
                            onDoubleTap: () {
                              if (wiringNodeSelected == null) {
                                debugPrint("Selected Output for wiring");
                                wiringNodeSelected = port.connectedNode;
                              } else if (wiringNodeSelected ==
                                  port.connectedNode) {
                                debugPrint("Cannot connect wire to itself");
                                wiringNodeSelected = null;
                              } else {
                                port.connectNode(wiringNodeSelected!);
                                wiringNodeSelected = null;
                                debugPrint("Connected wire");
                              }
                            },
                            child: Text(port.portName,
                                style: TextStyle(
                                    fontSize: portNameSize,
                                    fontFamily: 'Courier New',
                                    color: getColor(port.value))),
                          ),
                        ),
                      )
                  ],
                ),
                // Right side column (normally outputs)
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var port in module.rightSide)
                      SizedBox(
                        height: portHeight,
                        child: Center(
                          child: GestureDetector(
                            onDoubleTap: () {
                              if (wiringNodeSelected == null) {
                                debugPrint("Selected Output for wiring");
                                wiringNodeSelected = port.connectedNode;
                              } else if (wiringNodeSelected ==
                                  port.connectedNode) {
                                debugPrint("Cannot connect wire to itself");
                                wiringNodeSelected = null;
                              } else {
                                port.connectNode(wiringNodeSelected!);
                                wiringNodeSelected = null;
                                debugPrint("Connected wire");
                              }
                            },
                            child: Text(port.portName,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: portNameSize,
                                    fontFamily: 'Courier New',
                                    color: getColor(port.value))),
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
    );
  }

  Widget buttonBuildOverride() {
    return Stack(
      children: [
        Container(
          width: alignSizeToGrid(10),
          height: alignSizeToGrid(10),
          color: Colors.blueGrey,
        ),
        Positioned.fill(
          top: 5,
          bottom: 5,
          left: 5,
          right: 5,
          child: GestureDetector(
            onTap: () {
              _toggleInputValue(module.ports[0]);
            },
            onDoubleTap: () {
              if (wiringNodeSelected == null) {
                debugPrint("Selected Output for wiring");
                wiringNodeSelected = module.ports[0].connectedNode;
              } else if (wiringNodeSelected == module.ports[0].connectedNode) {
                debugPrint("Cannot connect wire to itself");
                wiringNodeSelected = null;
              } else {
                module.ports[0].connectNode(wiringNodeSelected!);
                wiringNodeSelected = null;
                debugPrint("Connected wire");
              }
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: getColor(module.ports[0].value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
