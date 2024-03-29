import 'package:flutter/material.dart';
import 'dart:collection';
import 'waveform.dart';

class Xor2Gate extends Module {
  Xor2Gate() : super(name: 'Xor2Gate') {
    ports = [
      for (int i = 0; i < 2; i++)
        PhysicalPort(
            portName: 'In $i',
            module: this,
            portLocation: PortLocation.left,
            initalState: LogicValue.z),
      for (int i = 0; i < 1; i++)
        PhysicalPort(
            portName: 'Out $i', module: this, portLocation: PortLocation.right)
    ];
  }

  @override
  update() {
    ports[2].drivePort(ports[0].value ^ ports[1].value);
  }
}

class NotGate extends Module {
  NotGate() : super(name: 'NotGate') {
    ports = [
      for (int i = 0; i < 1; i++)
        PhysicalPort(
            portName: 'In $i',
            module: this,
            portLocation: PortLocation.left,
            initalState: LogicValue.z),
      for (int i = 0; i < 1; i++)
        PhysicalPort(
            portName: 'Out $i', module: this, portLocation: PortLocation.right)
    ];
  }

  @override
  update() {
    ports[1].drivePort(~ports[0].value);
  }
}

class BufferGate extends Module {
  BufferGate() : super(name: 'Buffer') {
    ports = [
      for (int i = 0; i < 1; i++)
        PhysicalPort(
            portName: 'In $i',
            module: this,
            portLocation: PortLocation.left,
            initalState: LogicValue.z),
      for (int i = 0; i < 1; i++)
        PhysicalPort(
            portName: 'Out $i', module: this, portLocation: PortLocation.right)
    ];
  }

  @override
  update() {
    ports[1].drivePort(ports[0].value);
  }
}

class Mux2Gate extends Module {
  Mux2Gate() : super(name: 'Mux2Gate') {
    ports = [
      for (int i = 0; i < 2; i++)
        PhysicalPort(
            portName: 'In $i',
            module: this,
            portLocation: PortLocation.left,
            initalState: LogicValue.z),
      PhysicalPort(
          portName: 'Sel', module: this, portLocation: PortLocation.left),
      PhysicalPort(
          portName: 'Out', module: this, portLocation: PortLocation.right)
    ];
  }

  @override
  update() {
    if (ports[2].value == LogicValue.x || ports[2].value == LogicValue.z) {
      ports[3].drivePort(LogicValue.z);
    }
    ports[3].drivePort(
        ports[2].value == LogicValue.zero ? ports[0].value : ports[1].value);
  }
}

class SN74LS138 extends Module {
  SN74LS138() : super(name: 'SN74LS138') {
    ports = [
      PhysicalPort(
          portName: 'G1',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: "G2A'",
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: "G2B'",
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: 'A',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: 'B',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: 'C',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      for (int i = 0; i < 8; i++)
        PhysicalPort(
            portName: "Y$i'", module: this, portLocation: PortLocation.right)
    ];
  }

  @override
  update() {
    if (ports.firstWhere((element) => element.portName == 'G1').value !=
            LogicValue.one ||
        ports.firstWhere((element) => element.portName == "G2A'").value !=
            LogicValue.zero ||
        ports.firstWhere((element) => element.portName == "G2B'").value !=
            LogicValue.zero) {
      for (int i = 6; i < 14; i++) {
        ports[i].queueDrivePort(LogicValue.one);
      }
      SimulationUpdater.submitStage(key);
    } else {
      int address = 0;
      for (int i = 0; i < 3; i++) {
        if (ports[i + 3].value == LogicValue.one) {
          address |= (1 << i);
        }
      }
      int mask = ~(1 << address);
      for (int i = 6; i < 14; i++) {
        ports[i]
            .queueDrivePort(mask & 1 == 1 ? LogicValue.one : LogicValue.zero);
        mask >>= 1;
      }
      SimulationUpdater.submitStage(key);
    }
  }
}

class TriStateBuffer extends Module {
  TriStateBuffer() : super(name: 'TriStateBuffer') {
    ports = [
      PhysicalPort(
          portName: 'In',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: 'En',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: 'Out', module: this, portLocation: PortLocation.right)
    ];
  }

