import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';

/// Reusable component for displaying sponsor logos footer
///
/// This component displays a "Accompanied by" text followed by 3 sponsor logos
/// arranged horizontally. It's designed to be placed at the bottom of pages.
///
/// Usage:
/// ```dart
/// SponsorFooter()
/// ```
class SponsorFooter extends StatelessWidget {
  /// List of sponsor logo paths
  final List<String> sponsorLogos;

  /// Translation key for the label (default: 'accompanied_by')
  final String labelKey;

  /// Height of each logo (default: 50)
  final double logoHeight;

  /// Spacing between logos (default: 16)
  final double logoSpacing;

  /// Text style for the label
  final TextStyle? labelStyle;

  /// Spacing between label and logos (default: 12)
  final double labelSpacing;

  const SponsorFooter({
    super.key,
    this.sponsorLogos = const [
      'assets/icons/anicns.png',
      'assets/icons/orange.png',
      'assets/icons/cnts.png',
    ],
    this.labelKey = 'accompanied_by',
    this.logoHeight = 50,
    this.logoSpacing = 16,
    this.labelStyle,
    this.labelSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label text
          Text(
            labelKey.tr,
            style: labelStyle ??
                GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
          ),
          
          SizedBox(height: labelSpacing),
          
          // Sponsor logos row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              sponsorLogos.length,
              (index) => Padding(
                padding: EdgeInsets.symmetric(horizontal: logoSpacing / 2),
                child: _buildLogoItem(sponsorLogos[index], index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual logo item with animation
  Widget _buildLogoItem(String logoPath, int index) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: 700 + (index * 100)),
      child: Container(
        height: logoHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          logoPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            );
          },
        ),
      ),
    );
  }
}

