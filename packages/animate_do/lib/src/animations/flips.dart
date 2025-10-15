import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that creates a flip animation.
class FlipInX extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Function(AnimationController)? controller;
  final bool manualTrigger;
  final bool animate;

  const FlipInX({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = const Duration(milliseconds: 0),
    this.controller,
    this.manualTrigger = false,
    this.animate = true,
  }) : super(key: key);

  @override
  _FlipInXState createState() => _FlipInXState();
}

class _FlipInXState extends State<FlipInX> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> rotation;
  late Animation<double> opacity;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: widget.duration, vsync: this);
    rotation = Tween<double>(begin: 1.5, end: 0.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.bounceOut));
    opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Interval(0, 0.65)));

    if (widget.controller is Function) {
      widget.controller!(controller);
    }

    if (widget.animate && !widget.manualTrigger) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          controller.forward();
        }
      });
    }

    if (widget.manualTrigger && widget.animate) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(rotation.value * math.pi),
        child: Opacity(
          opacity: opacity.value,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A widget that creates a flip animation.
class FlipInY extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Function(AnimationController)? controller;
  final bool manualTrigger;
  final bool animate;

  const FlipInY({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = const Duration(milliseconds: 0),
    this.controller,
    this.manualTrigger = false,
    this.animate = true,
  }) : super(key: key);

  @override
  _FlipInYState createState() => _FlipInYState();
}

class _FlipInYState extends State<FlipInY> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> rotation;
  late Animation<double> opacity;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: widget.duration, vsync: this);
    rotation = Tween<double>(begin: 1.5, end: 0.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.bounceOut));
    opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Interval(0, 0.65)));

    if (widget.controller is Function) {
      widget.controller!(controller);
    }

    if (widget.animate && !widget.manualTrigger) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          controller.forward();
        }
      });
    }

    if (widget.manualTrigger && widget.animate) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(rotation.value * math.pi),
        child: Opacity(
          opacity: opacity.value,
          child: widget.child,
        ),
      ),
    );
  }
}