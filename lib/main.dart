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

enum ButtonType {
  addChild,
  addExistingNodeAsChild,
  removeExistingConnection,
  main,
  delete,
  addInfo,
  complete
}

List<Widget> layoutElements(
    BuildContext context, Map mainButtons, Map buttons) {
  List<Widget> layedOutNodes = [];
  const double buttonSize = 70;
  final List<Map> buttonData = [
    {
      "type": ButtonType.addChild,
      "color": Colors.green,
      "iconData": Icons.add_circle_outline,
      "onTap": context.watch<NodeStates>().addChild,
    },
    {
      "type": ButtonType.addExistingNodeAsChild,
      "color": Colors.green[200],
      "iconData": Icons.add_circle_outline,
      "onTap": context.watch<NodeStates>().toggleAddChild
    },
    {
      "type": ButtonType.delete,
      "color": Colors.red,
      "iconData": Icons.remove_circle_outline,
      "onTap": context.watch<NodeStates>().deleteNode
    },    {
      "type": ButtonType.removeExistingConnection,
      "color": Colors.red[200],
      "iconData": Icons.remove_circle_outline,
      "onTap": context.watch<NodeStates>().toggleRemoveExistingConnection
    },

    {
      "type": ButtonType.complete,
      "color": Colors.amber,
      "iconData": Icons.check,
      "onTap": context.watch<NodeStates>().toggleComplete
    }
  ];
  List nodes = context.watch<NodeStates>().getNodes();
  Matrix4 mainButtonMatrix;
  for (var node in nodes) {
    mainButtonMatrix = context.watch<NodeStates>().matrix.clone()
      ..translate(node.position.dx, node.position.dy);
    if (mainButtons.containsKey(node)) {
      print("added node from store");
      layedOutNodes.add(
          Transform(transform: mainButtonMatrix, child: mainButtons[node]));
    } else {
      var mainButton = AnimatedButton(
          key: GlobalKey(),
          onTap: context.watch<NodeStates>().toggleActiveNodeOrPerformAction,
          type: ButtonType.main,
          color: Colors.brown[300],
          size: node.size,
          node: node,
          offsetLength: 0,
          active: false,
          moveable: true,
          unrolled: true);
      mainButtons[node] = mainButton;
      layedOutNodes
          .add(Transform(transform: mainButtonMatrix, child: mainButton));
    }
    Matrix4 buttonMatrix = context.watch<NodeStates>().matrix.clone()
      ..translate(node.position.dx + node.size / 2 - buttonSize / 2,
          node.position.dy + node.size / 2 - buttonSize / 2);

    if (buttons.containsKey(node)) {
      buttons[node].forEach((k, v) =>
          layedOutNodes.add(Transform(transform: buttonMatrix, child: v)));
    } else {
      int i = 0;
      for (var b in buttonData) {
        if (i == 0) {
          buttons[node] = {};
        }
        var button = AnimatedButton(
            key: UniqueKey(),
            type: b["type"],
            onTap: b["onTap"],
            node: node,
            color: b["color"],
            iconData: b["iconData"],
            size: buttonSize,
            offsetLength: 1.3,
            moveable: false,
            degreeRotation: i * 360 / buttonData.length);
        layedOutNodes.add(Transform(transform: buttonMatrix, child: button));
        buttons[node][b["type"]] = button;
        i++;
      }
    }
  }

  //  delete Buttons for non existing nodes from dict
  List keys = mainButtons.keys.toList();
  for (var node in keys) {
    if (!nodes.contains(node)) {
      var mainButton = mainButtons.remove(node);
      mainButtonMatrix = context.watch<NodeStates>().matrix.clone()
        ..translate(node.position.dx, node.position.dy);
      layedOutNodes
          .add(Transform(transform: mainButtonMatrix, child: mainButton));
      var _ = buttons.remove(node);
    }
  }
  return layedOutNodes;
}

