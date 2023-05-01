import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';
import 'package:tuple/tuple.dart';

/// Base logic type.
enum LogicValue { zero, one, z, x }

/// Operator Overloading for Logic Levels.
extension LogicOperators on LogicValue {
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

/// Logic base class, Input and Ouput inherit from Logic class
class Logic {
  String name;
  LogicValue value;
  final StreamController<LogicValueChanged> logicStreamController =
      StreamController<LogicValueChanged>.broadcast();
  Stream<LogicValueChanged> get changed => logicStreamController.stream;

  Logic({required this.name, this.value = LogicValue.x});

  void update() {
    logicStreamController.add(LogicValueChanged(value, LogicValue.x));
  }

  void inject(LogicValue newValue) =>
      SimulationUpdater.queue.addFirst(Tuple2(this, newValue));

  void put(LogicValue newValue) =>
      SimulationUpdater.queue.addLast(Tuple2(this, newValue));
}

/// Represents the event of a [Logic] changing value.
class LogicValueChanged {
  /// The newly updated value of the [Logic].
  final LogicValue newValue;

  /// The previous value of the [Logic].
  final LogicValue previousValue;

  /// Represents the event of a [Logic] changing value from [previousValue]
  /// to [newValue].
  const LogicValueChanged(this.newValue, this.previousValue);

  @override
  String toString() => '$previousValue  -->  $newValue';
}

/// Module is the Uppermost class of a Logic Chip
/// created with the number of input ports and output ports
class Module {
  Function? callback;
  Map<String, Logic> inputs = {};
  Map<String, Logic> outputs = {};
  Map<String, StreamSubscription<LogicValueChanged>> subscriptions = {};
  String name;

  Module(
      {required this.name,
      required int numInputs,
      required int numOutputs,
      isPreview = false}) {
    if (isPreview) {
      for (int i = 0; i < numInputs; i++) {
        inputs["Input $i"] = Logic(name: "Input $i");
      }
      for (int i = 0; i < numOutputs; i++) {
        outputs["Output $i"] = Logic(name: "Output $i");
      }
      return;
    }
    for (int i = 0; i < numInputs; i++) {
      String portName = NameGenerator.generateName();
      inputs.putIfAbsent(portName, () => Logic(name: portName));
      subscriptions.putIfAbsent(
        portName,
        () => inputs[portName]!.changed.listen(
          (event) {
            debugPrint("$portName has been changed");
            solveLogic(event, inputs[portName]);
            callback?.call();
          },
        ),
      );
    }
    for (int i = 0; i < numOutputs; i++) {
      String portName = NameGenerator.generateName();
      outputs.putIfAbsent(portName, () => Logic(name: portName));
      subscriptions.putIfAbsent(
        portName,
        () => outputs[portName]!.changed.listen(
          (event) {
            debugPrint("${outputs.values.first.name} has been changed");
            callback?.call();
          },
        ),
      );
    }
  }

  void swapInputs(Logic newLogic, Logic oldLogic) {
    // TODO Stop pin connections from being shuffled around when making connection
    subscriptions[oldLogic.name]?.cancel();
    inputs.remove(oldLogic.name);
    inputs.putIfAbsent(newLogic.name, () => newLogic);
    subscriptions.putIfAbsent(
        newLogic.name,
        () => newLogic.changed.listen((event) {
              debugPrint("${newLogic.name} has been changed");
              solveLogic(event, newLogic);
              callback?.call();
            }));
  }

  void release() {
    subscriptions.forEach((key, value) {
      value.cancel();
    });
    subscriptions.clear();
  }

  solveLogic(LogicValueChanged change, [Logic? caller]) =>
      throw UnimplementedError("Function must be implemented by child class");
}

class Xor2Gate extends Module {
  Xor2Gate({bool isPreview = false})
      : super(
            name: "Xor2Gate",
            numInputs: 2,
            numOutputs: 1,
            isPreview: isPreview);

  @override
  solveLogic(LogicValueChanged change, [Logic? caller]) {
    outputs.values.first.put(
        inputs.values.elementAt(0).value ^ inputs.values.elementAt(1).value);
  }
}

class Or2Gate extends Module {
  Or2Gate({bool isPreview = false})
      : super(
            name: "Or2Gate", numInputs: 2, numOutputs: 1, isPreview: isPreview);

  @override
  solveLogic(LogicValueChanged change, [Logic? caller]) {
    outputs.values.first.put(
        inputs.values.elementAt(0).value | inputs.values.elementAt(1).value);
  }
}

class And2Gate extends Module {
  And2Gate({bool isPreview = false})
      : super(
            name: "And2Gate",
            numInputs: 2,
            numOutputs: 1,
            isPreview: isPreview);

  @override
  solveLogic(LogicValueChanged change, [Logic? caller]) {
    outputs.values.first.put(
        inputs.values.elementAt(0).value & inputs.values.elementAt(1).value);
  }
}

class NotGate extends Module {
  NotGate({bool isPreview = false})
      : super(
            name: "NotGate", numInputs: 1, numOutputs: 1, isPreview: isPreview);

  @override
  solveLogic(LogicValueChanged change, [Logic? caller]) {
    outputs.values.first.put(~inputs.values.elementAt(0).value);
  }
}

class FlipFlop extends Module {
  FlipFlop({bool isPreview = false})
      : super(
            name: "FlipFlop",
            numInputs: 2,
            numOutputs: 1,
            isPreview: isPreview);

  @override
  solveLogic(LogicValueChanged change, [Logic? caller]) {
    if (caller == inputs.values.first &&
        change.newValue == LogicValue.one &&
        change.previousValue == LogicValue.zero) {
      outputs.values.first.put(inputs.values.elementAt(1).value);
    }
  }
}

class NameGenerator {
  static int _portNameCounter = 0;
  static String generateName() {
    _portNameCounter++;
    return "PORT ${_portNameCounter - 1}";
  }
}

class SimulationUpdater {
  static final Queue<Tuple2<Logic, LogicValue>> queue = Queue();
  SimulationUpdater();

  static void tick() {
    if (queue.isEmpty) return;

    LogicValue old = queue.first.item1.value;
    queue.first.item1.value = queue.first.item2;
    queue.first.item1.logicStreamController
        .add(LogicValueChanged(queue.first.item2, old));
    queue.removeFirst();
  }
}
