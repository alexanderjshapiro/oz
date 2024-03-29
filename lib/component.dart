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
  'Buffer': () => BufferGate(),
  'TriBuffer': () => TriStateBuffer(),
  'And2Gate': () => And2Gate(),
  'Nand2Gate': () => Nand2Gate(),
  'Or2Gate': () => Or2Gate(),
  'Mux2Gate': () => Mux2Gate(),
  'SN74LS138': () => SN74LS138(),
  'LightBulb': () => LightBulb(),
  'AnalogSwitch': () => AnalogSwitch(),
  'KeyBoard': () => KeyBoard(),
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
  BufferGate: 'Buffer',
  TriStateBuffer: 'TriBuffer',
  And2Gate: 'And2Gate',
  Nand2Gate: 'Nand2Gate',
  Or2Gate: 'Or2Gate',
  Mux2Gate: 'Mux2Gate',
  SN74LS138: 'SN74LS138',
  LightBulb: 'LightBulb',
  AnalogSwitch: 'AnalogSwitch',
  KeyBoard: 'KeyBoard',
};

class Component extends StatefulWidget {
  final Type moduleType; // Add module field
  final bool selected;

  const Component({
    Key? key, // Make key nullable
    required this.moduleType,
    this.selected = false, // Add module parameter
  }) : super(key: key); // Call super with nullable key

  @override
  ComponentState createState() => ComponentState();
}

class ComponentState extends State<Component> {
  static const double componentNameSize = 28.0;
  static const double portNameSize = 24.0;
  static const double paddingSize = 8.0; // around edge of component
  static const double borderSize = 2.0;
  static const double minCenterPadding =
      16.0; // between input and output columns

  late Module module; // Add module field
  late bool _selected;

  set selected(bool val) => setState(() {
        _selected = val;
      });

  /// Data structure: `{'left': List<Offset>, 'right': List<Offset>}`
  final Map<String, List<Offset>> _portOffsets = {};

  Map<String, List<Offset>> get portOffsets => _portOffsets;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;

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