  @override
  update() {
    if (ports.firstWhere((element) => element.portName == 'En').value ==
        LogicValue.zero) {
      ports[2].drivePort(LogicValue.z);
    } else {
      ports[2].drivePort(ports[0].value);
    }
  }
}

//OCTAL BUS TRANSCEIVERS WITH 3-STATE OUTPUTS
class SN74LS245 extends Module {
  SN74LS245() : super(name: 'SN74LS245') {
    ports = [
      for (int i = 0; i < 8; i++)
        PhysicalPort(
            portName: 'A$i', module: this, portLocation: PortLocation.left),
      for (int i = 0; i < 8; i++)
        PhysicalPort(
            portName: 'B$i', module: this, portLocation: PortLocation.right),
      PhysicalPort(
          portName: 'DIR', module: this, portLocation: PortLocation.left),
      PhysicalPort(
          portName: "OE'", module: this, portLocation: PortLocation.left),
    ];
  }

  @override
  update() {
    if (ports.firstWhere((element) => element.portName == "OE'").value ==
        LogicValue.one) {
      for (int i = 0; i < 16; i++) {
        ports[i].queueDrivePort(LogicValue.z);
      }
      SimulationUpdater.submitStage(key);
      return;
    }

    if (ports.firstWhere((element) => element.portName == 'DIR').value ==
        LogicValue.one) {
      // transfer left side values to right side
      for (int i = 0; i < 8; i++) {
        ports[i].queueDrivePort(LogicValue.z);
      }
      for (int i = 0; i < 8; i++) {
        ports[i + 8].queueDrivePort(ports[i].value);
      }
    } else {
      // transfer right side values to left side
      for (int i = 8; i < 16; i++) {
        ports[i].queueDrivePort(LogicValue.z);
      }
      for (int i = 0; i < 8; i++) {
        ports[i].queueDrivePort(ports[i + 8].value);
      }
    }
    SimulationUpdater.submitStage(key);
  }
}

//D-Type latch
class SN74LS373 extends Module {
  SN74LS373() : super(name: 'SN74LS373') {
    ports = [
      for (int i = 0; i < 8; i++)
        PhysicalPort(
            portName: 'D$i',
            module: this,
            portLocation: PortLocation.left,
            initalState: LogicValue.z),
      for (int i = 0; i < 8; i++)
        PhysicalPort(
            portName: 'Q$i', module: this, portLocation: PortLocation.right),
      PhysicalPort(
          portName: 'EN',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
    ];
  }

  @override
  update() {
    if (ports.firstWhere((element) => element.portName == 'EN').value ==
        LogicValue.one) {
      for (int i = 0; i < 8; i++) {
        ports[i + 8].queueDrivePort(ports[i].value);
      }
      SimulationUpdater.submitStage(key);
    }
  }
}

//Static ram memory device
class SRAM6116 extends Module {
  SRAM6116() : super(name: 'SRAM6116') {
    ports = [
      for (int i = 0; i < 11; i++)
        PhysicalPort(
            portName: 'A$i',
            module: this,
            portLocation: PortLocation.left,
            initalState: LogicValue.z),
      for (int i = 0; i < 8; i++)
        PhysicalPort(
            portName: 'DIO$i', module: this, portLocation: PortLocation.right),
      PhysicalPort(
          portName: "WE'",
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: "OE'",
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: "CS'",
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
    ];
  }

//Preset the memory for testing purposes
  Map<int, List<LogicValue>> memory = {
    //andrew
    514: [
      LogicValue.one,
      LogicValue.zero,
      LogicValue.one,
      LogicValue.zero,
      LogicValue.one,
      LogicValue.one,
      LogicValue.one,
      LogicValue.zero,
    ],
    //alex
    1013: [
      LogicValue.one,
      LogicValue.zero,
      LogicValue.one,
      LogicValue.zero,
      LogicValue.zero,
      LogicValue.one,
      LogicValue.zero,
      LogicValue.one,
    ],
    //wayne
    127: [
      LogicValue.zero,
      LogicValue.zero,
      LogicValue.one,
      LogicValue.one,
      LogicValue.one,
      LogicValue.one,
      LogicValue.one,
      LogicValue.one,
    ],
  };

  @override
  update() {
    if (ports.firstWhere((element) => element.portName == "CS'").value ==
        LogicValue.one) {
      for (int i = 0; i < 8; i++) {
        ports[i + 11].queueDrivePort(LogicValue.z);
      }
      SimulationUpdater.submitStage(key);
      return;
    }
    //chip must be enabled at this point
    if (ports.firstWhere((element) => element.portName == "OE'").value ==
        LogicValue.zero) {
      //Read mode, must put data on bus
      int address = 0;
      for (int i = 0; i < 11; i++) {
        if (ports[i].value == LogicValue.one) {
          address |= (1 << i);
        }
      }
      for (int i = 0; i < 8; i++) {
        ports[i + 11].queueDrivePort(memory[address]?[i] ?? LogicValue.zero);
      }
      debugPrint('value = $address');
    } else {
      for (int i = 0; i < 8; i++) {
        ports[i + 11].queueDrivePort(LogicValue.zero);
      }
      if (ports.firstWhere((element) => element.portName == "WE'").value ==
          LogicValue.zero) {
        //Write to memory
        int address = 0;
        for (int i = 0; i < 11; i++) {
          if (ports[i].value == LogicValue.one) {
            address |= (1 << i);
          }
        }
        memory[address] = List.generate(8, (index) => ports[index + 11].value);
      }
    }
    SimulationUpdater.submitStage(key);
  }
}

class Nor2Gate extends Module {
  Nor2Gate() : super(name: 'Nor2Gate') {
    ports = [
      for (int i = 0; i < 2; i++)
        PhysicalPort(
            portName: 'In $i',
            module: this,
            portLocation: PortLocation.left,
            initalState: LogicValue.z),
      for (int i = 0; i < 1; i++)
        PhysicalPort(
            portName: 'Out $i',
            module: this,
            portLocation: PortLocation.right,
            initalState: LogicValue.x)
    ];
  }

