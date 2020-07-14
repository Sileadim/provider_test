import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:arrow_path/arrow_path.dart';
import 'dart:math';
import 'package:provider_test/node.dart';

Offset computeOffsetToEdge(
    double r, double originX, double originY, double x, double y) {
  double diffX = x - originX;
  double diffY = y - originY;
  double length = sqrt(pow(diffX, 2) + pow(diffY, 2));
  double beta = acos(diffY / length);
  double alpha = pi / 2 - beta;
  double dy = r * cos(beta);
  double dx = r * cos(alpha);
  double directionX = diffX >= 0 ? 1 : -1;
  return Offset(x - directionX * dx, y - dy);
}

class EdgePainter extends CustomPainter {
  List<Node> nodes;
  Matrix4 matrix;

  EdgePainter({this.matrix, this.nodes}) : super();

  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint();
    backgroundPaint.color = Colors.white;
    var rect = Offset.zero & size;
    canvas.drawRect(rect, backgroundPaint);

    var decomposedValues = MatrixGestureDetector.decomposeToValues(matrix);

    Offset moveCenter(Node node) {
      Offset position = Offset(node.position.dx, node.position.dy);
    
      return Offset(
          (position.dx +  node.size/2 ) * decomposedValues.scale +
              decomposedValues.translation.dx,
          (position.dy+ node.size/2) * decomposedValues.scale +
              decomposedValues.translation.dy);
    }

    Paint big = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 10 * decomposedValues.scale;

    Paint small = Paint()
      ..color = Colors.yellow[300]
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4 * decomposedValues.scale;

    for (var parent in nodes) {
      for (var child in parent.children) {
        Offset transformedParentPosition = moveCenter(parent);
        Offset transformedChildPosition = moveCenter(child);

        // got to scale radius of box, radius = half of heigth or width
        // for whatever reason arrowpath point the arrow head ~5 pixel in.
        Offset toChildEdge = computeOffsetToEdge(
            (parent.size / 2 ) * decomposedValues.scale,
            transformedParentPosition.dx,
            transformedParentPosition.dy,
            transformedChildPosition.dx,
            transformedChildPosition.dy);
        Offset almostToChildEdge = computeOffsetToEdge(
            (parent.size / 2 ) * decomposedValues.scale,
            transformedParentPosition.dx,
            transformedParentPosition.dy,
            transformedChildPosition.dx,
            transformedChildPosition.dy);
        Path pathBig = Path();
        pathBig.moveTo(
            transformedParentPosition.dx, transformedParentPosition.dy);
        pathBig.lineTo(toChildEdge.dx, toChildEdge.dy);
        pathBig = ArrowPath.make(
            path: pathBig, tipLength: 30 * decomposedValues.scale);
        Path pathSmall = Path();
        pathSmall.moveTo(
            transformedParentPosition.dx, transformedParentPosition.dy);
        pathSmall.lineTo(almostToChildEdge.dx, almostToChildEdge.dy);
        pathSmall = ArrowPath.make(
            path: pathSmall, tipLength: 30 * decomposedValues.scale);

        canvas.drawPath(pathBig, big);
        canvas.drawPath(pathSmall, small);
      }
    }
  }

  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
