import 'package:flutter/material.dart';

/// A widget that creates a zoom-in animation.
class ZoomIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Function(AnimationController)? controller;
  final bool manualTrigger;
  final bool animate;
  final double from;

  const ZoomIn({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = const Duration(milliseconds: 0),
    this.controller,
    this.manualTrigger = false,
    this.animate = true,
    this.from = 0.0,
  }) : super(key: key);

  @override
  _ZoomInState createState() => _ZoomInState();
}

class _ZoomInState extends State<ZoomIn> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> zoom;
  late Animation<double> opacity;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: widget.duration, vsync: this);
    zoom = Tween<double>(begin: widget.from, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
    opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Interval(0.0, 0.65)),
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
      builder: (context, child) => Transform.scale(
        scale: zoom.value,
        child: Opacity(
          opacity: opacity.value,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A widget that creates a zoom-out animation.
class ZoomOut extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Function(AnimationController)? controller;
  final bool manualTrigger;
  final bool animate;
  final double from;

  const ZoomOut({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = const Duration(milliseconds: 0),
    this.controller,
    this.manualTrigger = false,
    this.animate = true,
    this.from = 1.0,
  }) : super(key: key);

  @override
  _ZoomOutState createState() => _ZoomOutState();
}

class _ZoomOutState extends State<ZoomOut> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> zoom;
  late Animation<double> opacity;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: widget.duration, vsync: this);
    zoom = Tween<double>(begin: widget.from, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
    opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Interval(0.0, 0.65)),
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
      builder: (context, child) => Transform.scale(
        scale: zoom.value,
        child: Opacity(
          opacity: opacity.value,
          child: widget.child,
        ),
      ),
    );
  }
}