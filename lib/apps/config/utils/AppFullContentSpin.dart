import 'package:flutter/material.dart';
import 'package:eblood_bank_mak_app/apps/widgets/ModernSpinnerWidget.dart';

class AppFullcontentSpin extends StatelessWidget {
  final Widget child;
  final bool activity_is_running;
  final String message;
  const AppFullcontentSpin(
      {super.key,
        this.message = 'en cours...',
        required this.child,
        this.activity_is_running = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ModernLoadingOverlay(
          isVisible: activity_is_running,
          message: message,
          spinnerType: SpinnerType.pulse,
          backgroundColor: Colors.blue.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}