  @override
  update() {
    ports[2].drivePort(~(ports[0].value | ports[1].value));
  }
}

class Or2Gate extends Module {
  Or2Gate() : super(name: 'Or2Gate') {
    ports = [
      for (int i = 0; i < 2; i++)
        PhysicalPort(
            portName: 'In $i',
            module: this,
            portLocation: PortLocation.left,
            initalState: LogicValue.z),
      for (int i = 0; i < 1; i++)
        PhysicalPort(
            portName: 'Out $i',
            module: this,
            portLocation: PortLocation.right,
            initalState: LogicValue.x)
    ];
  }

  @override
  update() {
    ports[2].drivePort(ports[0].value | ports[1].value);
  }
}

class And2Gate extends Module {
  And2Gate() : super(name: 'And2Gate') {
    ports = [
      for (int i = 0; i < 2; i++)
        PhysicalPort(
            portName: 'In $i',
            module: this,
            portLocation: PortLocation.left,
            initalState: LogicValue.z),
      for (int i = 0; i < 1; i++)
        PhysicalPort(
            portName: 'Out $i',
            module: this,
            portLocation: PortLocation.right,
            initalState: LogicValue.x)
    ];
  }

  @override
  update() {
    ports[2].drivePort((ports[0].value & ports[1].value));
  }
}

class Nand2Gate extends Module {
  Nand2Gate() : super(name: 'Nand2Gate') {
    ports = [
      for (int i = 0; i < 2; i++)
        PhysicalPort(
            portName: 'In $i',
            module: this,
            portLocation: PortLocation.left,
            initalState: LogicValue.z),
      for (int i = 0; i < 1; i++)
        PhysicalPort(
            portName: 'Out $i',
            module: this,
            portLocation: PortLocation.right,
            initalState: LogicValue.x)
    ];
  }

  @override
  update() {
    ports[2].drivePort(~(ports[0].value & ports[1].value));
  }
}

class Xor2GateRev extends Module {
  Xor2GateRev() : super(name: 'Xor2GateRev') {
    ports = [
      for (int i = 0; i < 1; i++)
        PhysicalPort(
            portName: 'Out $i', module: this, portLocation: PortLocation.left),
      for (int i = 0; i < 2; i++)
        PhysicalPort(
            portName: 'In $i', module: this, portLocation: PortLocation.right)
    ];
  }

  @override
  update() {
    ports[0].drivePort(ports[1].value ^ ports[2].value);
  }
}

class BinarySwitch extends Module {
  BinarySwitch() : super(name: 'BinarySwitch') {
    ports = [
      PhysicalPort(
          portName: 'Button',
          module: this,
          portLocation: PortLocation.right,
          initalState: LogicValue.zero)
    ];
  }

  @override
  update() {}
}

class LightBulb extends Module {
  LightBulb() : super(name: 'LightBulb') {
    ports = [
      PhysicalPort(
          portName: 'LightBulb',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z)
    ];
  }

  @override
  update() {}
}

class AnalogSwitch extends Module {
  bool isClosed = false;