List<Widget> layoutButtons(BuildContext context) {
  List<Widget> layedOutButtons = [];
  const double buttonSize = 70;
  List nodes = context.watch<NodeStates>().getNodes();

  for (var node in nodes) {
    Matrix4 mainButtonMatrix = context.watch<NodeStates>().matrix.clone()
      ..translate(node.position.dx + node.size / 2 - buttonSize / 2,
          node.position.dy + node.size / 2 - buttonSize / 2);

    //final List<Map> buttonData = [
    //  {
    //    "color": Colors.green,
    //    "iconData": Icons.add_circle_outline,
    //    "onTap": () => {},
    //  }
    //];
    final List<Map> buttonData = [
      {
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
            transform: mainButtonMatrix,
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
  Map<Node, Map<dynamic, dynamic>> buttons = {};
  Map<Node, dynamic> mainButtons = {};

  @override
  Widget build(BuildContext context) {
    print("*************");
    List<Widget> elements = layoutElements(context, mainButtons, buttons);
    List<Widget> stackChildren = [
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
      ...elements
    ];

    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: context.watch<NodeStates>().addNode,
        ),
        appBar: AppBar(
          title: const Text('Example'),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(children: stackChildren),
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
  final ButtonType type;
  AnimatedButton(
      {Key key,
      this.node,
      this.size,
      this.onTap,
      this.iconData,
      this.color,
      this.degreeRotation = 0,
      this.type,
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
  final key = GlobalKey();
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
    super.initState();

    print("init ${widget.type}");
    //String type = widget.color != null ? "button" : "node";
    growAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    growAnimation =
        Tween<double>(begin: 1, end: 1.4).animate(growAnimationController);
    unrollAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
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
  }

  void dispose() {
    growAnimationController?.dispose();
    unrollAnimationController?.dispose();
    super.dispose();
  }

  List determineColorAndClickability() {
    Color returnColor = Colors.grey[300];
    bool clickable = false;
    switch (widget.type) {
      case ButtonType.main:
        if (widget.node.completed) {
          returnColor = Colors.amber;
        } else {
          returnColor = widget.color;
        }
        clickable = true;
        break;
      case ButtonType.delete:
        if (context.watch<NodeStates>().nodes.length > 1) {
          returnColor = widget.color;
          clickable = true;
        }
        break;
      case ButtonType.addExistingNodeAsChild:
        if (context.watch<NodeStates>().canAddAnyAsChild(widget.node)) {
          returnColor = widget.color;
          clickable = true;
        }
        break;
      case ButtonType.addChild:
        returnColor = widget.color;
        clickable = true;

        break;
      case ButtonType.complete:
        returnColor = widget.color;
        clickable = true;
        break;
      case ButtonType.removeExistingConnection:
        if (context.watch<NodeStates>().hasAnyConnection(widget.node)){
          returnColor = widget.color;
        }
        clickable = true;

        break;
    }
    return [returnColor, clickable];
  }

  bool determineUnrolled() {
    bool unrolled = context.watch<NodeStates>().isActiveNode(widget.node);
    switch (widget.type) {
      case ButtonType.main:
        if (context.watch<NodeStates>().nodes.contains(widget.node)) {
          unrolled = true;
        } else {
          unrolled = false;
        }
        break;
    }
    return unrolled;
  }

  @override
  Widget build(BuildContext context) {
    print("${widget.type} ${identityHashCode(unrollAnimationController)}");
    List colorAndClickable = determineColorAndClickability();

    String type = widget.color != null ? "button" : "node";
    if (widget.active) {
      growAnimationController.repeat(reverse: true);
    } else {
      growAnimationController.reverse();
    }

    if (determineUnrolled()) {
      if (!unrollAnimationController.isCompleted) {
        unrollAnimationController.forward();
      }
    } else if (unrollAnimationController.isCompleted) {
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
            child: AbsorbPointer(
              absorbing: !colorAndClickable[1],
              child: GestureDetector(
                  onTap: () => _onTap(),
                  onPanStart: (details) => {print(details)},
                  onPanEnd: (details) => {print(details)},
                  onPanUpdate: (details) => {onPanUpdate(details)},
                  child: NodeBody(
                      iconData: widget.iconData,
                      color: colorAndClickable[0],
                      height: widget.size ?? widget.node.size,
                      width: widget.size ?? widget.node.size)),
            ),
          ),
        ),
      ),
    );
  }
}
