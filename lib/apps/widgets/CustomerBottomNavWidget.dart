import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme/ColorPages.dart';
import '../home/customer_home_page.dart';
import '../connect/announcements/announcements_screen.dart';
import '../../utilisateurs/ui/pages/profil/ProfilePage.dart';
import '../../blood_bank/ui/pages/HealthStructureNetworkPage.dart';

class CustomerBottomNavWidget extends ConsumerStatefulWidget {
  const CustomerBottomNavWidget({super.key});

  @override
  ConsumerState<CustomerBottomNavWidget> createState() => _CustomerBottomNavWidgetState();
}

class _CustomerBottomNavWidgetState extends ConsumerState<CustomerBottomNavWidget> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CustomerHomePage(),                                    // Home - Customer dashboard
    const AnnouncementsScreen(showBackButton: false),            // Announcements - Admin posts & campaigns
    const HealthStructureNetworkPage(showBackButton: false),     // Network - Find nearby health structures (same as blood bank profile)
    ProfilePage(),                                               // Profile - User profile & settings
  ];

  final List<BottomNavItem> _navItems = [
    BottomNavItem(
      icon: Iconsax.home,
      activeIcon: Iconsax.home_15,
      label: 'home',
    ),
    BottomNavItem(
      icon: Iconsax.notification,
      activeIcon: Iconsax.notification_bing,
      label: 'announcements',
    ),
    BottomNavItem(
      icon: Iconsax.location,
      activeIcon: Iconsax.location_add,
      label: 'network',
    ),
    BottomNavItem(
      icon: Iconsax.user,
      activeIcon: Iconsax.user,
      label: 'profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      extendBody: true,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade50,
            Colors.white,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: ColorPages.COLOR_PRINCIPAL,
          unselectedItemColor: Colors.black,
          selectedLabelStyle: GoogleFonts.ubuntu(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.ubuntu(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: _navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Model for bottom navigation items
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

