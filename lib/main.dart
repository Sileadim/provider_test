// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:provider_test/edgepainter.dart';
import 'package:provider_test/node.dart';
import 'package:provider_test/animated_button.dart';

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
    },
    {
      "type": ButtonType.removeExistingConnection,
      "color": Colors.red[200],
      "iconData": Icons.content_cut,
      "onTap": context.watch<NodeStates>().toggleRemoveExistingConnection
    },
    {
      "type": ButtonType.complete,
      "color": Colors.amber,
      "iconData": Icons.check,
      "onTap": context.watch<NodeStates>().toggleComplete
    },
    {
      "type": ButtonType.addInfo,
      "color": Colors.blue,
      "iconData": Icons.create,
      "onTap": context.watch<NodeStates>().setModeToAddInfo
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
      ..translate(node.position.dx  ,
          node.position.dy );

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
      ...elements,
      TextEntryMenu()

    ];
    return Scaffold(
        drawer: Drawer(child: Container()),
        floatingActionButton: FloatingActionButton(
            onPressed: context.watch<NodeStates>().resetView,
            child: Icon(Icons.refresh, color: Colors.white)),
        appBar: AppBar(
          title: const Text('Example'),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack( alignment: Alignment.center, children: stackChildren),
        ));
  }
}
