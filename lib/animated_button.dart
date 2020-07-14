import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_test/node.dart';

double getRadiansFromDegree(double degree) {
  double unitRadian = 57.295779513;
  return degree / unitRadian;
}

enum ButtonType {
  addChild,
  addExistingNodeAsChild,
  removeExistingConnection,
  main,
  delete,
  addInfo,
  complete,
  info
}

class NodeBody extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  final IconData iconData;
  final bool shadow;
  static const double smallBorderwidth = 3;

  NodeBody(
      {Key key,
      this.height = 50,
      this.width = 50,
      this.shadow = true,
      this.color = Colors.blue,
      this.iconData = Icons.add})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: <Widget>[
      shadow ? Container(
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
          )):
            Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(width: smallBorderwidth, color: Colors.brown),
      
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
        if (context.watch<NodeStates>().hasAnyConnection(widget.node)) {
          returnColor = widget.color;
          clickable = true;
        }
        break;
      case ButtonType.addInfo:
        returnColor = widget.color;
        clickable = true;
        break;
      default:
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
      default:
        break;
    }
    return unrolled;
  }

  bool isActive() {
    bool active = false;
    switch (widget.type) {
      case ButtonType.addExistingNodeAsChild:
        if (context.watch<NodeStates>().mode == Mode.addExistingNodeAsChild &&
            widget.node == context.watch<NodeStates>().activeNode) {
          active = true;
        }
        break;
      case ButtonType.removeExistingConnection:
        if (context.watch<NodeStates>().mode == Mode.removeExistingConnection &&
            widget.node == context.watch<NodeStates>().activeNode) {
          active = true;
        }
        break;
      default:
        break;
    }
    return active;
  }

  @override
  Widget build(BuildContext context) {
    print("${widget.type} ${identityHashCode(unrollAnimationController)}");
    List colorAndClickable = determineColorAndClickability();

    String type = widget.color != null ? "button" : "node";
    if (isActive()) {
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

class TextEntryMenu extends StatefulWidget {
  TextEntryMenu({Key key}) : super(key: key);

  @override
  _TextEntryMenuState createState() => _TextEntryMenuState();
}

double smallBorderwidth = 5;

class _TextEntryMenuState extends State<TextEntryMenu> {
  @override
  Widget build(BuildContext context) {
    bool _open = context.watch<NodeStates>().mode == Mode.addInfo;
    void onPressed() {
      FocusScope.of(context).unfocus();
      context.read<NodeStates>().setDefault();
    }

    return AnimatedContainer(
        duration: Duration(milliseconds: 500),
        width: _open ? MediaQuery.of(context).size.width : 0,
        height: _open ? MediaQuery.of(context).size.height : 0,
        color: Colors.brown,
        child: Center(
          child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(color: Colors.yellow[200]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: new BorderRadius.only(
                              topLeft: const Radius.circular(40.0),
                              topRight: const Radius.circular(40.0),
                              bottomLeft: const Radius.circular(40.0),
                              bottomRight: const Radius.circular(40.0)),
                          color: Colors.grey[400],
                        ),
                        child: TextField(
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Start here...'),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                      flex: 1,
                      child: MaterialButton(
                          onPressed: onPressed, child: Icon(Icons.save)))
                ],
              )),
        ));
  }
}
