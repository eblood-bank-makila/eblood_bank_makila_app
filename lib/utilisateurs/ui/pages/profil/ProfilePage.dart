import 'package:eblood_bank_mak_app/apps/autres/AproposPage.dart';
import 'package:eblood_bank_mak_app/apps/autres/ParametrePage.dart';
import 'package:eblood_bank_mak_app/apps/autres/AidePage.dart';
import 'package:eblood_bank_mak_app/apps/autres/ContactezNousPage.dart';
import 'package:eblood_bank_mak_app/apps/autres/PolitiqueConfidentialitePage.dart';
import 'package:eblood_bank_mak_app/apps/autres/ConditionsGeneralesPage.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/config/enums/CommonConfigType.dart';
import 'package:eblood_bank_mak_app/commande/business/model/DatumPanierModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/favoris/FavorisPage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/notification/NotificationPage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/InformationPage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/ProfileCtrl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

// String extension for text formatting
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  List<DatumModel> favoris = []; // Initialisez la liste des favoris
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // action initiale de la page et appel d'un controleur
      var ctrl = ref.read(profileCtrlProvider.notifier);
      ctrl.getUserCode();
    });
  }

  @override
  Widget build(BuildContext context) {
    var state = ref.watch(profileCtrlProvider);
    var username = state.user?.uUserName ?? "";
    var email = state.user?.uCourriels ?? [];
    var prenom = state.user?.uPrenom ?? "";
    var nom = state.user?.uNom ?? "";

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorPages.COLOR_PRINCIPAL,
              ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(context, prenom, nom, email),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildProfileContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }

  Widget _buildModernHeader(BuildContext context, String prenom, String nom, List email) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header with settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profil',
                style: GoogleFonts.ubuntu(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => ParametrePage()));
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Profile Avatar and Info
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InformationPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        backgroundImage: AssetImage('assets/images/image8.png'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                prenom.capitalizeFirstLetter(),
                                style: GoogleFonts.ubuntu(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                nom.capitalizeFirstLetter(),
                                style: GoogleFonts.ubuntu(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (email.isNotEmpty)
                            Text(
                              email[0].email ?? "",
                              style: GoogleFonts.ubuntu(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Section
          _buildSectionTitle('MON COMPTE'),
          const SizedBox(height: 16),

          // Account Type
          _buildAccountTypeListTile(),

          _buildModernListTile(
            icon: Icons.favorite_border,
            title: 'Favoris',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FavorisPage()));
            },
          ),

          _buildModernListTile(
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NotificationPage(
                            notification: [],
                          )));
            },
          ),

          const SizedBox(height: 32),

          // General Section
          _buildSectionTitle('GÉNÉRAL'),
          const SizedBox(height: 16),

          _buildModernListTile(
            icon: Icons.info_outline,
            title: 'À propos',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AproposPage()));
            },
          ),

          _buildModernListTile(
            icon: Icons.help_outline_rounded,
            title: 'Aide',
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AidePage()));
            },
          ),

          const SizedBox(height: 32),

          // Support Section
          _buildSectionTitle('SUPPORT ET COMMENTAIRES'),
          const SizedBox(height: 16),

          _buildModernListTile(
            icon: Icons.phone,
            title: 'Contactez-nous',
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ContactezNousPage()));
            },
          ),

          _buildModernListTile(
            icon: Icons.reviews_outlined,
            title: 'Noter l\'application',
            onTap: () async {
              final Uri url = Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.example.your_app_id');
              if (!await launchUrl(url)) {
                throw Exception('Could not launch $url');
              }
            },
          ),

          _buildModernListTile(
            icon: Icons.share,
            title: 'Partager E-Blood Bank',
            onTap: () {
              Share.share("https://play.google.com/store/apps/e-blood");
            },
          ),

          const SizedBox(height: 32),

          // App Info Section
          _buildSectionTitle('INFORMATIONS SUR L\'APPLICATION'),
          const SizedBox(height: 16),

          _buildModernListTile(
            icon: Icons.security,
            title: 'Politique de confidentialité',
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => PolitiqueConfidentialitePage()));
            },
          ),

          _buildModernListTile(
            icon: Icons.info_outline_rounded,
            title: 'Conditions générales',
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ConditionsGeneralesPage()));
            },
          ),

          const SizedBox(height: 32),

          // Logout Section
          _buildLogoutButton(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.ubuntu(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.grey.shade600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildModernListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool showTrailing = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (iconColor ?? ColorPages.COLOR_PRINCIPAL).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? ColorPages.COLOR_PRINCIPAL,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.ubuntu(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: showTrailing
            ? Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildAccountTypeListTile() {
    var state = ref.watch(profileCtrlProvider);
    var accountType = state.user?.accountType ?? ECommonConfigType.none;
    var accountTypeName = state.user?.accountTypeDisplayName ?? "Non défini";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(accountType.colorValue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getAccountTypeIcon(accountType),
            size: 20,
            color: Color(accountType.colorValue),
          ),
        ),
        title: Text(
          'Type de compte',
          style: GoogleFonts.ubuntu(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          accountTypeName,
          style: GoogleFonts.ubuntu(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Color(accountType.colorValue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(accountType.colorValue).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            accountTypeName,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(accountType.colorValue),
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Get icon for account type
  IconData _getAccountTypeIcon(ECommonConfigType accountType) {
    switch (accountType) {
      case ECommonConfigType.bloodBank:
        return Iconsax.heart;
      case ECommonConfigType.hospital:
        return Iconsax.hospital;
      case ECommonConfigType.deliveryPerson:
        return Iconsax.truck;
      case ECommonConfigType.system:
        return Iconsax.setting_2;
      case ECommonConfigType.personal:
        return Iconsax.user;
      case ECommonConfigType.none:
        return Iconsax.profile_circle;
    }
  }

  Widget _buildLogoutButton(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade400,
              Colors.red.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showLogoutDialog(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Se déconnecter',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.logout,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Déconnexion',
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Se déconnecter',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout(BuildContext context) async {
    Navigator.of(context).pop(); // Close dialog

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
                const SizedBox(height: 16),
                Text(
                  'Déconnexion en cours...',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Perform logout
      final ctrl = ref.read(profileCtrlProvider.notifier);
      await ctrl.disconnect();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Navigate to welcome page
        context.go('/welcome');
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
