import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierCtrl.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierPage.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/qr_action/QrCodeActionPage.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/blood_request/BloodRequestPage.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BanquePage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/NotificationPush.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/framework/UtilisateurLocalServiceImpl.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/ProfilePage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'EnhancedBottomNavBar.dart';
import 'package:path/path.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await Firebase.initializeApp();

  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print('Handling a background message ${message.messageId}');
}

class BottomNavBarWidget extends ConsumerStatefulWidget {
  const BottomNavBarWidget({super.key});

  @override
  ConsumerState createState() => _BottomNavBarWidgetState();
}

class _BottomNavBarWidgetState extends ConsumerState<BottomNavBarWidget> {
  //int currentIndex = 0;
  //
  // // List of pages to display
  // final List<Widget> pages = [
  //   Banquepage(),
  //   Recherchepage(),
  //   PanierPage(),
  //   ProfilePage(),
  // ];

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

  int selectedIndex = 0;
  late final List<Widget> page;

  @override
  void initState() {
    page = [
      Banquepage(),
      PanierPage(),
      const BloodRequestPage(),
      ProfilePage(),
    ];
    Future.delayed(const Duration(seconds: 10), () {
      initiateFCMApp();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var state = ref.watch(panierCtrlProvider);
    final cartItemCount = state.paniers?.data.isNotEmpty == true
        ? state.paniers!.data[0].cartItems.length
        : 0;

    return Scaffold(
      body: page[selectedIndex],
      extendBody: true,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: EnhancedQRFab(
          onPressed: () {
            print("🔍 QR Scanner FAB pressed!");
            _showQRActionBottomSheet(context);
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: EnhancedBottomNavBar(
        currentIndex: selectedIndex,
        cartItemCount: cartItemCount,
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
      ),
    );
  }

  navBarPage(iconName) {
    return Center(
      child: Icon(
        iconName,
        size: 100,
        color: ColorPages.COLOR_PRINCIPAL,
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
                const Text(
                  'Actions QR Code',
                  style: TextStyle(
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
              title: 'Confirmer la livraison',
              subtitle: 'Scanner le QR code pour confirmer la réception',
              onTap: () => _confirmDelivery(context),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context: context,
              icon: Icons.lock_outline,
              title: 'Demander le mot de passe',
              subtitle: 'Obtenir le code d\'accès sécurisé',
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
