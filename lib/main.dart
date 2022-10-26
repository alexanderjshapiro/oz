import 'package:flutter/material.dart';

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
  String _whichDropped = 'none';
  Offset offset = Offset.zero;

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
                        Positioned(
                          left: (offset.dx/gridSize).roundToDouble()*gridSize,
                          top: (offset.dy/gridSize).roundToDouble()*gridSize,
                          child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              offset = Offset(offset.dx + details.delta.dx, offset.dy + details.delta.dy);
                            });
                          },
                          child: Container(width: 100, height: 100, color: Colors.blue),
                          ),
                        )
                      ])
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status:'),
                      Text('$offset'),
                      Text('$_whichDropped'),
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
