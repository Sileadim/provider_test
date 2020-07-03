// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';

class Node {
  
  final List<Color> colorsToChooseFrom;
  bool active;
  int count = 0;
  List<Node> nodes;
  List<Node> children;
  int id = 0;
  Offset position;
  Function notify;
  double size;
  void toggle() {
    active = !active;
  }

  void deactive() {
    active = false;
  }

  Node(
      {this.colorsToChooseFrom,
      this.nodes,
      this.active = false,
      this.id,
      this.children = const [],
      this.position,
      this.notify,
      this.size = 100});
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
class NodeStates with ChangeNotifier, DiagnosticableTreeMixin {
  List<Node> nodes = [];
  Matrix4 matrix = Matrix4.identity();
  NodeStates() {
    var parent = Node(
        colorsToChooseFrom: [Colors.green, Colors.red],
        nodes: nodes,
        position: Offset(10, 200),
        notify: notifyListeners);
    nodes.add(parent);

    nodes.add(Node(
        colorsToChooseFrom: [Colors.yellow, Colors.blue],
        nodes: nodes,
        position: Offset(200, 200),
        notify: notifyListeners,
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
}


class NodeBody extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  static const double smallBorderwidth = 3;

  NodeBody({Key key, this.height, this.width, this.color}) : super(key: key);

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
      )
    ]);
  }
}
