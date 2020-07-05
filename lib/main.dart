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

List<Widget> layoutElements(
    Matrix4 matrix, List<Node> nodes, BuildContext context) {
  List<Widget> layedOutNodes = [];
  for (var node in nodes) {
    Matrix4 newMatrix = matrix.clone()
      ..translate(node.position.dx, node.position.dy);
    layedOutNodes.add(
      Transform(
        transform: newMatrix,
        child: AnimatedButton(
            onTap: context.watch<NodeStates>().toggleActiveNode,
            size: node.size,
            node: node,
            offsetLength: 0,
            active: context.watch<NodeStates>().isActiveNode(node),
            moveable: true,
            unrolled: true),
      ),
    );
  }
  return layedOutNodes;
}

List<Widget> layoutButtons(
    Matrix4 matrix, List<Node> nodes, BuildContext context) {
  List<Widget> layedOutButtons = [];
  for (var node in nodes) {
    Matrix4 newMatrix = matrix.clone()
      ..translate(node.position.dx, node.position.dy);
    List<Map> buttonData = [
      {
        "node": node,
        "color": Colors.green,
        "icon": Icons.add_circle_outline,
        "onTap": context.watch<NodeStates>().addChild,
      }
    ];
    //[Colors.green, Icons.add_circle, addNewParent, false],
    //if (children.length < nodes.length - 1)
    //  [
    //    Colors.green[200],
    //    Icons.arrow_forward,
    //    toggleAddChild,
    //    activeNodeWrapper?.activeNode == this &&
    //            activeNodeWrapper?.mode == Mode.addExistingChild
    //        ? true
    //        : false
    //  ],
    //if (nodes.length > 1)
    //  [Colors.red, Icons.remove_circle_outline, delete, false],
    //if (children.length > 0)
    //  [
    //    Colors.red[200],
    //    Icons.remove,
    //    toggleDeleteChild,
    //    activeNodeWrapper?.activeNode == this &&
    //            activeNodeWrapper?.mode == Mode.removeChild
    //        ? true
    //        : false
    //  ],
    //[Colors.blue, Icons.create, () => {}, false]
    //;

    int i = 0;
    for (var b in buttonData) {
      layedOutButtons.add(
        Transform(
            transform: newMatrix,
            child: AnimatedButton(
                onTap: b["onTap"],
                node: b["node"],
                color: b["color"],
                iconData: b["iconData"],
                size: 70,
                active: false,
                unrolled: node.active,
                offsetLength: 100,
                degreeRotation: i * 360 / buttonData.length)),
      );
      i++;
    }
  }
  return layedOutButtons;
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
                  context.read<NodeStates>().updateMatrix(tm, sm, null);
                },
                child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent),
              ),
              ...layoutElements(matrix, nodes, context),
              //...layoutButtons(matrix, nodes, context)
            ],
          ),
        ),
      ),
    );
  }
}

double getRadiansFromDegree(double degree) {
  double unitRadian = 57.295779513;
  return degree / unitRadian;
}

class AnimatedButton extends StatefulWidget {
  final Node node;
  final double size;
  final bool active;
  final bool unrolled;
  final Function onTap;
  final bool moveable;
  final double degreeRotation;
  final IconData iconData;
  final double offsetLength;
  final Color color;

  AnimatedButton(
      {Key key,
      this.node,
      this.size,
      this.onTap,
      this.iconData,
      this.color,
      this.degreeRotation = 0,
      this.active = false,
      this.unrolled = false,
      this.moveable = false,
      this.offsetLength = 1})
      : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  @override
  AnimationController growAnimationController;
  Animation growAnimation;
  Animation layoutGrowAnimation;

  AnimationController unrollAnimationController;
  Animation unrollAnimation;
  Animation rotateAnimation;
  Animation offsetAnimation;
  Animation initialGrowAnimation;
  @override
  void initState() {
    growAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    growAnimation =
        Tween<double>(begin: 1, end: 1.4).animate(growAnimationController);
    unrollAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1000));
    initialGrowAnimation =
        Tween<double>(begin: 0, end: 1).animate(unrollAnimationController);
    unrollAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.2), weight: 75.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.2, end: 1.0), weight: 25.0),
    ]).animate(unrollAnimationController);

    offsetAnimation = Tween<Offset>(  begin: Offset.zero, end: Offset.fromDirection(getRadiansFromDegree(widget.degreeRotation), widget.offsetLength) ).animate(unrollAnimationController);
    rotateAnimation = Tween<double>(begin: 180.0, end: 0.0).animate(
        CurvedAnimation(
            parent: unrollAnimationController, curve: Curves.easeOut));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active) {
      growAnimationController.repeat(reverse: true);
    } else if (!growAnimationController.isCompleted) {
      growAnimationController.reverse();
    }

    if (widget.unrolled) {
      unrollAnimationController.forward();
    } else {
      unrollAnimationController.reverse();
    }

    void _onTap() {
      return widget.onTap(widget.node);
    }

    return 

          SlideTransition(
              position: offsetAnimation,
              child: RotationTransition(
              turns: unrollAnimation,
              child: ScaleTransition(
                          scale: initialGrowAnimation,
                              child: ScaleTransition(
                  scale: growAnimation,
                  child: GestureDetector(
                      onTap: () => _onTap(),
                      onPanUpdate: (details) => {
                            if (widget.moveable)
                              {
                                context
                                    .read<NodeStates>()
                                    .updatePosition(widget.node, details.delta)
                              }
                          },
                      child: NodeBody(
                          iconData: widget.iconData,
                          color: widget.color ?? widget.node.getColor(),
                          height: widget.node.size,
                          width: widget.node.size)),
                ),
              ),
      ),
          );
  }
}
