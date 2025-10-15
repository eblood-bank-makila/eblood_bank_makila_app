import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that creates a shake animation.
class Shake extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final bool infinite;
  final Function(AnimationController)? controller;
  final bool manualTrigger;
  final bool animate;
  final double from;

  const Shake({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 900),
    this.delay = const Duration(milliseconds: 0),
    this.infinite = false,
    this.controller,
    this.manualTrigger = false,
    this.animate = true,
    this.from = 10.0,
  }) : super(key: key);

  @override
  _ShakeState createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: widget.duration, vsync: this);

    animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    if (widget.controller is Function) {
      widget.controller!(controller);
    }

    if (widget.animate && !widget.manualTrigger) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          if (widget.infinite) {
            controller.repeat(reverse: true);
          } else {
            controller.forward();
          }
        }
      });
    }

    if (widget.manualTrigger && widget.animate) {
      if (widget.infinite) {
        controller.repeat(reverse: true);
      } else {
        controller.forward();
      }
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
      animation: animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          math.sin(animation.value * math.pi * 8) * widget.from,
          0,
        ),
        child: widget.child,
      ),
    );
  }
}