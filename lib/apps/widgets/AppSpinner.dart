import 'package:flutter/material.dart';
import 'package:eblood_bank_mak_app/apps/widgets/ModernSpinnerWidget.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';

/// Utility class for consistent spinner usage throughout the app
class AppSpinner {
  
  /// Default blood drop spinner for general loading
  static Widget bloodDrop({
    double size = 50.0,
    Color? color,
    String? message,
    bool showMessage = false,
  }) {
    return ModernSpinnerWidget(
      type: SpinnerType.bloodDrop,
      size: size,
      color: color ?? ColorPages.COLOR_PRINCIPAL,
      message: message,
      showMessage: showMessage,
    );
  }

  /// Pulse spinner for authentication and login
  static Widget pulse({
    double size = 50.0,
    Color? color,
    String? message,
    bool showMessage = false,
  }) {
    return ModernSpinnerWidget(
      type: SpinnerType.pulse,
      size: size,
      color: color ?? ColorPages.COLOR_PRINCIPAL,
      message: message,
      showMessage: showMessage,
    );
  }

  /// Heartbeat spinner for medical/health related loading
  static Widget heartbeat({
    double size = 50.0,
    Color? color,
    String? message,
    bool showMessage = false,
  }) {
    return ModernSpinnerWidget(
      type: SpinnerType.heartbeat,
      size: size,
      color: color ?? ColorPages.COLOR_PRINCIPAL,
      message: message,
      showMessage: showMessage,
    );
  }

  /// Dots spinner for simple loading states
  static Widget dots({
    double size = 50.0,
    Color? color,
    String? message,
    bool showMessage = false,
  }) {
    return ModernSpinnerWidget(
      type: SpinnerType.dots,
      size: size,
      color: color ?? ColorPages.COLOR_PRINCIPAL,
      message: message,
      showMessage: showMessage,
    );
  }

  /// Ring spinner for progress indicators
  static Widget ring({
    double size = 50.0,
    Color? color,
    String? message,
    bool showMessage = false,
  }) {
    return ModernSpinnerWidget(
      type: SpinnerType.ring,
      size: size,
      color: color ?? ColorPages.COLOR_PRINCIPAL,
      message: message,
      showMessage: showMessage,
    );
  }

  /// Wave spinner for data loading
  static Widget wave({
    double size = 50.0,
    Color? color,
    String? message,
    bool showMessage = false,
  }) {
    return ModernSpinnerWidget(
      type: SpinnerType.wave,
      size: size,
      color: color ?? ColorPages.COLOR_PRINCIPAL,
      message: message,
      showMessage: showMessage,
    );
  }

  /// Small spinner for buttons
  static Widget button({
    Color color = Colors.white,
    double size = 20.0,
  }) {
    return ModernButtonSpinner(
      color: color,
      size: size,
    );
  }

  /// Full screen loading overlay
  static Widget overlay({
    required bool isVisible,
    String? message,
    SpinnerType type = SpinnerType.bloodDrop,
    Color? backgroundColor,
    Color? spinnerColor,
    double spinnerSize = 60.0,
  }) {
    return ModernLoadingOverlay(
      isVisible: isVisible,
      message: message,
      spinnerType: type,
      backgroundColor: backgroundColor,
      spinnerColor: spinnerColor ?? ColorPages.COLOR_PRINCIPAL,
      spinnerSize: spinnerSize,
    );
  }

  /// Shimmer loading for content placeholders
  static Widget shimmer({
    required Widget child,
    bool isLoading = true,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return ModernShimmerWidget(
      isLoading: isLoading,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }

  /// Get appropriate spinner for context
  static Widget forContext(BuildContext context, {
    String? contextType,
    double size = 50.0,
    Color? color,
    String? message,
    bool showMessage = false,
  }) {
    SpinnerType type;
    
    switch (contextType?.toLowerCase()) {
      case 'auth':
      case 'login':
      case 'authentication':
        type = SpinnerType.pulse;
        break;
      case 'medical':
      case 'health':
      case 'blood':
      case 'hospital':
        type = SpinnerType.heartbeat;
        break;
      case 'data':
      case 'loading':
      case 'fetch':
        type = SpinnerType.wave;
        break;
      case 'simple':
      case 'basic':
        type = SpinnerType.dots;
        break;
      case 'progress':
      case 'upload':
      case 'download':
        type = SpinnerType.ring;
        break;
      default:
        type = SpinnerType.bloodDrop;
    }

    return ModernSpinnerWidget(
      type: type,
      size: size,
      color: color ?? ColorPages.COLOR_PRINCIPAL,
      message: message,
      showMessage: showMessage,
    );
  }

  /// Predefined spinner configurations for common use cases
  static const Map<String, SpinnerType> presets = {
    'default': SpinnerType.bloodDrop,
    'auth': SpinnerType.pulse,
    'medical': SpinnerType.heartbeat,
    'data': SpinnerType.wave,
    'simple': SpinnerType.dots,
    'progress': SpinnerType.ring,
  };

  /// Get spinner type from preset name
  static SpinnerType getPreset(String presetName) {
    return presets[presetName.toLowerCase()] ?? SpinnerType.bloodDrop;
  }
}

/// Extension methods for easy spinner usage
extension SpinnerExtension on Widget {
  /// Wrap widget with shimmer loading
  Widget withShimmer({
    bool isLoading = true,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return AppSpinner.shimmer(
      isLoading: isLoading,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: this,
    );
  }
}

/// Spinner theme configuration
class SpinnerTheme {
  static const double smallSize = 20.0;
  static const double mediumSize = 40.0;
  static const double largeSize = 60.0;
  static const double extraLargeSize = 80.0;

  static const Duration fastDuration = Duration(milliseconds: 800);
  static const Duration normalDuration = Duration(milliseconds: 1200);
  static const Duration slowDuration = Duration(milliseconds: 1600);
}
