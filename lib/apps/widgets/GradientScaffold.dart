import 'package:flutter/material.dart';

/// A reusable Scaffold widget with gradient background
/// Applies the app's standard gradient design (Red.shade100 → Red.shade50 → White)
class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;
  final bool useGradient;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: useGradient
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.red.shade100,
                    Colors.red.shade50,
                    Colors.white,
                  ],
                ),
              )
            : BoxDecoration(
                color: backgroundColor ?? Colors.white,
              ),
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}

/// A reusable container with gradient background for content sections
/// Use this for content areas within screens
class GradientContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final bool useGradient;

  const GradientContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(0),
    this.borderRadius,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: useGradient
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.shade100,
                  Colors.red.shade50,
                  Colors.white,
                ],
              ),
              borderRadius: borderRadius,
            )
          : BoxDecoration(
              color: Colors.white,
              borderRadius: borderRadius,
            ),
      padding: padding,
      child: child,
    );
  }
}

/// A reusable bottom navigation bar with gradient background
/// Use this for consistent bottom nav styling across all screens
class GradientBottomNavBar extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const GradientBottomNavBar({
    super.key,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade50,
            Colors.white,
          ],
        ),
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

