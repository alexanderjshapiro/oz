import 'package:stack/stack.dart';
import 'dart:io';

void main() {
  LogicNode pwr = LogicNode.fromFile("./assets/power.prt");
  pwr.update();

  LogicNode gnd = LogicNode.fromFile("./assets/ground.prt");
  gnd.update();

  LogicNode fulladd = LogicNode.fromFile("./assets/fulladder.prt");
  fulladd.inPorts[0].connect(pwr.outPorts[0]); //A
  fulladd.inPorts[0].connect(gnd.outPorts[0]); //A this is where Ozemek would draw a skull for us
  fulladd.inPorts[0].disconnect();

  fulladd.inPorts[0].connect(pwr.outPorts[0]); //A
  fulladd.inPorts[1].connect(gnd.outPorts[0]); //B
  fulladd.inPorts[2].connect(gnd.outPorts[0]); //CIN
  fulladd.update();
  print(fulladd.outPorts);
}

/// Base logic type.
enum LogicLevel { low, high, impedance, unknown }

/// Operator Overloading for Logic Levels.
extension LogicOperators on LogicLevel {
  LogicLevel operator &(LogicLevel other) {
    if (this == LogicLevel.low || other == LogicLevel.low) {
      return LogicLevel.low;
    }
    if (this == LogicLevel.high && other == LogicLevel.high) {
      return LogicLevel.high;
    }
    return LogicLevel.unknown;
  }

  LogicLevel operator |(LogicLevel other) {
    if (this == LogicLevel.high || other == LogicLevel.high) {
      return LogicLevel.high;
    }
    if (this == LogicLevel.low && other == LogicLevel.low) {
      return LogicLevel.low;
    }
    return LogicLevel.unknown;
  }

  LogicLevel operator ~() {
    if (this == LogicLevel.high) return LogicLevel.low;
    if (this == LogicLevel.low) return LogicLevel.high;
    return LogicLevel.unknown;
  }

  LogicLevel operator ^(LogicLevel other) {
    if (this == LogicLevel.high && other == LogicLevel.high) {
      return LogicLevel.low;
    }
    if (this == LogicLevel.low && other == LogicLevel.low) {
      return LogicLevel.low;
    }
    if (this == LogicLevel.high && other == LogicLevel.low) {
      return LogicLevel.high;
    }
    if (this == LogicLevel.low && other == LogicLevel.high) {
      return LogicLevel.high;
    }
    return LogicLevel.unknown;
  }
}

/// Port base class, Input and Ouput inherit from Port class
abstract class Port {
  String name;
  LogicLevel _level = LogicLevel.unknown;
  late LogicNode _parent;

  Port() : name = Port.generateName();

  @override
  String toString() {
    return "Name: $name Level: $_level";
  }

  /// Return a unique string to initilize the name of the port
  static int portNameCounter = 0;
  static String generateName() {
    portNameCounter++;
    return "PORT ${portNameCounter - 1}";
  }

  /// Link two ports together so an input can read in a value
  List<Port> connections = [];
  void connect(Port connection){
    connections.add(connection);
    connection.connections.add(this);
  }

  /// Undoes the connection between ports
  void disconnect(){
    for(Port conn in connections){
      conn.connections.remove(this);
    }
    connections = [];
  }

  /// Getter function for the underlining Logic Level of a Port
  LogicLevel getValue() {
    return _level;
  }
  
}

/// Output Port of a logic chip.
class OutputPort extends Port {
  List<String> logicalEquation = ["G"];

  @override
  String toString() {
    return "${super.toString()} Equation: $logicalEquation";
  }

  /// Given A logical equation in RPN, resolve it by reading the input pins of a logic node and applying the appropriate logical funtions
  /// A malformed equation will throw an exception.
  void resolve() {
    Stack<LogicLevel> operatorStack = Stack();
    for (var operator in logicalEquation) {
      LogicLevel firstOp = LogicLevel.unknown;
      LogicLevel secondOp = LogicLevel.unknown;
      if (int.tryParse(operator) != null) {
        // Add value of port to operator stack
        operatorStack
            .push(_parent.inPorts.elementAt(int.parse(operator)).getValue());
      } else if (operator == "^") {
        firstOp = operatorStack.pop();
        secondOp = operatorStack.pop();
        operatorStack.push(firstOp ^ secondOp);
      } else if (operator == "&") {
        firstOp = operatorStack.pop();
        secondOp = operatorStack.pop();
        operatorStack.push(firstOp & secondOp);
      } else if (operator == "|") {
        firstOp = operatorStack.pop();
        secondOp = operatorStack.pop();
        operatorStack.push(firstOp | secondOp);
      } else if (operator == "~") {
        firstOp = operatorStack.pop();
        operatorStack.push(~firstOp);
      } else if (operator == "H") {
        operatorStack.push(LogicLevel.high);
      } else if (operator == "L") {
        operatorStack.push(LogicLevel.low);
      } else {
        // Panic here
        throw Exception('Invalid operator in logic equation');
      }
    }
    if (operatorStack.size() != 1) {
      throw Exception('More than one operator remaining in stack');
    }
    _level = operatorStack.top();
  }
}

/// Input Port of a logic chip.
class InputPort extends Port {
  @override
  LogicLevel getValue() {
    if (connections.isEmpty) return LogicLevel.impedance;
     //TODO: check if all values are equal, if they are return that value instead of unknown
    if (connections.length != 1) return LogicLevel.unknown;
    return connections[0].getValue();
  }
}

/// LogicNode is the Uppermost class of a Logic Chip
/// created with the number of input ports and output ports
class LogicNode {
  late List<InputPort> inPorts;
  late List<OutputPort> outPorts;
  late String name;
  LogicNode(int numInputs, int numOutputs) {
    inPorts = List<InputPort>.generate(numInputs, (_) => InputPort());
    outPorts = List<OutputPort>.generate(numOutputs, (_) => OutputPort());
    for (OutputPort outPort in outPorts) {
      outPort._parent = this;
    }
  }

  /// Read in the configuration for a part from a file
  /// First line should be the name of the part, one word allowed
  /// Second line is space seperated list of input port names
  /// Third line is space seperated list of output port names
  /// Following lines are RPN logical equation with space seperated elements
  /// input ports are accessed by index, H = logicHigh, L = logicLow
  /// Operators supported: ^,&,|,~
  LogicNode.fromFile(String filePath) {
    List<String> lines = File(filePath).readAsLinesSync();
    name = lines[0];
    List<String> inNames = lines[1].split(' ');
    List<String> outNames = lines[2].split(' ');
    inPorts = List<InputPort>.generate(inNames.length, (index) => InputPort());
    for (int i = 0; i < inPorts.length; i++) {
      inPorts[i]._parent = this;
      inPorts[i].name = inNames[i];
    }
    outPorts = List<OutputPort>.generate(outNames.length, (index) => OutputPort());
    for (int i = 0; i < outPorts.length; i++) {
      outPorts[i]._parent = this;
      outPorts[i].name = outNames[i];
      outPorts[i].logicalEquation = lines[i + 3].split(' ');
    }
  }

  /// Update the output ports of the chip by resolving each ports logical equation
  void update() {
    for (int i = 0; i < outPorts.length; i++) {
      outPorts[i].resolve();
    }
  }
}
