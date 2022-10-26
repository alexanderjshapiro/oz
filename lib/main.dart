import 'package:flutter/material.dart';

import 'component.dart';

const double toolbarIconSize = 48;
const double gridSize = 20;

void main() {
  runApp(const Oz());
}

class Oz extends StatelessWidget {
  const Oz({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Oz'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Component> components = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
        Container(
          color: Colors.white,
          child:
            Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black))
                  ),
                  child:
                  Row(
                    children: const [
                      Text('Toolbar'),
                      Icon(Icons.square_outlined, size: toolbarIconSize),
                      Icon(Icons.square_outlined, size: toolbarIconSize),
                      Icon(Icons.square_outlined, size: toolbarIconSize),
                      Icon(Icons.square_outlined, size: toolbarIconSize),
                      Icon(Icons.square_outlined, size: toolbarIconSize),
                    ],
                  ),
                ),
                Expanded(child:
                Row(
                  children: [
                    Expanded(child:
                      Stack(children: <Widget>[
                        GridPaper(
                          divisions: 1,
                          subdivisions: 1,
                          interval: gridSize,
                          color: Colors.black12,
                          child: Container(),
                        ),
                        DragTarget<Component>(
                          builder: (BuildContext context, List candidate, List rejected) {
                            return Stack(children: components.isNotEmpty ? components : [Container()]);
                          },
                          onWillAccept: (data) {
                            return true;
                          },
                          onAccept: (data) {
                            setState(() {
                              components.add(data);
                            });
                          },
                        )
                      ])
                    ),
                    Container(
                      decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.black))
                      ),
                      child:
                      Column(
                        children: [
                          Text('Library'),
                          Draggable(
                            data: Component(name: 'square', color: Colors.red),
                            feedback: Container(height: 100, width: 100, color: Colors.red),
                            childWhenDragging: Container(height: 100, width: 100, color: Colors.redAccent),
                            child: Container(height: 100, width: 100, color: Colors.red),
                          ),
                          Draggable(
                            data: Component(name: 'circle', color: Colors.green),
                            feedback: Container(height: 100, width: 100, color: Colors.green),
                            childWhenDragging: Container(height: 100, width: 100, color: Colors.greenAccent),
                            child: Container(height: 100, width: 100, color: Colors.green),
                          ),
                          Draggable(
                            data: Component(name: 'circle', color: Colors.blue),
                            feedback: Container(height: 100, width: 100, color: Colors.blue),
                            childWhenDragging: Container(height: 100, width: 100, color: Colors.blueAccent),
                            child: Container(height: 100, width: 100, color: Colors.blue),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black))
                  ),
                  child:
                  Row(
                    children: [
                      const Text('Status:'),
                      const Spacer(),
                      Text('Last State Update: ${DateTime.now()}')
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
