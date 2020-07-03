// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:provider_test/edgepainter.dart';
import 'package:provider_test/node.dart';

void main() {
  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NodeStates()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

List<Widget> layoutElements(Matrix4 matrix, List<Node> nodes) {
  List<Widget> layedOutNodes = [];
  for (var node in nodes) {
    Matrix4 newMatrix = matrix.clone()
      ..translate(node.position.dx, node.position.dy);
    layedOutNodes.add(
      Transform(
        transform: newMatrix,
        child: AnimatedColorContainer(node: node),
      ),
    );
  }
  return layedOutNodes;
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var nodes = context.watch<NodeStates>().getNodes();
    Matrix4 matrix = context.watch<NodeStates>().matrix;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(
          painter: EdgePainter(
            matrix: matrix,
            nodes: nodes,
          ),
          child: Stack(
            children: <Widget>[
              MatrixGestureDetector(
                // Need to fix edgepainter if rotation should be allowed
                shouldRotate: false,
                onMatrixUpdate: (m, tm, sm, rm) {
                  context.read<NodeStates>().updateMatrix(tm, sm,rm);
                },
                child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent),
              ),
              ...layoutElements(matrix, nodes)
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedColorContainer extends StatefulWidget {
  final Node node;
  AnimatedColorContainer({Key key, this.node}) : super(key: key);
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
      context.read<NodeStates>().incrementAll();
      widget.node.deactivatedOthers();
      widget.node.toggle();
    }

    if (widget.node.active) {
      controller.repeat(reverse: true);
    } else if (!controller.isCompleted) {
      controller.reverse();
    }
    return ScaleTransition(
      scale: animation,
      child: GestureDetector(
          onTap: () => onTap(),
          onPanUpdate: (details) => {
                context
                    .read<NodeStates>()
                    .updatePosition(widget.node, details.delta)
              },
          child: Container( decoration: BoxDecoration(
                color: widget.node.getColor(),
                shape: BoxShape.circle,),
              height: widget.node.size, width: widget.node.size)),
    );
  }
}
