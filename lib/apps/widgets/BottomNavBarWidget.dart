import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierCtrl.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/qr_action/QrCodeActionPage.dart';
import 'package:eblood_bank_mak_app/apps/widgets/HospitalQRCodeWidget.dart';
import 'package:eblood_bank_mak_app/services/HealthStructureService.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BanquePage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/NotificationPush.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/framework/UtilisateurLocalServiceImpl.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/ProfilePage.dart';
import 'package:eblood_bank_mak_app/apps/home/hospital_home_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../../gestionStocks/ui/pages/recherchePoche/RecherchePochePage.dart';
import '../../commande/ui/pages/panier/PanierPage.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await Firebase.initializeApp();

  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print('Handling a background message ${message.messageId}');
}

class HospitalBottomNavBarWidget extends ConsumerStatefulWidget {
  const HospitalBottomNavBarWidget({super.key});

  @override
  ConsumerState createState() => _HospitalBottomNavBarWidgetState();
}

class _HospitalBottomNavBarWidgetState extends ConsumerState<HospitalBottomNavBarWidget> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Banquepage(),
    const HospitalHomePage(),
    Recherchepage(query: ''),
    // PanierPage(),
    ProfilePage(),
  ];

  final List<BottomNavItem> _navItems = [
    BottomNavItem(
      icon: Iconsax.box,
      activeIcon: Iconsax.box_15,
      label: 'blood_bags',
    ),
    BottomNavItem(
      icon: Iconsax.home,
      activeIcon: Iconsax.home_15,
      label: 'overview',
    ),
    
    BottomNavItem(
      icon: Iconsax.search_normal,
      activeIcon: Iconsax.search_normal_15,
      label: 'search',
    ),
    // BottomNavItem(
    //   icon: Iconsax.shopping_cart,
    //   activeIcon: Iconsax.shopping_cart5,
    //   label: 'cart',
    // ),
    BottomNavItem(
      icon: Iconsax.profile_circle,
      activeIcon: Iconsax.profile_circle5,
      label: 'profile',
    ),
  ];

  void initiateFCMApp() async {
    await dotenv.load(fileName: ".env");
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, "sembast.db");
    DatabaseFactory dbFactory = databaseFactoryIo;
    Database db = await dbFactory.openDatabase(dbPath);

    var utilisateurLocalImpl = UtilisateurLocalServiceImpl(db);

    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    final pushNotificationService =
        PushNotificationService(firebaseMessaging, utilisateurLocalImpl);
    pushNotificationService.initialise();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  @override
  void initState() {
    super.initState();
    
    // Fetch and cache health structure on app startup for hospital profile
    _initializeHealthStructure();
    
    Future.delayed(const Duration(seconds: 10), () {
      initiateFCMApp();
    });
  }

  /// Initialize health structure data on startup
  void _initializeHealthStructure() async {
    try {
      final healthStructureService = ref.read(healthStructureServiceProvider);
      await healthStructureService.fetchAndCacheHealthStructure();
      print('✅ Health structure initialized on app startup');
    } catch (e) {
      print('⚠️ Failed to initialize health structure: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var state = ref.watch(panierCtrlProvider);
    final cartItemCount = state.paniers?.data.isNotEmpty == true ? state.paniers!.data[0].cartItems.length : 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        statusBarBrightness: Brightness.light, // For iOS
      ),
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        floatingActionButton: FloatingActionButton(
                onPressed: () => _showHospitalQRBottomSheet(context),
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                child: const Icon(Icons.qr_code),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _buildBottomNavigationBar(cartItemCount),
      ),
    );
  }

  Widget _buildBottomNavigationBar(int cartItemCount) {
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == index;
              final isCartTab = item.label == 'cart';

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onItemTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
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
                            // Badge for cart items
                            if (isCartTab && cartItemCount > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  constraints: const BoxConstraints(minWidth: 16),
                                  height: 16,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: ColorPages.COLOR_PRINCIPAL,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cartItemCount > 99 ? '99+' : cartItemCount.toString(),
                                      style: GoogleFonts.ubuntu(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.ubuntu(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? ColorPages.COLOR_PRINCIPAL
                                : Colors.black,
                          ),
                          child: Text(
                            item.label.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
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

  void _showHospitalQRBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // QR Code Widget
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: HospitalQRCodeWidget(),
              ),

              const SizedBox(height: 24),

              // Scan Actions Section
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'scan_actions'.tr.isEmpty ? 'Scan Actions' : 'scan_actions'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Confirm Delivery Button
                  _buildScanActionButton(
                    context: context,
                    icon: Iconsax.truck,
                    iconColor: Colors.green,
                    title: 'confirm_delivery'.tr.isEmpty ? 'Confirm Delivery' : 'confirm_delivery'.tr,
                    subtitle: 'scan_qr_to_confirm'.tr.isEmpty ? 'Scan QR to confirm delivery received' : 'scan_qr_to_confirm'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QrCodeActionPage(
                            actionType: QrCodeActionType.deliveryValidation,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Request Coolbox Password Button
                  _buildScanActionButton(
                    context: context,
                    icon: Iconsax.lock,
                    iconColor: Colors.purple,
                    title: 'request_password'.tr.isEmpty ? 'Request Coolbox Password' : 'request_password'.tr,
                    subtitle: 'get_secure_access_code'.tr.isEmpty ? 'Scan coolbox QR for access code' : 'get_secure_access_code'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QrCodeActionPage(
                            actionType: QrCodeActionType.passwordRequest,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildScanActionButton({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 14,
            ),
          ],
        ),
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
            Row(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: ColorPages.COLOR_PRINCIPAL,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'qr_code_actions'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Action buttons
            _buildActionButton(
              context: context,
              icon: Icons.check_circle_outline,
              title: 'confirm_delivery'.tr,
              subtitle: 'scan_qr_to_confirm'.tr,
              onTap: () => _confirmDelivery(context),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context: context,
              icon: Icons.lock_outline,
              title: 'request_password'.tr,
              subtitle: 'get_secure_access_code'.tr,
              onTap: () => _requestPassword(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
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

  void _confirmDelivery(BuildContext context) {
    Navigator.pop(context); // Close bottom sheet

    // Navigate to delivery validation page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrCodeActionPage(
          actionType: QrCodeActionType.deliveryValidation,
        ),
      ),
    );
  }

  void _requestPassword(BuildContext context) {
    Navigator.pop(context); // Close bottom sheet

    // Navigate to password request page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrCodeActionPage(
          actionType: QrCodeActionType.passwordRequest,
        ),
      ),
    );
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
