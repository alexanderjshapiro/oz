import 'package:flutter/material.dart';

const double toolbarIconSize = 36;

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
  int _counter = 0;
  String _whichDropped = 'none';

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

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
                      Icon(Icons.square_outlined, size: 36),
                      Icon(Icons.square_outlined, size: 36),
                      Icon(Icons.square_outlined, size: 36),
                      Icon(Icons.square_outlined, size: 36),
                      Icon(Icons.square_outlined, size: 36),
                    ],
                  ),
                ),
                Expanded(child:
                Row(
                  children: [
                    Expanded(child:
                    GridPaper(
                      divisions: 1,
                      subdivisions: 1,
                      interval: 20.0,
                      color: Colors.black12,
                      child:
                          DragTarget<String>(
                            builder: (BuildContext context, List accepted, List rejected) {
                              return _whichDropped == 'square' ? Icon(Icons.square, size: 256) : _whichDropped == 'circle' ? Icon(Icons.circle, size: 256) : Container();
                            },
                            onWillAccept: (data) {
                              return data == 'square' || data == 'circle';
                            },
                            onAccept: (data) {
                              setState(() {
                                _whichDropped = data;
                              });
                            },
                          )
                    ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.black))
                      ),
                      child:
                      Column(
                        children: const [
                          Text('Library'),
                          Draggable(
                            data: 'square',
                            feedback: Icon(Icons.square_outlined, size: 256),
                            childWhenDragging: Icon(Icons.square, size: 256, color: Colors.grey),
                            child: Icon(Icons.square, size: 256),
                          ),
                          Draggable(
                            data: 'circle',
                            feedback: Icon(Icons.circle_outlined, size: 256),
                            childWhenDragging: Icon(Icons.circle, size: 256, color: Colors.grey),
                            child: Icon(Icons.circle, size: 256),
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
                    children: const [Text('Status Bar')],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