  AnalogSwitch() : super(name: 'AnalogSwitch') {
    ports = [
      PhysicalPort(
          portName: 'LeftSide',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: 'RightSide',
          module: this,
          portLocation: PortLocation.right,
          initalState: LogicValue.z)
    ];
  }

  @override
  update() {
    if (isClosed) {
      bridgePorts(ports[0], ports[1]);
    } else {
      for (var port in ports) {
        port.queueDrivePort(LogicValue.z);
      }
    }
    SimulationUpdater.submitStage(key);
  }
}

class KeyBoard extends Module {
  int? buttonPressed;

  KeyBoard() : super(name: 'KeyBoard') {
    ports = [
      for (int i = 0; i < 4; i++)
        PhysicalPort(
            portName: 'RowLine$i',
            module: this,
            portLocation: PortLocation.left,
            initalState: LogicValue.z),
      for (int i = 0; i < 4; i++)
        PhysicalPort(
            portName: 'ColumnLine$i',
            module: this,
            portLocation: PortLocation.right,
            initalState: LogicValue.z)
    ];
  }

  int? previousKeys;

  @override
  update() {
    // Not sure why this is working as well as it is, Im sure there's a problem with it, but it seems to be working.
    if (previousKeys == buttonPressed && buttonPressed != null) {
      bridgePorts(ports[buttonPressed! ~/ 4], ports[(buttonPressed! % 4) + 4]);
      SimulationUpdater.submitStage(key);
      return;
    }
    if (previousKeys != null) {
      ports[previousKeys! ~/ 4].queueDrivePort(LogicValue.z);
      ports[(previousKeys! % 4) + 4].queueDrivePort(LogicValue.z);
    }
    if (buttonPressed != null) {
      bridgePorts(ports[buttonPressed! ~/ 4], ports[(buttonPressed! % 4) + 4]);
    } else if (previousKeys != null) {
      ports[previousKeys! ~/ 4].queueDrivePort(LogicValue.z);
      ports[(previousKeys! % 4) + 4].queueDrivePort(LogicValue.z);
    }
    previousKeys = buttonPressed;

    SimulationUpdater.submitStage(key);
  }
}

class HexDisplay extends Module {
  HexDisplay() : super(name: 'HexDisplay') {
    ports = [
      PhysicalPort(
          portName: 'B8',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: 'B4',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: 'B2',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
      PhysicalPort(
          portName: 'B1',
          module: this,
          portLocation: PortLocation.left,
          initalState: LogicValue.z),
    ];
  }

  @override
  update() {}
}

class SimulationUpdater {
  static final Queue<List<Function>> queue = Queue();
  static final Map<String, List<Function>> staging = {};

  SimulationUpdater();

  static void tick() {
    if (queue.isEmpty) return;
    for (var element in queue.first) {
      element.call();
    }
    queue.removeFirst();
    updateWaveformAnalyzer();
  }

  static void submitStage(String moduleKey) {
    if (staging[moduleKey] == null) return;
    queue.addLast(staging[moduleKey]!);
    staging.remove(moduleKey);
  }

  static void pushStage(String moduleKey, Function fun) {
    staging[moduleKey] != null
        ? staging[moduleKey]?.add(fun)
        : staging[moduleKey] = [fun];
  }
}

class Module {
  Function? guiUpdateCallback;
  String name;
  String key = KeyGen.key();
  late List<PhysicalPort> ports;

  Module({
    required this.name,
    //required this.ports,
    this.guiUpdateCallback,
  });

  update() {
    throw UnimplementedError('Function must be implemented by child class');
  }

  delete() {
    for (var port in ports) {
      port.connectedNode?.impede(portKey: port.key);
      port.connectedNode?.connectedModules.remove(port.module);
    }
  }

  //Used for switch and hex keyboard
  bridgePorts(PhysicalPort first, PhysicalPort second) {
    Set<String> a = first.connectedNode!.drivers.keys.toSet();
    a.remove(first.key);
    Set<String> b = second.connectedNode!.drivers.keys.toSet();
    b.remove(second.key);
    if (a.isNotEmpty && b.isNotEmpty) {
      //Both sides are attempting to drive, thats ok if they have the same value.
      if (second.value != first.value) {
        second.queueDrivePort(first.value);
        first.queueDrivePort(second.value);
      }
    } else {
      if (a.isNotEmpty) {
        second.queueDrivePort(first.value);
      } else if (b.isNotEmpty) {
        first.queueDrivePort(second.value);
      }
    }
  }

