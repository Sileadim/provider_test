// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';

enum Mode { addExistingNodeAsChild, removeExistingConnection, def, delete }

class Node {
  final Color colorsToChooseFrom;
  bool active;
  int count = 0;
  List<Node> nodes;
  List<Node> children;
  int id = 0;
  Offset position;
  double size;
  bool completed = false;

  Node(
      {this.colorsToChooseFrom,
      this.nodes,
      this.active = false,
      this.id,
      this.position,
      children,
      this.size = 100})
      : children = children ?? [];

  Color getColor() {
    return colorsToChooseFrom;
  }

  void updatePosition(Offset update) {
    position += update;
  }

  void toggleCompleted() {
    completed = !completed;
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
      colorsToChooseFrom: Colors.green,
      nodes: nodes,
      position: Offset(10, 200),
    );
    nodes.add(parent);
  }

  void updatePosition(Node node, Offset update) {
    node.updatePosition(update);
    notifyListeners();
  }

  void updateMatrix(Matrix4 tm, Matrix4 sm, Matrix4 rm) {
    matrix = MatrixGestureDetector.compose(matrix, tm, sm, rm);
    notifyListeners();
  }

  void notify(Node node) {
    notifyListeners();
  }

  void toggleComplete(Node node) {
    node.toggleCompleted();
    notifyListeners();
  }

  List<Node> getNodes() {
    return nodes;
  }

  void deleteNode(Node node) {
    if (nodes.length > 1) {
      if (node == activeNode) {
        activeNode = null;
        mode = Mode.def;
      }
      nodes.remove(node);
      for (var potentialParent in nodes) {
        if (potentialParent.children.contains(node)) {
          potentialParent.children.remove(node);
        }
      }
      notifyListeners();
    }
  }

  bool isChild(Node parent, Node child) {
    if (parent.children.contains(child)) {
      return true;
    }
    return false;
  }

  bool addExistingAsChild(Node node) {
    if (canAddAsChild(activeNode, node)) {
      activeNode.children.add(node);
      mode = Mode.def;
      return true;
    }
    return false;
  }

  bool canAddAsChild(Node node, Node child) {
    if (node != null) {
      if (node.children.contains(child) ||
          child.children.contains(node) ||
          node == child) {
        return false;
      }
    }
    return true;
  }

  bool hasConnection(Node node, Node other) {
    if (node == null ||
        other == null ||
        isChild(node, other) ||
        isChild(other, node)) {
      return false;
    }
    return true;
  }

  bool hasAnyConnection(Node node) {
    for (var other in nodes) {
      if (hasConnection(node, other)) {
        return true;
      }
    }
    return false;
  }

  bool canAddAnyAsChild(Node node) {
    for (var child in nodes) {
      if (canAddAsChild(node, child)) {
        return true;
      }
    }
    return false;
  }

  void addChild(Node node) {
    Node newNode = Node(
      colorsToChooseFrom: Colors.blue,
      nodes: nodes,
      position: node.position + Offset(0, 200),
    );
    nodes.add(newNode);
    node.children.add(newNode);
    notifyListeners();
  }

  void addNode() {
    Node newNode = Node(
      colorsToChooseFrom: Colors.yellow,
      nodes: nodes,
      position: Offset(0, 0),
    );
    nodes.add(newNode);
    notifyListeners();
  }

  //bool removeConnection(Node node) {
  //  if (isChild(activeNode, node)) {
  //    activeNode.children.remove(node);
  //    return true;
  //  } else if (isChild(node, activeNode)) {
  //    node.children.remove(activeNode);
  //    return true;
  //  }
  //  return false;
  //}
  bool removeConnection(Node node) {
    if (!(node == null || activeNode == null)) {
      if (isChild(activeNode, node)) {
        activeNode.children.remove(node);
        return true;
      } else if (isChild(node, activeNode)) {
        node.children.remove(activeNode);
        return true;
      }
    }
    return false;
  }

  void toggleAddChild(Node node) {
    switch (mode) {
      case Mode.addExistingNodeAsChild:
        mode = Mode.def;
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
        break;

      case Mode.addExistingNodeAsChild:
        mode = Mode.removeExistingConnection;
        //activeNode = node;
        break;

      case Mode.def:
        mode = Mode.removeExistingConnection;
      //activeNode = node;
    }
    notifyListeners();
  }

  void toggleActiveNode(Node node) {
    activeNode = activeNode == node ? null : node;
    notifyListeners();
  }

  void toggleActiveNodeOrPerformAction(Node node) {
    switch (mode) {
      case Mode.removeExistingConnection:
        bool success = removeConnection(node);
        if (success) {
          notifyListeners();
        }
        break;

      case Mode.addExistingNodeAsChild:
        bool success = addExistingAsChild(node);
        if (success) {
          notifyListeners();
        }
        break;

      case Mode.def:
        toggleActiveNode(node);
    }
  }

  bool isActiveNode(Node node) {
    return activeNode == node ? true : false;
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
          child: Center(child: Icon(iconData, color: Colors.white)))
    ]);
  }
}
