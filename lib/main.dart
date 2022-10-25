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
  bool _isDropped = false;

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
        Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black
                  ),
                )
              ),
              child:
                Row(
                  children: const [Text('Toolbar')],
                ),
            ),
            Expanded(child: 
              Row(
                children: [
                  Expanded(child: 
                    Center(
                      child: Container(
                        child: DragTarget<String>(
                          builder: (
                            BuildContext context,
                            List accepted,
                            List rejected,
                          ) {
                            return Icon(_isDropped ? Icons.square : Icons.star);
                          },
                          onWillAccept: (data) {
                            return data == 'component';
                          },
                          onAccept: (data) {
                            setState(() {
                              _isDropped = true;
                            });
                          },
                        )
                      )
                    )
                  ),
                  Container(
                    decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                              color: Colors.black
                          ),
                        )
                    ),
                    child:
                      Column(
                        children: const [
                          Text('Library'),
                          Draggable(
                            data: 'component',
                            feedback: Icon(Icons.square_outlined),
                            childWhenDragging: Icon(Icons.square, color: Colors.grey,),
                            child: Icon(Icons.square),
                          )
                        ],
                      ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: Colors.black
                    ),
                  )
              ),
              child:
              Row(
                children: const [Text('Status Bar')],
              ),
            ),
          ],
        ),
    );
  }
}
