import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sembast/sembast_io.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../pages/BloodBankHomePage.dart';
import '../pages/BloodBankInventoryPage.dart';
import '../pages/BloodBankRequestsPage.dart';
import '../../../utilisateurs/ui/pages/profil/ProfilePage.dart';
import '../../../apps/connect/announcements/announcements_screen.dart';
import '../../../utilisateurs/business/service/NotificationPush.dart';
import '../../../utilisateurs/ui/framework/UtilisateurLocalServiceImpl.dart';
import '../../services/blood_request_notification_service.dart';

class BloodBankBottomNavWidget extends ConsumerStatefulWidget {
  const BloodBankBottomNavWidget({super.key});

  @override
  ConsumerState<BloodBankBottomNavWidget> createState() => _BloodBankBottomNavWidgetState();
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message for blood bank: ${message.messageId}');
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
      label: 'home',
    ),
    BottomNavItem(
      icon: Iconsax.box,
      activeIcon: Iconsax.box_15,
      label: 'inventory',
    ),
    BottomNavItem(
      icon: Iconsax.document_text,
      activeIcon: Iconsax.document_text_15,
      label: 'requests',
    ),
    BottomNavItem(
      icon: Iconsax.profile_circle,
      activeIcon: Iconsax.profile_circle5,
      label: 'profile',
    ),
  ];

  void initiateFCMForBloodBank() async {
    try {
      await dotenv.load(fileName: ".env");
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(appDir.path, "sembast.db");
      DatabaseFactory dbFactory = databaseFactoryIo;
      Database db = await dbFactory.openDatabase(dbPath);

      var utilisateurLocalImpl = UtilisateurLocalServiceImpl(db);

      // Initialize general FCM service
      FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
      final pushNotificationService =
          PushNotificationService(firebaseMessaging, utilisateurLocalImpl);
      pushNotificationService.initialise();

      // Initialize blood request notification service
      final localNotifications = FlutterLocalNotificationsPlugin();
      final bloodRequestNotificationService = BloodRequestNotificationService(
        fcm: firebaseMessaging,
        localNotifications: localNotifications,
        ref: ref,
      );
      await bloodRequestNotificationService.initialize();

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      print('✅ FCM initialized for Blood Bank');
    } catch (e) {
      print('❌ Error initializing FCM for Blood Bank: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      initiateFCMForBloodBank();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      // floatingActionButton: _buildCenterFab(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar() {
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
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                              : Colors.black,
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
                              : Colors.black,
                        ),
                        child: Text(item.label.tr),
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

  // Floating Action Button placed centered above the bottom bar
  Widget _buildCenterFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          heroTag: 'bb_center_fab',
          backgroundColor: ColorPages.COLOR_PRINCIPAL,
          elevation: 6,
          shape: const CircleBorder(),
          onPressed: () => _showQuickActionsSheet(context),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.bolt_outlined, color: ColorPages.COLOR_PRINCIPAL),
                  const SizedBox(width: 8),
                  Text(
                    'quick_actions'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildQuickActionItem(
                icon: Icons.group_outlined,
                title: 'donors'.tr,
                subtitle: 'manage_view_donors'.tr,
                onTap: () {
                  Navigator.pop(ctx);
                  // Navigate to the blood bank donors management screen
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (_) => const DonorsManagementPage(),
                  //   ),
                  // );
                },
              ),
              const SizedBox(height: 12),
              _buildQuickActionItem(
                icon: Icons.campaign_outlined,
                title: 'announcements'.tr,
                subtitle: 'create_manage_announcements'.tr,
                onTap: () {
                  Navigator.pop(ctx);
                  // Navigate to the announcements screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AnnouncementsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
              child: Icon(icon, color: ColorPages.COLOR_PRINCIPAL, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ubuntu(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.ubuntu(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
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