  void _toggleInputValue(PhysicalPort port) {
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

  int? portIndexAt(Offset point) {
    if (widget.moduleType == BinarySwitch) return 0;
    for (int i = 0; i < _portOffsets['right']!.length; i++) {
      if (point == _portOffsets['right']![i]) {
        return module.ports.indexOf(module.rightPorts.elementAt(i));
      }
    }

    for (int i = 0; i < _portOffsets['left']!.length; i++) {
      if (point == _portOffsets['left']![i]) {
        return module.ports.indexOf(module.leftPorts.elementAt(i));
      }
    }

    return null;
  }

  static Color getColor(LogicValue logicValue) {
    switch (logicValue) {
      case LogicValue.zero:
        return Colors.red;
      case LogicValue.one:
        return Colors.green;
      case LogicValue.z:
        return Colors.yellow;
      case LogicValue.x:
        return Colors.grey;
    }
  }

  static double alignSizeToGrid(double size, {double div = 1}) {
    return size + ((gridSize / div) - (size % (gridSize / div)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moduleType == BinarySwitch) {
      _portOffsets['left'] = const [];
      _portOffsets['right'] = const [
        Offset(gridSize, gridSize),
      ];
      return buttonBuildOverride();
    }

    if (widget.moduleType == LightBulb) {
      _portOffsets['left'] = const [
        Offset(gridSize, gridSize),
      ];
      _portOffsets['right'] = const [];
      return SizedBox(
        height: gridSize * 2,
        width: gridSize * 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: gridSize / 4,
              height: 2,
              color: Colors.black,
            ),
            Container(
              width: gridSize,
              height: gridSize,
              decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                      color: _selected ? Colors.blue : Colors.black,
                      width: borderSize)),
              child: Center(
                child: Icon(
                  Icons.lightbulb,
                  color: module.ports[0].value == LogicValue.one
                      ? Colors.amber
                      : Colors.grey,
                  shadows: module.ports[0].value == LogicValue.one
                      ? [const Shadow(color: Colors.orange, blurRadius: 4)]
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.moduleType == AnalogSwitch) {
      _portOffsets['left'] = const [
        Offset(gridSize, gridSize),
      ];
      _portOffsets['right'] = const [
        Offset(2 * gridSize, gridSize),
      ];
      AnalogSwitch aSwitch = module as AnalogSwitch;
      return SizedBox(
        height: gridSize * 2,
        width: gridSize * 3,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: gridSize / 4,
              height: 2,
              color: Colors.black,
            ),
            SizedBox(
              width: gridSize,
              height: gridSize,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    aSwitch.isClosed = !aSwitch.isClosed;
                    aSwitch.update();
                  });
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.black,
                    side: BorderSide(
                        color: _selected ? Colors.blue : Colors.black),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    padding: EdgeInsets.zero),
                child: Icon(
                  aSwitch.isClosed ? Icons.flash_on : Icons.flash_off,
                  color: aSwitch.isClosed ? Colors.amber : Colors.grey,
                  shadows: aSwitch.isClosed
                      ? [const Shadow(color: Colors.orange, blurRadius: 4)]
                      : null,
                ),
              ),
            ),
            Container(
              width: gridSize / 4,
              height: 2,
              color: Colors.black,
            ),
          ],
        ),
      );
    }

    if (widget.moduleType == KeyBoard) {
      _portOffsets['left'] = [
        for (int i = 0; i < module.leftPorts.length; i++)
          Offset(gridSize, (gridSize * (i + 1)))
      ];
      _portOffsets['right'] = [
        for (int i = 0; i < module.leftPorts.length; i++)
          Offset((gridSize * (i + 2)), 5 * gridSize)
      ];
      String keys = '123A456B789C*0#D';
      KeyBoard board = module as KeyBoard;
      return SizedBox(
        height: gridSize * 6,
        width: gridSize * 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Left side ports
            Column(
              children: [
                const SizedBox(
                  height: gridSize - 1,
                ),
                for (int i = 0; i < 4; i++) ...[
                  Container(
                    width: gridSize / 4,
                    height: 2,
                    color: Colors.black,
                  ),
                  const SizedBox(
                    height: gridSize - 2,
                  ),
                ]
              ],
            ),
            Column(
              //Body of keyboard
              children: [
                Container(
                  width: gridSize * 5,
                  height: gridSize * 5,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(
                          color: _selected ? Colors.blue : Colors.black,
                          width: borderSize)),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10.0, // Add margin between rows
                      crossAxisSpacing: 10.0, // Add margin between columns
                    ),
                    itemCount: keys.characters.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          color: keys.characters
                                          .elementAt(index)
                                          .codeUnits
                                          .first >=
                                      '0'.codeUnits.first &&
                                  keys.characters
                                          .elementAt(index)
                                          .codeUnits
                                          .first <=
                                      '9'.codeUnits.first
                              ? (board.buttonPressed == index
                                  ? Colors.blue[900]
                                  : Colors.blue)
                              : (board.buttonPressed == index
                                  ? Colors.red[900]
                                  : Colors.red),
                        ),
                        child: TextButton(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(keys.characters.elementAt(index),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900))),
                          onPressed: () {
                            setState(() {
                              if (board.buttonPressed != null) {
                                board.buttonPressed =
                                    board.buttonPressed == index ? null : index;
                              } else {
                                board.buttonPressed = index;
                              }
                              board.update();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                //Bottom side ports
                Row(
                  children: [
                    const SizedBox(
                      width: gridSize - 1,
                    ),
                    for (int i = 0; i < 4; i++) ...[
                      Container(
                        height: gridSize / 4,
                        width: 2,
                        color: Colors.black,
                      ),
                      const SizedBox(
                        width: gridSize - 2,
                      ),
                    ]
                  ],
                )
              ],
            )
          ],
        ),
      );
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
      TextSpan span = TextSpan(
          style: const TextStyle(
              fontSize: portNameSize, fontFamily: 'Courier New'),
          text: port.portName);
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
      TextSpan span = TextSpan(
          style: const TextStyle(
              fontSize: portNameSize, fontFamily: 'Courier New'),
          text: port.portName);
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
        Offset(gridSize, nameAreaHeight + (gridSize / 2) + (portHeight * i))
    ];
    _portOffsets['right'] = [
      for (int i = 0; i < module.rightPorts.length; i++)
        Offset(gridSize + componentWidth,
            nameAreaHeight + (gridSize / 2) + (portHeight * i))
    ];

    int numLines = max(module.leftPorts.length, module.rightPorts.length);
    double minPortAreaHeight = (portHeight * numLines);
    double portAreaHeight = alignSizeToGrid(minPortAreaHeight, div: 2);

    double componentHeight = nameAreaHeight + portAreaHeight;

    if (widget.moduleType == HexDisplay) {
      return SizedBox(
        width: alignSizeToGrid(minComponentWidth = ((borderSize + paddingSize) *
                    2) +
                max((leftPortsNameWidth + minCenterPadding + 150), nameWidth)) +
            gridSize * 2,
        height: componentHeight,
        child: Stack(
          children: <Widget>[
                for (int i = 0; i < module.leftPorts.length; i++)
                  Container(
                    width: gridSize / 4,
                    height: 2,
                    color: Colors.black,
                    margin: EdgeInsets.only(
                        top: gridSize * (i + 2) - 1, left: gridSize * 3 / 4),
                  )
              ] +
              <Widget>[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(paddingSize),
                    width: alignSizeToGrid(minComponentWidth =
                        ((borderSize + paddingSize) * 2) +
                            max((leftPortsNameWidth + minCenterPadding + 150),
                                nameWidth)),
                    height: componentHeight,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: _selected ? Colors.blue : Colors.black,
                            width: borderSize)),
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
                                              style: TextStyle(
                                                  fontSize: portNameSize,
                                                  fontFamily: 'Courier New',
                                                  color: colorMode
                                                      ? getColor(port.value)
                                                      : null))),
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
                                      for (var char
                                          in '1234567890ABCDEF'.characters)
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
                                        (module.leftPorts.any((element) =>
                                                element.value == LogicValue.x)
                                            ? '?'
                                            : ((module.ports[0].value ==
                                                            LogicValue.one
                                                        ? 8
                                                        : 0) +
                                                    (module.ports[1].value ==
                                                            LogicValue.one
                                                        ? 4
                                                        : 0) +
                                                    (module.ports[2].value ==
                                                            LogicValue.one
                                                        ? 2
                                                        : 0) +
                                                    (module.ports[3].value ==
                                                            LogicValue.one
                                                        ? 1
                                                        : 0))
                                                .toRadixString(16)
                                                .toUpperCase()),
                                        style: const TextStyle(
                                            fontSize: 1000,
                                            fontFamily: 'Consolas',
                                            color: Colors.amber,
                                            shadows: [
                                              Shadow(
                                                  blurRadius: 12,
                                                  color: Colors.red)
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
                ),
              ],
        ),
      );
    }

    return SizedBox(
      width: componentWidth + gridSize * 2,
      height: componentHeight,
      child: Stack(
          children: <Widget>[
                for (int i = 0; i < module.leftPorts.length; i++)
                  module.leftPorts.elementAt(i).portName.contains("'")
                      ? Container(
                          width: gridSize / 4,
                          height: gridSize / 4,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.black, width: 2)),
                          margin: EdgeInsets.only(
                              top: gridSize * (i + 2) - (gridSize / 4 / 2),
                              left: gridSize * 3 / 4),
                        )
                      : Container(
                          width: gridSize / 4,
                          height: 2,
                          color: Colors.black,
                          margin: EdgeInsets.only(
                              top: gridSize * (i + 2) - 1,
                              left: gridSize * 3 / 4),
                        )
              ] +
              <Widget>[
                for (int i = 0; i < module.rightPorts.length; i++)
                  module.rightPorts.elementAt(i).portName.contains("'")
                      ? Container(
                          width: gridSize / 4,
                          height: gridSize / 4,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.black, width: 2)),
                          margin: EdgeInsets.only(
                              top: gridSize * (i + 2) - (gridSize / 4 / 2),
                              left: componentWidth + gridSize),
                        )
                      : Container(
                          width: gridSize / 4,
                          height: 2,
                          color: Colors.black,
                          margin: EdgeInsets.only(
                              top: gridSize * (i + 2) - 1,
                              left: componentWidth + gridSize),
                        )
              ] +
              <Widget>[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(paddingSize),
                    width: componentWidth,
                    height: componentHeight,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: _selected ? Colors.blue : Colors.black,
                            width: borderSize)),
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
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                  fontSize: portNameSize,
                                                  fontFamily: 'Courier New',
                                                  color: colorMode
                                                      ? getColor(port.value)
                                                      : null)))
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
                                        child: Text(
                                          port.portName,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontSize: portNameSize,
                                              fontFamily: 'Courier New',
                                              color: colorMode
                                                  ? getColor(port.value)
                                                  : null),
                                        ))
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ]),
    );
  }

  Widget buttonBuildOverride() {
    return SizedBox(
      height: gridSize * 2,
      width: gridSize * 2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
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
                    side: BorderSide(
                        color: _selected ? Colors.blue : Colors.black),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    padding: EdgeInsets.zero),
                child: Text(
                  module.ports[0].value == LogicValue.one
                      ? 'H'
                      : module.ports[0].value == LogicValue.zero
                          ? 'L'
                          : module.ports[0].value == LogicValue.z
                              ? 'Z'
                              : 'X',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w900),
                ),
              )),
          Container(
            width: gridSize / 4,
            height: 2,
            color: Colors.black,
          ),
        ],
      ),
    );
  }
}
