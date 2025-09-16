import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../config/theme/ColorPages.dart';
import 'svg_icons/CustomSvgIcons.dart';

class EnhancedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int cartItemCount;

  const EnhancedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartItemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: CustomSvgIcons.home,
              label: 'Accueil',
              isSelected: currentIndex == 0,
            ),
            _buildNavItem(
              index: 1,
              icon: CustomSvgIcons.shoppingCart,
              label: 'Panier',
              isSelected: currentIndex == 1,
              badgeCount: cartItemCount,
            ),
            _buildNavItem(
              index: 2,
              icon: CustomSvgIcons.medicalRequest,
              label: 'Demandes',
              isSelected: currentIndex == 2,
            ),
            _buildNavItem(
              index: 3,
              icon: CustomSvgIcons.profile,
              label: 'Profil',
              isSelected: currentIndex == 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required Widget Function({double size, Color? color}) icon,
    required String label,
    required bool isSelected,
    int? badgeCount,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with animation and badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Icon container with background animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isSelected ? 45 : 38,
                  height: isSelected ? 45 : 38,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(isSelected ? 15 : 12),
                    border: isSelected 
                        ? Border.all(
                            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: isSelected ? 1.1 : 1.0,
                      child: icon(
                        size: isSelected ? 22 : 20,
                        color: isSelected
                            ? ColorPages.COLOR_PRINCIPAL
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                
                // Badge for cart items
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: FadeIn(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: ColorPages.COLOR_PRINCIPAL,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : badgeCount.toString(),
                            style: GoogleFonts.ubuntu(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 2),
            
            // Label with animation
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.ubuntu(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? ColorPages.COLOR_PRINCIPAL
                    : Colors.grey.shade600,
              ),
              child: Text(label),
            ),
            
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(top: 1),
              width: isSelected ? 6 : 0,
              height: isSelected ? 6 : 0,
              decoration: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Floating Action Button for QR Scanner
class EnhancedQRFab extends StatelessWidget {
  final VoidCallback onPressed;

  const EnhancedQRFab({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorPages.COLOR_PRINCIPAL,
            ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32.5),
        boxShadow: [
          BoxShadow(
            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32.5),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(32.5),
          child: Center(
            child: CustomSvgIcons.qrScanner(
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom Navigation Bar with Notch for FAB
class BottomNavBarWithNotch extends StatelessWidget {
  final Widget child;

  const BottomNavBarWithNotch({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Bottom Navigation Bar
        child,
        
        // Notch for FAB
        Positioned(
          bottom: 45,
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(37.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom Bottom Navigation Bar Shape with Notch
class BottomNavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Start from top-left corner
    path.moveTo(0, 25);
    
    // Top-left rounded corner
    path.quadraticBezierTo(0, 0, 25, 0);
    
    // Line to notch start
    path.lineTo(size.width / 2 - 40, 0);
    
    // Create notch for FAB
    path.quadraticBezierTo(size.width / 2 - 40, 0, size.width / 2 - 35, 5);
    path.quadraticBezierTo(size.width / 2 - 25, 15, size.width / 2 - 25, 25);
    path.lineTo(size.width / 2 - 25, 30);
    path.quadraticBezierTo(size.width / 2 - 25, 40, size.width / 2 - 15, 45);
    path.quadraticBezierTo(size.width / 2, 50, size.width / 2 + 15, 45);
    path.quadraticBezierTo(size.width / 2 + 25, 40, size.width / 2 + 25, 30);
    path.lineTo(size.width / 2 + 25, 25);
    path.quadraticBezierTo(size.width / 2 + 25, 15, size.width / 2 + 35, 5);
    path.quadraticBezierTo(size.width / 2 + 40, 0, size.width / 2 + 40, 0);
    
    // Line to top-right corner
    path.lineTo(size.width - 25, 0);
    
    // Top-right rounded corner
    path.quadraticBezierTo(size.width, 0, size.width, 25);
    
    // Right side
    path.lineTo(size.width, size.height);
    
    // Bottom side
    path.lineTo(0, size.height);
    
    // Close path
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
