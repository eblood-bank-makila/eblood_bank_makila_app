import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme/ColorPages.dart';
import '../widgets/ModernSpinnerWidget.dart';

class SpinnerDemoPage extends StatefulWidget {
  const SpinnerDemoPage({super.key});

  @override
  State<SpinnerDemoPage> createState() => _SpinnerDemoPageState();
}

class _SpinnerDemoPageState extends State<SpinnerDemoPage> {
  bool _showOverlay = false;
  bool _isButtonLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enhanced Spinners Demo',
          style: GoogleFonts.ubuntu(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  '🎨 Beautiful Modern Spinners',
                  style: GoogleFonts.ubuntu(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enhanced loading animations for your blood bank app',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Spinner Types Grid
                _buildSpinnerSection('Blood Drop Spinner', SpinnerType.bloodDrop, 
                    'Perfect for blood bank theme with pulsing animation'),
                
                _buildSpinnerSection('Pulse Spinner', SpinnerType.pulse, 
                    'Heartbeat-like animation for medical apps'),
                
                _buildSpinnerSection('Dots Spinner', SpinnerType.dots, 
                    'Classic three-dot loading animation'),
                
                _buildSpinnerSection('Ring Spinner', SpinnerType.ring, 
                    'Modern circular progress with gradient'),
                
                _buildSpinnerSection('Heartbeat Spinner', SpinnerType.heartbeat, 
                    'Heart icon with beating animation'),
                
                _buildSpinnerSection('Wave Spinner', SpinnerType.wave, 
                    'Sound wave-like loading bars'),

                const SizedBox(height: 32),

                // Interactive Demos
                _buildInteractiveSection(),

                const SizedBox(height: 32),

                // Button Spinner Demo
                _buildButtonSpinnerSection(),

                const SizedBox(height: 32),

                // Shimmer Demo
                _buildShimmerSection(),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // Full-screen overlay demo
          ModernLoadingOverlay(
            isVisible: _showOverlay,
            message: 'Loading your data...\nPlease wait',
            spinnerType: SpinnerType.bloodDrop,
            spinnerColor: ColorPages.COLOR_PRINCIPAL,
          ),
        ],
      ),
    );
  }

  Widget _buildSpinnerSection(String title, SpinnerType type, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Spinner
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: ModernSpinnerWidget(
                type: type,
                size: 50,
                color: ColorPages.COLOR_PRINCIPAL,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Interactive Demo',
            style: GoogleFonts.ubuntu(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          const SizedBox(height: 16),
          
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showOverlay = true;
              });
              
              // Auto-hide after 3 seconds
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _showOverlay = false;
                  });
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Show Full-Screen Loading Overlay',
              style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonSpinnerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔘 Button Loading States',
            style: GoogleFonts.ubuntu(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isButtonLoading ? null : () {
                setState(() {
                  _isButtonLoading = true;
                });
                
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _isButtonLoading = false;
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isButtonLoading
                  ? const ModernButtonSpinner(
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      'Click to See Button Loading',
                      style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Shimmer Loading Effect',
            style: GoogleFonts.ubuntu(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          ModernShimmerWidget(
            isLoading: true,
            child: Column(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  width: double.infinity * 0.7,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  width: double.infinity * 0.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
