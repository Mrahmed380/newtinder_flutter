import 'package:flutter/material.dart';

class SwipeableWidget extends StatefulWidget {
  SwipeableWidget({
    Key key,
    this.cardController,
    this.animationDuration = 700,
    this.horizontalThreshold = 0.85,
    this.verticalThreshold = 0.95,
    this.onLeftSwipe,
    this.onRightSwipe,
    this.onTopSwipe,
    this.scrollSensitivity = 6.0,
    @required this.child,
    this.nextCards,
  }) : super(key: key);

  final SwipeableWidgetController cardController;

  /// Animation duration in millseconds
  final int animationDuration;

  /// Alignment.x value beyond which card will be dismissed
  final double horizontalThreshold;

  /// NOT IMPLEMENTED YET
  final double verticalThreshold;

  /// Function executed when the card is swiped left
  final Function onLeftSwipe;

  /// Function executed when the card is swiped right
  final Function onRightSwipe;

  /// Function executed when the card is swiped top
  final Function onTopSwipe;

  /// The multiplier for the scroll value
  final double scrollSensitivity;

  /// The child widget, which is swipeable
  final Widget child;

  /// Any widgets to show behind the [child]. These will most likely be the next
  /// few cards in the deck
  final List<Widget> nextCards;

  @override
  _SwipeableWidgetState createState() => _SwipeableWidgetState();
}

class _SwipeableWidgetState extends State<SwipeableWidget>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Alignment _childAlign;
  Alignment _initialAlignment = Alignment.center;

  // stores the direction in which the card is being dismissed
  Direction _dir;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: Duration(milliseconds: widget.animationDuration),
        vsync: this);
    _controller.addListener(() => setState(() {}));

    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        // when animated completed, put card back at origin without animation
        _childAlign = _initialAlignment;
      }
    });

    // setting the initial alignment
    _childAlign = _initialAlignment;
  }

  @override
  Widget build(BuildContext context) {
    // controller isn't necessary
    widget.cardController?.setListener((dir) {
      // animate card out in specified direction
      animateCardLeaving(dir);
    });

    return Expanded(
      child: Stack(
        children: <Widget>[
          // widgets behind current card
          ...widget.nextCards,

          // current card
          child(),

          // when the card is animating, prevent onPanUpdate to exxecute
          _controller.status != AnimationStatus.forward
              ? SizedBox.expand(
                  child:
                      GestureDetector(onPanUpdate: (DragUpdateDetails details) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final screenHeight = MediaQuery.of(context).size.height;
                    setState(() {
                      // setting new alignment based on finger position
                      _childAlign = Alignment(
                        _childAlign.x +
                            widget.scrollSensitivity *
                                details.delta.dx /
                                screenWidth,
                        _childAlign.y +
                            widget.scrollSensitivity *
                                details.delta.dy /
                                screenHeight,
                      );
                    });
                  }, onPanEnd: (_) {
                    if (_childAlign.x > widget.horizontalThreshold)
                      animateCardLeaving(Direction.right);
                    else if (_childAlign.x < -widget.horizontalThreshold)
                      animateCardLeaving(Direction.left);
                    else {
                      // when direction is null, it goes back to the center
                      animateCardLeaving(null);
                    }
                  }),
                )
              : Container(),
        ],
      ),
    );
  }

  void animateCardLeaving(Direction dir) {
    Function then;
    switch (dir) {
      case (Direction.left):
        then = widget.onLeftSwipe;
        break;
      case (Direction.right):
        then = widget.onRightSwipe;
        break;
      case (Direction.top):
        then = widget.onTopSwipe;
        break;
      default:
        then = () {};
        break;
    }
    _dir = dir;
    _controller.stop();
    _controller.value = 0.0;

    _controller.forward().then((value) => then());
  }

  Widget child() {
    Alignment alignment;

    if (_controller.status == AnimationStatus.forward) {
      alignment =
          cardDismissAlignmentAnimation(_controller, _childAlign, _dir).value;
    } else {
      alignment = _childAlign;
    }

    return Align(
      alignment: alignment,
      child: widget.child,
    );
  }
}

Animation<Alignment> cardDismissAlignmentAnimation(
  AnimationController controller,
  Alignment startAlign,
  Direction dir,
) {
  double x, y;
  // find direction it's being disissed
  if (dir == Direction.right || startAlign.x > 0) {
    // print("RIGHT, $dir");
    x = startAlign.x + 18.0;
    y = startAlign.y + 0.2;
  } else if (dir == Direction.left || startAlign.x < 0) {
    // print("LEFT, $dir");
    x = startAlign.x - 18.0;
    y = startAlign.y + 0.2;
  } else if (dir == Direction.top || startAlign.y > 0) {
    // print("TOP, $dir");
    x = startAlign.x + 0.2;
    y = startAlign.y + 18.0;
  }

  if (dir == null) {
// null means go back to origin
    x = 0.0;
    y = 0.0;
  }

  return AlignmentTween(
    begin: startAlign,
    end: Alignment(x, y),
  ).animate(
    CurvedAnimation(
      parent: controller,
      curve: Interval(0.0, 0.5, curve: Curves.easeIn),
    ),
  );
}

Animation<Alignment> cardBackToOrigin(AnimationController controller,
    Alignment startAlign, Alignment initialAlign) {
  return AlignmentTween(
    begin: startAlign,
    end: initialAlign,
  ).animate(
    CurvedAnimation(
      parent: controller,
      curve: Interval(0.0, 0.5, curve: Curves.easeOut),
    ),
  );
}

typedef TriggerListener = void Function(Direction dir);

class SwipeableWidgetController {
  TriggerListener _listener;

  void triggerSwipeLeft() => _listener(Direction.left);

  void triggerSwipeRight() => _listener(Direction.right);

  void triggerSwipeTop() => _listener(Direction.top);

  void triggerBottom() => _listener(Direction.bottom);

  void setListener(listener) => _listener = listener;
}

enum Direction { left, right, top, bottom }
// class SwipeableDirection {
//   static const int horizontalLeft = 0;
//   static const int horizontalRight = 1;

//   static const int verticalTop = 2;
//   static const int verticalBottom = 3;
// }
