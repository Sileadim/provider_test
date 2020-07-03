// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';

enum Mode { addExistingNodeAsChild, removeExistingConnection, def }

class Node {
  final List<Color> colorsToChooseFrom;
  bool active;
  int count = 0;
  List<Node> nodes;
  List<Node> children;
  int id = 0;
  Offset position;
  double size;
  Node(
      {this.colorsToChooseFrom,
      this.nodes,
      this.active = false,
      this.id,
      this.children = const [],
      this.position,
      this.size = 100});

  Color getColor() {
    return colorsToChooseFrom[count % 2];
  }

  void increment() {
    count++;
  }

  void toggle() {
    active = !active;
  }

  void deactive() {
    active = false;
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
class NodeStates with ChangeNotifier, DiagnosticableTreeMixin {
  List<Node> nodes = [];
  Matrix4 matrix = Matrix4.identity();
  Node activeNode;
  Mode mode = Mode.def;

  NodeStates() {
    var parent = Node(
      colorsToChooseFrom: [Colors.green, Colors.red],
      nodes: nodes,
      position: Offset(10, 200),
    );
    nodes.add(parent);

    nodes.add(Node(
        colorsToChooseFrom: [Colors.yellow, Colors.blue],
        nodes: nodes,
        position: Offset(200, 200),
        children: [parent]));
  }

  void incrementAll() {
    for (var node in nodes) {
      node.increment();
    }
    notifyListeners();
  }

  void updatePosition(Node node, Offset update) {
    node.updatePosition(update);
    notifyListeners();
  }

  void updateMatrix(Matrix4 tm, Matrix4 sm, Matrix4 rm) {
    matrix = MatrixGestureDetector.compose(matrix, tm, sm, rm);
    notifyListeners();
  }

  List<Node> getNodes() {
    return nodes;
  }

  bool deleteNode(Node node) {
    if (nodes.length > 1) {
      nodes.remove(node);
      return true;
    }
    return false;
  }

  bool isChild(Node parent, Node child) {
    if (parent.children.contains(child)) {
      return true;
    }
    return false;
  }

  bool addExistingAsChild(Node node) {
    if (!isChild(activeNode, node) && activeNode != node) {
      activeNode.children.add(node);
      return true;
    }
    return false;
  }

  void addChild(Node node) {
    Node newNode = Node(
      colorsToChooseFrom: [Colors.green, Colors.red],
      nodes: nodes,
      position: node.position + Offset(0, 200),
    );
    nodes.add(newNode);
    node.children.add(newNode);
  }

  bool removeConnection(Node node) {
    if (isChild(activeNode, node)) {
      activeNode.children.remove(node);
      return true;
    } else if (isChild(node, activeNode)) {
      node.children.remove(activeNode);
      return true;
    }
    return false;
  }

  void toggleAddChild(Node node) {
    switch (mode) {
      case Mode.addExistingNodeAsChild:
        mode = Mode.def;
        activeNode = null;
        break;

      case Mode.removeExistingConnection:
        mode = Mode.addExistingNodeAsChild;
        activeNode = node;
        break;

      case Mode.def:
        mode = Mode.addExistingNodeAsChild;
        activeNode = node;
    }
    notifyListeners();
  }

  void toggleRemoveExistingConnection(Node node) {
    switch (mode) {
      case Mode.removeExistingConnection:
        mode = Mode.def;
        activeNode = null;
        break;

      case Mode.addExistingNodeAsChild:
        mode = Mode.removeExistingConnection;
        activeNode = node;
        break;

      case Mode.def:
        mode = Mode.removeExistingConnection;
        activeNode = node;
    }
    notifyListeners();
  }

  void toggleActiveNode (Node node){

    activeNode = activeNode == node ? null:node;
    notifyListeners();

  }

}

class NodeBody extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  final IconData iconData;
  static const double smallBorderwidth = 3;

  NodeBody(
      {Key key, this.height, this.width, this.color, this.iconData = Icons.add})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: <Widget>[
      Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(width: smallBorderwidth, color: Colors.brown),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(5, 5), // changes position of shadow
              ),
            ],
          )),
      Container(
          height: height - 2 * smallBorderwidth,
          width: width - 2 * smallBorderwidth,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                  width: smallBorderwidth * 2, color: Colors.yellow[300]))),
      Container(
          height: height - 4 * smallBorderwidth,
          width: width - 4 * smallBorderwidth,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(width: smallBorderwidth, color: Colors.brown)),
          child:
              Center(child: Icon(iconData, color:Colors.white) ))
    ]);
  }
}
