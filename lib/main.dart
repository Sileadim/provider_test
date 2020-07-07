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
      home: Home(),
    );
  }
}

List<Widget> layoutElements(BuildContext context) {
  List<Widget> layedOutNodes = [];

  //print("layed nodes");
  List nodes = context.watch<NodeStates>().getNodes();
  //print(nodes.length);
  for (var node in nodes) {
    Matrix4 newMatrix = context.watch<NodeStates>().matrix.clone()
      ..translate(node.position.dx, node.position.dy);
    layedOutNodes.add(
      Transform(
        transform: newMatrix,
        child: AnimatedButton(
            onTap: context.watch<NodeStates>().toggleActiveNode,
            size: node.size,
            node: node,
            offsetLength: 0,
            active: false,
            moveable: true,
            unrolled: true),
      ),
    );
  }
  return layedOutNodes;
}

List<Widget> layoutButtons(BuildContext context) {
  List<Widget> layedOutButtons = [];
  const double buttonSize = 70;
  List nodes = context.watch<NodeStates>().getNodes();

  for (var node in nodes) {
    Matrix4 newMatrix = context.watch<NodeStates>().matrix.clone()
      ..translate(node.position.dx + node.size / 2 - buttonSize / 2,
          node.position.dy + node.size / 2 - buttonSize / 2);
    final List<Map> buttonData = [
      {
        "node": node,
        "color": Colors.green,
        "iconData": Icons.add_circle_outline,
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
                node: node,
                color: b["color"],
                iconData: b["iconData"],
                size: buttonSize,
                active: false,
                offsetLength: 0.8,
                moveable: false,
                degreeRotation: 0)),
      );
      i++;
    }
  }
  return layedOutButtons;
}

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Example'),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: <Widget>[
              CustomPaint(
                  painter: EdgePainter(
                nodes: context.watch<NodeStates>().getNodes(),
                matrix: context.watch<NodeStates>().matrix,
              )),
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
              ...layoutElements(context),
              ...layoutButtons(context)
            ],
          ),
        ));
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
  int initCalls = 0;

  AnimatedButton(
      {Key key,
      this.node,
      this.size,
      this.onTap,
      this.iconData,
      this.color,
      this.degreeRotation = 0,
      this.active = false,
      this.unrolled,
      this.moveable = false,
      this.offsetLength = 0})
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
    //String type = widget.color != null ? "button" : "node";
    growAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    growAnimation =
        Tween<double>(begin: 1, end: 1.4).animate(growAnimationController);
    unrollAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    initialGrowAnimation =
        Tween<double>(begin: 0, end: 1).animate(unrollAnimationController);
    unrollAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.2), weight: 75.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.2, end: 1.0), weight: 25.0),
    ]).animate(unrollAnimationController);
    offsetAnimation = Tween<Offset>(
            begin: Offset.zero,
            end: Offset.fromDirection(
                getRadiansFromDegree(widget.degreeRotation),
                widget.offsetLength))
        .animate(unrollAnimationController);
    rotateAnimation = Tween<double>(begin: 180.0, end: 0.0).animate(
        CurvedAnimation(
            parent: unrollAnimationController, curve: Curves.easeOut));

    super.initState();
  }

  void dispose() {
    growAnimationController.dispose();
    unrollAnimationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String type = widget.color != null ? "button" : "node";
    print("build $type");
    if (widget.active) {
      growAnimationController.repeat(reverse: true);
    } else if (!growAnimationController.isCompleted) {
      growAnimationController.reverse();
    }

    bool unrolled = widget.unrolled ??
        context.watch<NodeStates>().isActiveNode(widget.node);
    if (unrolled) {
      if (!unrollAnimationController.isCompleted) {
        unrollAnimationController.forward();
      }
    } else {
      unrollAnimationController.reverse();
    }

    void _onTap() {
      return widget.onTap(widget.node);
    }

    void onPanUpdate(DragUpdateDetails details) {
      if (widget.moveable) {
        context.read<NodeStates>().updatePosition(widget.node, details.delta);
      }
    }

    return SlideTransition(
      position: offsetAnimation,
      child: RotationTransition(
        turns: unrollAnimation,
        child: ScaleTransition(
          scale: initialGrowAnimation,
          child: ScaleTransition(
            scale: growAnimation,
            child: GestureDetector(
                onTap: () => _onTap(),
                onPanStart: (details) => {print(details)},
                onPanEnd: (details) => {print(details)},
                onPanUpdate: (details) => {onPanUpdate(details)},
                child: NodeBody(
                    iconData: widget.iconData,
                    color: widget.color ?? widget.node.getColor(),
                    height: widget.size ?? widget.node.size,
                    width: widget.node.size)),
          ),
        ),
      ),
    );
  }
}