  Iterable get leftPorts =>
      ports.where((element) => element.portLocation == PortLocation.left);

  Iterable get rightPorts =>
      ports.where((element) => element.portLocation == PortLocation.right);
}

class PhysicalPort {
  String portName;
  PortLocation portLocation;
  String key = KeyGen.key();
  Node? connectedNode;
  Module module;

  PhysicalPort(
      {required this.portName,
      required this.module,
      this.portLocation = PortLocation.right,
      LogicValue? initalState})
      : connectedNode = Node(module, initalState);

  void connectNode(Node logic) {
    //Copy existing node info to new one.
    logic.connectedModules.addAll(connectedNode!.connectedModules
        .where((element) => logic.connectedModules.contains(element)));
    logic.drivers.addAll(connectedNode!.drivers);

    logic.connectedModules.add(module);
    connectedNode = logic;
    for (var module in logic.connectedModules.toSet()) {
      module.update();
      module.guiUpdateCallback?.call();
    }
  }

  void drivePort(LogicValue value) {
    if (connectedNode != null) {
      SimulationUpdater.queue.addLast(
          [() => connectedNode!.drive(portKey: key, driveValue: value)]);
    }
  }

  void queueDrivePort(LogicValue value) {
    if (connectedNode != null) {
      SimulationUpdater.pushStage(module.key,
          () => connectedNode!.drive(portKey: key, driveValue: value));
    }
  }

  /// Return the current logic value
  LogicValue get value => connectedNode!.value;
}

enum PortLocation { left, right }

class Node {
  //final String _key = KeyGen.key();
  LogicValue _value;
  Map<String, LogicValue> drivers = {};

  List<Module> connectedModules;

  Node([Module? module, LogicValue? initVal])
      : connectedModules = [if (module != null) module],
        _value = initVal ?? LogicValue.x;

  impede({required String portKey}) =>
      drive(portKey: portKey, driveValue: LogicValue.z);

  /// Sets the value of a logic to be the value given iff all other drivers are matching or z
  drive({required String portKey, required LogicValue driveValue}) {
    if (driveValue == LogicValue.z) {
      drivers.remove(portKey);
    } else {
      drivers[portKey] = driveValue;
    }
    List<LogicValue> drivingValues = drivers.values.toList(growable: false);
    LogicValue uniformityValue = drivingValues.firstWhere(
        (element) => element != LogicValue.z,
        orElse: () => LogicValue.z);
    if (!drivingValues.every((element) => element == uniformityValue)) {
      uniformityValue = LogicValue.x;
    }

    if (_value != uniformityValue) {
      _value = uniformityValue;
      for (var module in connectedModules.toSet()) {
        module.update();
        module.guiUpdateCallback?.call();
      }
    }
  }

  /// Return the current logic value
  LogicValue get value => _value;
}

class KeyGen {
  static int _keyCounter = 0;

  static String key([String prefix = '']) {
    _keyCounter++;
    return '$prefix${_keyCounter - 1}';
  }
}

/// Base logic type.
enum LogicValue { zero, one, z, x }

/// Operator Overloading for Node Levels.
extension NodeOperators on LogicValue {
  LogicValue operator &(LogicValue other) {
    if (this == LogicValue.zero || other == LogicValue.zero) {
      return LogicValue.zero;
    }
    if (this == LogicValue.one && other == LogicValue.one) {
      return LogicValue.one;
    }
    return LogicValue.x;
  }

  LogicValue operator |(LogicValue other) {
    if (this == LogicValue.one || other == LogicValue.one) {
      return LogicValue.one;
    }
    if (this == LogicValue.zero && other == LogicValue.zero) {
      return LogicValue.zero;
    }
    return LogicValue.x;
  }

  LogicValue operator ~() {
    if (this == LogicValue.one) return LogicValue.zero;
    if (this == LogicValue.zero) return LogicValue.one;
    return LogicValue.x;
  }

  LogicValue operator ^(LogicValue other) {
    if (this == LogicValue.one && other == LogicValue.one) {
      return LogicValue.zero;
    }
    if (this == LogicValue.zero && other == LogicValue.zero) {
      return LogicValue.zero;
    }
    if (this == LogicValue.one && other == LogicValue.zero) {
      return LogicValue.one;
    }
    if (this == LogicValue.zero && other == LogicValue.one) {
      return LogicValue.one;
    }
    return LogicValue.x;
  }
}
