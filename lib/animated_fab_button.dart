import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_test/node.dart';

import 'package:provider_test/animated_button.dart';
import 'package:matrix4_transform/matrix4_transform.dart';

class AnimatedFabButton extends StatefulWidget {
  AnimatedFabButton({Key key}) : super(key: key);
  final double size = 70;
  @override
  _AnimatedFabButtonState createState() => _AnimatedFabButtonState();
}

class _AnimatedFabButtonState extends State<AnimatedFabButton>
    with SingleTickerProviderStateMixin {
  Animation rotation;
  AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    rotation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isAddInfoMode = context.watch<NodeStates>().mode == Mode.addInfo;

    if (isAddInfoMode) {
      controller?.forward();
    } else {
      controller?.reverse();
    }

    void onPressed() {
      if (isAddInfoMode) {
        FocusScope.of(context).unfocus();
        context.read<NodeStates>().setDefault();
      } else {
        print("resetView");
        context.read<NodeStates>().resetView();
      }
    }

    return SizedBox(
          width: widget.size,
          height: widget.size,
          child: FloatingActionButton(
        onPressed: onPressed,
        elevation: 10,
        
        backgroundColor: Colors.transparent,
        child: Container(
          child: RotationTransition(
            turns: rotation,
            child: AnimatedContainer(
                decoration: BoxDecoration(shape: BoxShape.circle),
                duration: Duration(milliseconds: 250),
                child: isAddInfoMode
                    ? NodeBody(
                        iconData: Icons.save, height: widget.size, width: widget.size, shadow: false)
                    : NodeBody(iconData: Icons.refresh, height: widget.size, width: widget.size, shadow: false)),
          ),
        ),
      ),
    );
  }
}
