import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'BottomNavBarWidget.dart';

class ConsumerMainApp extends ConsumerWidget {
  const ConsumerMainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Explicit customer UI (simple user / donor / delivery)
    return const BottomNavBarWidget();
  }
}
