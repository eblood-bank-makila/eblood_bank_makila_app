import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../pages/BloodBankHomePage.dart';
import '../pages/BloodBankInventoryPage.dart';
import '../pages/BloodBankRequestsPage.dart';
import '../../../utilisateurs/ui/pages/profil/ProfilePage.dart';

class BloodBankBottomNavWidget extends ConsumerStatefulWidget {
  const BloodBankBottomNavWidget({super.key});

  @override
  ConsumerState<BloodBankBottomNavWidget> createState() => _BloodBankBottomNavWidgetState();
}

class _BloodBankBottomNavWidgetState extends ConsumerState<BloodBankBottomNavWidget> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BloodBankHomePage(),
    const BloodBankInventoryPage(),
    const BloodBankRequestsPage(),
    const ProfilePage(),
  ];

  final List<BottomNavItem> _navItems = [
    BottomNavItem(
      icon: Iconsax.home,
      activeIcon: Iconsax.home_15,
      label: 'Accueil',
    ),
    BottomNavItem(
      icon: Iconsax.box,
      activeIcon: Iconsax.box_15,
      label: 'Inventaire',
    ),
    BottomNavItem(
      icon: Iconsax.document_text,
      activeIcon: Iconsax.document_text_15,
      label: 'Demandes',
    ),
    BottomNavItem(
      icon: Iconsax.profile_circle,
      activeIcon: Iconsax.profile_circle5,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == index;

              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          key: ValueKey(isSelected),
                          color: isSelected 
                              ? ColorPages.COLOR_PRINCIPAL
                              : Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected 
                              ? ColorPages.COLOR_PRINCIPAL
                              : Colors.grey.shade600,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
