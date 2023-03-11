import 'logic.dart';
import 'package:test/test.dart';

void main(){
  test("LogicLevel And", (){
    expect(LogicLevel.low  & LogicLevel.low,       LogicLevel.low);
    expect(LogicLevel.low  & LogicLevel.high,      LogicLevel.low);
    expect(LogicLevel.low  & LogicLevel.impedance, LogicLevel.low);
    expect(LogicLevel.low  & LogicLevel.unknown,   LogicLevel.low);

    expect(LogicLevel.high  & LogicLevel.low,       LogicLevel.low);
    expect(LogicLevel.high  & LogicLevel.high,      LogicLevel.high);
    expect(LogicLevel.high  & LogicLevel.impedance, LogicLevel.unknown);
    expect(LogicLevel.high  & LogicLevel.unknown,   LogicLevel.unknown);

    expect(LogicLevel.unknown  & LogicLevel.low,       LogicLevel.low);
    expect(LogicLevel.unknown  & LogicLevel.high,      LogicLevel.unknown);
    expect(LogicLevel.unknown  & LogicLevel.impedance, LogicLevel.unknown);
    expect(LogicLevel.unknown  & LogicLevel.unknown,   LogicLevel.unknown);

    expect(LogicLevel.impedance  & LogicLevel.low,       LogicLevel.low);
    expect(LogicLevel.impedance  & LogicLevel.high,      LogicLevel.unknown);
    expect(LogicLevel.impedance  & LogicLevel.impedance, LogicLevel.unknown);
    expect(LogicLevel.impedance  & LogicLevel.unknown,   LogicLevel.unknown);
  });

  test("LogicLevel Not", (){
    expect(~LogicLevel.high, LogicLevel.low);
    expect(~LogicLevel.low, LogicLevel.high);
    expect(~LogicLevel.unknown, LogicLevel.unknown);
    expect(~LogicLevel.impedance, LogicLevel.unknown);
  });
}