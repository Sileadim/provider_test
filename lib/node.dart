// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';

enum Mode {
  addExistingNodeAsChild,
  removeExistingConnection,
  def,
  delete,
  addInfo
}

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
  String text;
  Node(
      {this.colorsToChooseFrom,
      this.nodes,
      this.active = false,
      this.id,
      this.position,
      this.text = "",
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
        position: Offset(0, 0),
        text: "Hello");
    nodes.add(parent);
  }
  void setDefault() {
    mode = Mode.def;
    notifyListeners();
  }

  void setTextOfActiveNode(String text) {
    activeNode?.text = text;
  }

  String getTextOfActiveNode() {
    print("getting text");
    print(activeNode != null ? activeNode.text : "");
    return activeNode != null ? activeNode.text : "";
  }

  void setModeToAddInfo(Node node) {
    activeNode = node;
    mode = Mode.addInfo;
    print("set mode to addInfo");
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
    if (node == null || other == null) {
      return false;
    }
    if (isChild(node, other) || isChild(other, node)) {
      return true;
    }
    return false;
  }

  bool hasAnyConnection(Node node) {
    for (var other in nodes) {
      if (hasConnection(node, other)) {
        print("has connection");
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

  bool removeConnection(Node node) {
    if (!(node == null || activeNode == null)) {
      if (isChild(activeNode, node)) {
        activeNode.children.remove(node);
        mode = Mode.def;
        return true;
      } else if (isChild(node, activeNode)) {
        node.children.remove(activeNode);
        mode = Mode.def;
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
        break;
      default:
        break;
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
        break;
      default:
        break;
    }
  }

  bool isActiveNode(Node node) {
    return activeNode == node ? true : false;
  }

  void resetView() {
    matrix = Matrix4.identity();
    notifyListeners();
  }
}
