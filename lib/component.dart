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
  BinarySwitch: 'BinarySwitch',
  HexDisplay: 'HexDisplay',
  NotGate: 'NotGate',
  Nor2Gate: 'Nor2Gate',
  Xor2Gate: 'Xor2Gate',
  SN74LS373: 'SN74LS373',
  SN74LS245: 'SN74LS245',
  SRAM6116: 'SRAM6116',
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
  static const double componentNameSize = 28.0;
  static const double portNameSize = 24.0;
  static const double paddingSize = 8.0; // around edge of component
  static const double borderSize = 2.0;
  static const double minCenterPadding =
      16.0; // between input and output columns

  static const portNameTextStyle =
      TextStyle(fontSize: portNameSize, fontFamily: 'Courier New');

  late Module module; // Add module field

  /// Data structure: `{'left': List<Offset>, 'right': List<Offset>}`
  final Map<String, List<Offset>> _portOffsets = {};

  Map<String, List<Offset>> get portOffsets => _portOffsets;

  @override
  void initState() {
    super.initState();
    module = gateTypes[gateNames[widget.moduleType]]!.call();
    module.guiUpdateCallback = () {
      if (mounted) {
        setState(() {});
      } else {
        module.delete();
        debugPrint('Uh Oh, Someone has a bug in the code');
      }
    };
  }

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

  static double alignSizeToGrid(double size, {double div = 1}) {
    return size + ((gridSize / div) - (size % (gridSize / div)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moduleType == BinarySwitch) {
      _portOffsets['left'] = const [Offset(0, gridSize), Offset(gridSize, 0)];
      _portOffsets['right'] = const [
        Offset(gridSize * 2, gridSize),
        Offset(gridSize, gridSize * 2)
      ];
      return buttonBuildOverride();
    }

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

    double leftPortsNameWidth = 0; // Width of longest input name
    for (final port in module.leftPorts) {
      TextSpan span = TextSpan(style: portNameTextStyle, text: port.portName);
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr);
      tp.layout();
      if (tp.width > leftPortsNameWidth) leftPortsNameWidth = tp.width;
      if (tp.height > portNameHeight) portNameHeight = tp.height;
    }

    double rightPortsNameWidth = 0; // Width of longest output name
    for (final port in module.rightPorts) {
      TextSpan span = TextSpan(style: portNameTextStyle, text: port.portName);
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr);
      tp.layout();
      if (tp.width > rightPortsNameWidth) rightPortsNameWidth = tp.width;
      if (tp.height > portNameHeight) portNameHeight = tp.height;
    }

    double minComponentWidth = ((borderSize + paddingSize) * 2) +
        max((leftPortsNameWidth + minCenterPadding + rightPortsNameWidth),
            nameWidth);
    double componentWidth =
        alignSizeToGrid(minComponentWidth); // round up to next grid division

    double minNameAreaHeight = nameHeight;
    double nameAreaHeight = alignSizeToGrid(minNameAreaHeight, div: 2) +
        (gridSize / 2); // round up to next half-grid division

    double minPortHeight = portNameHeight;
    double portHeight = alignSizeToGrid(minPortHeight);

    _portOffsets['left'] = [
      for (int i = 0; i < module.leftPorts.length; i++)
        Offset(0, nameAreaHeight + (gridSize / 2) + (portHeight * i))
    ];
    _portOffsets['right'] = [
      for (int i = 0; i < module.rightPorts.length; i++)
        Offset(
            componentWidth, nameAreaHeight + (gridSize / 2) + (portHeight * i))
    ];

    int numLines = max(module.leftPorts.length, module.rightPorts.length);
    double minPortAreaHeight = (portHeight * numLines);
    double portAreaHeight = alignSizeToGrid(minPortAreaHeight, div: 2);

    double componentHeight = nameAreaHeight + portAreaHeight;

    if (widget.moduleType == HexDisplay) {
      return Container(
        padding: const EdgeInsets.all(paddingSize),
        width: alignSizeToGrid(minComponentWidth =
            ((borderSize + paddingSize) * 2) +
                max((leftPortsNameWidth + minCenterPadding + 150), nameWidth)),
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
                              child: Text(port.portName,
                                  style: portNameTextStyle)),
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
                          for (var char in '1234567890ABCDEF'.characters)
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
                            (module.leftPorts.any(
                                    (element) => element.value == LogicValue.x)
                                ? '?'
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
                      for (var port in module.leftPorts)
                        SizedBox(
                            width: leftPortsNameWidth,
                            height: portHeight,
                            child: Text(port.portName,
                                textAlign: TextAlign.right,
                                style: portNameTextStyle))
                    ]),
                // Right side column (normally outputs)
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var port in module.rightPorts)
                      SizedBox(
                          width: rightPortsNameWidth,
                          height: portHeight,
                          child: Text(port.portName,
                              textAlign: TextAlign.right,
                              style: portNameTextStyle))
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
    return SizedBox(
      height: gridSize * 2,
      width: gridSize * 2,
      child: Stack(
        children: [
          Container(
            width: gridSize * 2,
            height: 2,
            color: Colors.black,
            margin: const EdgeInsets.only(top: gridSize - 1),
          ),
          Container(
            width: 2,
            height: gridSize * 2,
            color: Colors.black,
            margin: const EdgeInsets.only(left: gridSize - 1),
          ),
          Center(
            child: SizedBox(
                width: gridSize,
                height: gridSize,
                child: ElevatedButton(
                  onPressed: () {
                    for (var port in module.ports) {
                      _toggleInputValue(port);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                      padding: EdgeInsets.zero),
                  child: Text(
                    module.ports[0].value == LogicValue.one ? 'H' : 'L',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
