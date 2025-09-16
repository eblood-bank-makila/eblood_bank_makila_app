import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme/ColorPages.dart';
import '../../gestionStocks/ui/pages/blood_bank/BloodBankHomePage.dart';
import '../../gestionStocks/ui/pages/blood_bank/BloodBankInventoryPage.dart';
import '../../commande/ui/pages/blood_request/BloodRequestPage.dart';
import '../../utilisateurs/ui/pages/profil/ProfilePage.dart';
import '../../commande/ui/pages/qr_action/QrCodeActionPage.dart';

class BloodBankBottomNavWidget extends ConsumerStatefulWidget {
  const BloodBankBottomNavWidget({super.key});

  @override
  ConsumerState<BloodBankBottomNavWidget> createState() => _BloodBankBottomNavWidgetState();
}

class _BloodBankBottomNavWidgetState extends ConsumerState<BloodBankBottomNavWidget> {
  int selectedIndex = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      const BloodBankHomePage(),      // Home with stats
      const BloodBankInventoryPage(), // Inventory management
      const BloodRequestPage(),       // Blood requests
      ProfilePage(),                  // Profile (common for all)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      extendBody: true,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: EnhancedQRFab(
          onPressed: () {
            debugPrint("🔍 Blood Bank QR Scanner FAB pressed!");
            _showQRActionBottomSheet(context);
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BloodBankBottomNavBar(
        currentIndex: selectedIndex,
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
      ),
    );
  }

  void _showQRActionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Actions QR Code',
              style: GoogleFonts.ubuntu(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez une action à effectuer',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action options for Blood Bank
            _buildActionOption(
              context: context,
              icon: Iconsax.scan_barcode,
              title: 'Scanner Stock',
              subtitle: 'Vérifier les stocks de sang',
              onTap: () => _scanStock(context),
            ),
            const SizedBox(height: 12),
            _buildActionOption(
              context: context,
              icon: Iconsax.document_text,
              title: 'Valider Demande',
              subtitle: 'Confirmer une demande de sang',
              onTap: () => _validateRequest(context),
            ),
            const SizedBox(height: 12),
            _buildActionOption(
              context: context,
              icon: Iconsax.box_tick,
              title: 'Confirmer Livraison',
              subtitle: 'Valider la réception d\'une livraison',
              onTap: () => _confirmDelivery(context),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _scanStock(BuildContext context) {
    Navigator.pop(context); // Close bottom sheet
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrCodeActionPage(
          actionType: QrCodeActionType.stockVerification,
        ),
      ),
    );
  }

  void _validateRequest(BuildContext context) {
    Navigator.pop(context); // Close bottom sheet
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrCodeActionPage(
          actionType: QrCodeActionType.requestValidation,
        ),
      ),
    );
  }

  void _confirmDelivery(BuildContext context) {
    Navigator.pop(context); // Close bottom sheet
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrCodeActionPage(
          actionType: QrCodeActionType.deliveryValidation,
        ),
      ),
    );
  }
}

class BloodBankBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BloodBankBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
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
              icon: Iconsax.home,
              label: 'Accueil',
              isSelected: currentIndex == 0,
            ),
            _buildNavItem(
              index: 1,
              icon: Iconsax.box,
              label: 'Inventaire',
              isSelected: currentIndex == 1,
            ),
            _buildNavItem(
              index: 2,
              icon: Iconsax.document_text,
              label: 'Demandes',
              isSelected: currentIndex == 2,
            ),
            _buildNavItem(
              index: 3,
              icon: Iconsax.profile_circle,
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
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isSelected ? 45 : 38,
              height: isSelected ? 45 : 38,
              decoration: BoxDecoration(
                color: isSelected 
                    ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(isSelected ? 12 : 10),
              ),
              child: Icon(
                icon,
                size: isSelected ? 24 : 22,
                color: isSelected 
                    ? ColorPages.COLOR_PRINCIPAL 
                    : Colors.grey.shade500,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Label with animation
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.ubuntu(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? ColorPages.COLOR_PRINCIPAL 
                    : Colors.grey.shade500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced QR FAB for Blood Bank
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorPages.COLOR_PRINCIPAL,
            ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(32.5),
        boxShadow: [
          BoxShadow(
            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(32.5),
          child: const Icon(
            Iconsax.scan_barcode,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
