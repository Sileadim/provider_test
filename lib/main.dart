// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

/// This is a reimplementation of the default Flutter application using provider + [ChangeNotifier].

void main() {
  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ColorToggler()),
      ],
      child: MyApp(),
    ),
  );
}

class NodeInfo {
  final List<Color> colorsToChooseFrom;
  bool active;
  int count = 0;
  List<NodeInfo> nodes;
  List<NodeInfo> children;
  int id = 0;
  Offset position;
  Function notify;
  void toggle() {
    active = !active;
  }

  void deactive() {
    active = false;
  }

  NodeInfo(
      {this.colorsToChooseFrom,
      this.nodes,
      this.active = false,
      this.id,
      this.children = const [],
      this.position,
      this.notify});
  Color getColor() {
    return colorsToChooseFrom[count % 2];
  }

  void increment() {
    count++;
  }

  void deactivatedOthers() {
    for (var node in nodes) {
      if (node != this) {
        node.deactive();
      }
    }
  }

  void updatePosition(Offset update) {
    position += update;
  }
}

/// Mix-in [DiagnosticableTreeMixin] to have access to [debugFillProperties] for the devtool
class ColorToggler with ChangeNotifier, DiagnosticableTreeMixin {
  List<NodeInfo> nodes = [];

  ColorToggler() {
    nodes.add(NodeInfo(
        colorsToChooseFrom: [Colors.green, Colors.red],
        nodes: nodes,
        position: Offset(10, 200),
        notify: notifyListeners));
    nodes.add(NodeInfo(
        colorsToChooseFrom: [Colors.yellow, Colors.blue],
        nodes: nodes,
        position: Offset(200, 200),
        notify: notifyListeners));
  }

  void incrementAll() {
    for (var node in nodes) {
      node.increment();
    }

    print("increment 2");
    notifyListeners();
  }

  void updatePosition(NodeInfo node, Offset update) {
    node.updatePosition(update);
    notifyListeners();
  }

  List<NodeInfo> getNodes() {
    return nodes;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key}) : super(key: key);
  //List<NodeInfo> nodes = context.watch<ColorToggler>().getNodes();

  @override
  Widget build(BuildContext context) {
    var nodes = context.watch<ColorToggler>().getNodes();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example'),
      ),
      body: Stack(
        children: <Widget>[

          Container(width: double.infinity, height: double.infinity, color:Colors.black),



          Positioned(
            left: nodes[0].position.dx,
            top: nodes[0].position.dy,
            child: AnimatedColorContainer(nodeInfo: nodes[0]),
          ),
          Positioned(
              left: nodes[1].position.dx,
              top: nodes[1].position.dy,
              child: AnimatedColorContainer(nodeInfo: nodes[1])),
        ],
      ),
    );
  }
}

class AnimatedColorContainer extends StatefulWidget {
  final NodeInfo nodeInfo;

  AnimatedColorContainer({Key key, this.nodeInfo}) : super(key: key);
  @override
  _AnimatedColorContainerState createState() => _AnimatedColorContainerState();
}

class _AnimatedColorContainerState extends State<AnimatedColorContainer>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation animation;

  @override
  void initState() {
    controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    animation = Tween<double>(begin: 1, end: 1.5).animate(controller);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    void onTap() {
      context.read<ColorToggler>().incrementAll();
      widget.nodeInfo.deactivatedOthers();
      widget.nodeInfo.toggle();
    }

    if (widget.nodeInfo.active) {
      controller.repeat(reverse: true);
    } else if (!controller.isCompleted) {
      controller.reverse();
    }
    return ScaleTransition(
      scale: animation,
      child: GestureDetector(
          onTap: () => onTap(),
          onPanUpdate: (details) =>
              {context.read<ColorToggler>().updatePosition(widget.nodeInfo,details.delta)},
          child: Container(
              height: 100, width: 100, color: widget.nodeInfo.getColor())),
    );
  }
}

//class Count extends StatelessWidget {
//  const Count({Key key}) : super(key: key);
//
//  @override
//  Widget build(BuildContext context) {
//    return Text(
//
//        /// Calls `context.watch` to make [MyHomePage] rebuild when [Counter] changes.
//        '${context.watch<ColorToggler>().count}',
//        style: Theme.of(context).textTheme.headline4);
//  }
//}
