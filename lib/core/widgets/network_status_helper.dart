import 'package:flutter/material.dart';

class NetworkStatusWrapper {
  static void wrapApp({required Widget app, void Function()? onRetry}) {
    // This is a placeholder for wrapping the entire app with network status handling
    // You can implement this to show network status across the whole app
  }
}

// Simple extension method for easier use
extension NetworkStatusExtension on Widget {
  Widget withNetworkStatus({VoidCallback? onRetry}) {
    return Builder(
      builder: (context) => Column(
        children: [
          // Network status banner would appear here when needed
          Expanded(child: this),
        ],
      ),
    );
  }
}