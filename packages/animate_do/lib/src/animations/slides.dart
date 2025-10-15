import 'package:flutter/material.dart';

/// A widget that creates a slide-in-left animation.
class SlideInLeft extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Function(AnimationController)? controller;
  final bool manualTrigger;
  final bool animate;
  final double from;

  const SlideInLeft({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = const Duration(milliseconds: 0),
    this.controller,
    this.manualTrigger = false,
    this.animate = true,
    this.from = 100,
  }) : super(key: key);

  @override
  _SlideInLeftState createState() => _SlideInLeftState();
}

class _SlideInLeftState extends State<SlideInLeft> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: widget.duration, vsync: this);
    animation = Tween<double>(begin: -widget.from, end: 0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

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
      builder: (context, child) => Transform.translate(
        offset: Offset(animation.value, 0),
        child: widget.child,
      ),
    );
  }
}

/// A widget that creates a slide-in-right animation.
class SlideInRight extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Function(AnimationController)? controller;
  final bool manualTrigger;
  final bool animate;
  final double from;

  const SlideInRight({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = const Duration(milliseconds: 0),
    this.controller,
    this.manualTrigger = false,
    this.animate = true,
    this.from = 100,
  }) : super(key: key);

  @override
  _SlideInRightState createState() => _SlideInRightState();
}

class _SlideInRightState extends State<SlideInRight> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: widget.duration, vsync: this);
    animation = Tween<double>(begin: widget.from, end: 0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

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
      builder: (context, child) => Transform.translate(
        offset: Offset(animation.value, 0),
        child: widget.child,
      ),
    );
  }
}