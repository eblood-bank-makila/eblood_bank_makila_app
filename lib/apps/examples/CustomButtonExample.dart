import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import '../widgets/CustomButton.dart';
import '../config/theme/ColorPages.dart';

class CustomButtonExample extends StatelessWidget {
  const CustomButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Button Examples'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Standard button with text
            const CustomButton(
              text: 'Standard Button',
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
            ),
            
            const SizedBox(height: 24),
            
            // Example 2: Button with icon and text
            CustomButton(
              text: 'Inscription',
              icon: Ionicons.person_add_outline,
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            
            const SizedBox(height: 24),
            
            // Example 3: Button with custom child
            CustomButton(
              text: 'Not displayed when child is used',
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Ionicons.finger_print_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verify Identity',
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Using biometric authentication',
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Example 4: Outlined button
            CustomButton(
              text: 'Outlined Button',
              outlined: true,
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              icon: Ionicons.arrow_forward_outline,
            ),
          ],
        ),
      ),
    );
  }
}