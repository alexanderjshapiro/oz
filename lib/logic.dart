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
  late List<Tuple3<String, Logic, StreamSubscription<LogicValueChanged>>>
      inputs;
  late List<Tuple3<String, Logic, StreamSubscription<LogicValueChanged>>>
      outputs;
  String name;

  Module({
    required this.name,
    required int numInputs,
    required int numOutputs,
  }) {
    inputs = List.generate(numInputs, (index) {
      Logic logic =
          Logic(name: PortKeyGen.generateKey(), value: LogicValue.z);
      StreamSubscription<LogicValueChanged> sub = logic.changed.listen(
        (event) {
          //debugPrint("${logic.name} has been changed");
          solveLogic(event, logic);
          callback?.call();
        },
      );
      return Tuple3("In $index", logic, sub);
    });

    outputs = List.generate(numOutputs, (index) {
      Logic logic =
          Logic(name: PortKeyGen.generateKey(), value: LogicValue.x);
      StreamSubscription<LogicValueChanged> sub = logic.changed.listen(
        (event) {
          //debugPrint("${logic.name} has been changed");
          callback?.call();
        },
      );
      return Tuple3("Out $index", logic, sub);
    });
  }

  void swapInputs(Logic newLogic, Logic oldLogic) {
    var matchingTuple = inputs.indexWhere((tuple) => tuple.item2 == oldLogic);
    inputs[matchingTuple].item3.cancel();
    StreamSubscription<LogicValueChanged> sub = newLogic.changed.listen(
      (event) {
        //debugPrint("${newLogic.name} has been changed");
        solveLogic(event, newLogic);
        callback?.call();
      },
    );
    inputs[matchingTuple] = Tuple3(inputs[matchingTuple].item1, newLogic, sub);
  }

  void release() {
    for (var element in inputs) {
      element.item3.cancel();
    }
    for (var element in outputs) {
      element.item3.cancel();
    }
  }

  solveLogic(LogicValueChanged change, [Logic? caller]) =>
      throw UnimplementedError("Function must be implemented by child class");
}

class Xor2Gate extends Module {
  Xor2Gate()
      : super(
          name: "Xor2Gate",
          numInputs: 2,
          numOutputs: 1,
        );

  @override
  solveLogic(LogicValueChanged change, [Logic? caller]) =>
      outputs[0].item2.put(inputs[0].item2.value ^ inputs[1].item2.value);
}

class Or2Gate extends Module {
  Or2Gate() : super(name: "Or2Gate", numInputs: 2, numOutputs: 1);

  @override
  solveLogic(LogicValueChanged change, [Logic? caller]) =>
      outputs[0].item2.put(inputs[0].item2.value | inputs[1].item2.value);
}

class And2Gate extends Module {
  And2Gate()
      : super(
          name: "And2Gate",
          numInputs: 2,
          numOutputs: 1,
        );

  @override
  solveLogic(LogicValueChanged change, [Logic? caller]) =>
      outputs[0].item2.put(inputs[0].item2.value & inputs[1].item2.value);
}

class NotGate extends Module {
  NotGate({bool isPreview = false})
      : super(name: "NotGate", numInputs: 1, numOutputs: 1);

  @override
  solveLogic(LogicValueChanged change, [Logic? caller]) =>
      outputs[0].item2.put(~inputs[0].item2.value);
}

class FlipFlop extends Module {
  FlipFlop({bool isPreview = false})
      : super(
          name: "FlipFlop",
          numInputs: 2,
          numOutputs: 1,
        );

  @override
  solveLogic(LogicValueChanged change, [Logic? caller]) {
    if (caller == inputs[0].item2 &&
        change.newValue == LogicValue.one &&
        change.previousValue == LogicValue.zero) {
      outputs[0].item2.put(inputs[1].item2.value);
    }
  }
}

class PortKeyGen {
  static int _portCounter = 0;
  static String generateKey() {
    _portCounter++;
    return "${_portCounter - 1}";
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
