import 'package:flutter/material.dart';

/// A widget that creates a bounce animation.
class Bounce extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final bool infinite;
  final Function(AnimationController)? controller;
  final bool manualTrigger;
  final bool animate;
  final double from;

  const Bounce({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1300),
    this.delay = const Duration(milliseconds: 0),
    this.infinite = false,
    this.controller,
    this.manualTrigger = false,
    this.animate = true,
    this.from = 50,
  }) : super(key: key);

  @override
  _BounceState createState() => _BounceState();
}

class _BounceState extends State<Bounce> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: widget.duration, vsync: this);

    animation = Tween<double>(begin: -widget.from, end: 0).animate(
      CurvedAnimation(parent: controller, curve: Curves.bounceOut),
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
      animation: controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, animation.value),
        child: widget.child,
      ),
    );
  }
}

/// A widget that creates a pulse animation.
class Pulse extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final bool infinite;
  final Function(AnimationController)? controller;
  final bool manualTrigger;
  final bool animate;
  final double from;

  const Pulse({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.delay = const Duration(milliseconds: 0),
    this.infinite = false,
    this.controller,
    this.manualTrigger = false,
    this.animate = true,
    this.from = 1.0,
  }) : super(key: key);

  @override
  _PulseState createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: widget.duration, vsync: this);
    animation = Tween<double>(begin: widget.from, end: 1.1).animate(
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
      builder: (context, child) => Transform.scale(
        scale: animation.value,
        child: widget.child,
      ),
    );
  }
}