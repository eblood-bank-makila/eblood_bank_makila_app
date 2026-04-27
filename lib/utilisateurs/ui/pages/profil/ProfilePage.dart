import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_provider.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/admin/ProfileUsersPage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/roles/org_roles_page.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/admin/ProfileUserDevicesPage.dart';
import 'package:eblood_bank_mak_app/apps/autres/AproposPage.dart';
import 'package:eblood_bank_mak_app/apps/autres/ParametrePage.dart';
import 'package:eblood_bank_mak_app/apps/autres/AidePage.dart';
import 'package:eblood_bank_mak_app/apps/autres/ContactezNousPage.dart';
import 'package:eblood_bank_mak_app/apps/autres/PolitiqueConfidentialitePage.dart';
import 'package:eblood_bank_mak_app/apps/autres/ConditionsGeneralesPage.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/config/enums/CommonConfigType.dart';
import 'package:eblood_bank_mak_app/apps/services/LanguageService.dart';
import 'package:eblood_bank_mak_app/commande/business/model/DatumPanierModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/favoris/FavorisPage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/notification/NotificationPage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/InformationPage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/ProfileCtrl.dart';
import 'package:eblood_bank_mak_app/apps/widgets/HospitalQRCodeWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:eblood_bank_mak_app/apps/services/AuthService.dart';

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
    var emailList = state.user?.uCourriels ?? [];
    final String primaryEmail = emailList.isNotEmpty ? emailList[0].email : '';
    var prenom = state.user?.uPrenom ?? '';
    var nom = state.user?.uNom ?? '';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade100,
              Colors.red.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(context, prenom, nom, primaryEmail),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
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

  Widget _buildModernHeader(BuildContext context, String prenom, String nom, String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header with settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'profile'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Iconsax.setting_2, color: ColorPages.COLOR_PRINCIPAL),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const ParametrePage()));
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Profile Avatar and Info
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 100),
            from: 70,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InformationPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
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
                        backgroundImage: AssetImage('assets/images/logo.png'),
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
                                  color: ColorPages.COLOR_PRINCIPAL,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                nom.capitalizeFirstLetter(),
                                style: GoogleFonts.ubuntu(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: ColorPages.COLOR_PRINCIPAL,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: GoogleFonts.ubuntu(
                                color: Colors.black.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Iconsax.arrow_right_3,
                      color: ColorPages.COLOR_PRINCIPAL,
                      size: 18,
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
          _buildSectionTitle('my_account'.tr.toUpperCase()),
          const SizedBox(height: 16),

          // Account Type
          _buildAccountTypeListTile(),

          // Hospital QR Code (only for hospital accounts)
          if (_isHospitalAccount()) ...[
            const SizedBox(height: 8),
            _buildHospitalQRCodeListTile(),
          ],

          _buildModernListTile(
            icon: Iconsax.heart,
            title: 'favorites'.tr,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavorisPage()));
            },
          ),

          _buildModernListTile(
            icon: Iconsax.notification,
            title: 'notifications'.tr,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationPage(
                            notification: [],
                          )));
            },
          ),

          const SizedBox(height: 32),

          // Administration Section (blood_bank, hospital, cnts only)
          _buildAdminSection(context),

          // General Section
          _buildSectionTitle('general'.tr.toUpperCase()),
          const SizedBox(height: 16),

          _buildModernListTile(
            icon: Iconsax.info_circle,
            title: 'about'.tr,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AproposPage()));
            },
          ),

          _buildModernListTile(
            icon: Iconsax.message_question,
            title: 'help'.tr,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AidePage()));
            },
          ),

          _buildLanguageListTile(),

          const SizedBox(height: 32),

          // Support Section
          _buildSectionTitle('support_and_feedback'.tr.toUpperCase()),
          const SizedBox(height: 16),

          _buildModernListTile(
            icon: Iconsax.call,
            title: 'contact_us'.tr,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ContactezNousPage()));
            },
          ),

          _buildModernListTile(
            icon: Iconsax.star,
            title: 'rate_app'.tr,
            onTap: () async {
              final Uri url = Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.example.your_app_id');
              if (!await launchUrl(url)) {
                throw Exception('Could not launch $url');
              }
            },
          ),

          _buildModernListTile(
            icon: Iconsax.share,
            title: 'share_app'.tr + ' E-Blood Bank',
            onTap: () {
              Share.share('https://play.google.com/store/apps/e-blood');
            },
          ),

          const SizedBox(height: 32),

          // App Info Section
          _buildSectionTitle('app_information'.tr.toUpperCase()),
          const SizedBox(height: 16),

          _buildModernListTile(
            icon: Iconsax.shield_tick,
            title: 'privacy'.tr,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const PolitiqueConfidentialitePage()));
            },
          ),

          _buildModernListTile(
            icon: Iconsax.document_text,
            title: 'terms'.tr,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ConditionsGeneralesPage()));
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

  /// RBAC-conditional administration section — only visible when the user
  /// has at least one of the admin sub_menu flags (users, roles, devices).
  Widget _buildAdminSection(BuildContext context) {
    final rbac = ref.read(rbacProvider.notifier);
    final hasUsers = rbac.hasMenuFlag('flutter_apps_eblood_bank_profile_users');
    final hasRoles = rbac.hasMenuFlag('flutter_apps_eblood_bank_profile_roles');
    final hasDevices = rbac.hasMenuFlag('flutter_apps_eblood_bank_profile_user_devices');

    if (!hasUsers && !hasRoles && !hasDevices) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('administration'.tr.toUpperCase()),
        const SizedBox(height: 16),
        if (hasUsers)
          _buildModernListTile(
            icon: Iconsax.people,
            title: 'users_management'.tr,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileUsersPage()),
            ),
          ),
        if (hasRoles)
          _buildModernListTile(
            icon: Iconsax.shield_tick,
            title: 'roles_management'.tr,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrgRolesPage()),
            ),
          ),
        if (hasDevices)
          _buildModernListTile(
            icon: Iconsax.mobile,
            title: 'user_devices'.tr,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileUserDevicesPage()),
            ),
          ),
        const SizedBox(height: 32),
      ],
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
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
          width: 1,
        ),
        // color: Colors.grey.shade50,
        // borderRadius: BorderRadius.circular(16),
        // border: Border.all(
        //   color: Colors.grey.shade200,
        //   width: 1,
        // ),
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
                Iconsax.arrow_right_3,
                size: 18,
                color: Colors.grey.shade400,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildLanguageListTile() {
    final languageService = Get.find<LanguageService>();

    return Obx(() {
      final currentLang = languageService.currentLanguageInfo;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ListTile(
          onTap: () => _showLanguageBottomSheet(context),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Iconsax.global,
              size: 20,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          title: Text(
            'language'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            currentLang['name'] ?? 'English',
            style: GoogleFonts.ubuntu(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLang['flag'] ?? '🇬🇧',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Icon(
                Iconsax.arrow_right_3,
                size: 18,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    });
  }

  Widget _buildAccountTypeListTile() {
    var state = ref.watch(profileCtrlProvider);

    // First try to get account type from user data
    var accountType = state.user?.accountType ?? ECommonConfigType.none;

    // If still undefined, try to get from stored account_type (same logic as AccountTypeBasedNavigation)
    if (accountType == ECommonConfigType.none) {
      final storage = GetStorage();
      final storedAccountType = (storage.read('account_type') as String?)?.toLowerCase().trim() ?? '';
      accountType = _parseStoredAccountType(storedAccountType);
    }

    var accountTypeName = _localizedAccountType(accountType);
    var accountTypeColor = _getAccountTypeColor(accountType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accountTypeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getAccountTypeIcon(accountType),
            size: 20,
            color: accountTypeColor,
          ),
        ),
        title: Text(
          'account_type'.tr,
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
            color: accountTypeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accountTypeColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            accountTypeName,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accountTypeColor,
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

  String _localizedAccountType(ECommonConfigType type) {
    switch (type) {
      case ECommonConfigType.personal:
        return 'personal_account'.tr;
      case ECommonConfigType.hospital:
        return 'hospital_account'.tr;
      case ECommonConfigType.bloodBank:
        return 'blood_bank_account'.tr;
      case ECommonConfigType.deliveryPerson:
        return 'delivery_person'.tr;
      case ECommonConfigType.system:
        return 'system_account'.tr;
      case ECommonConfigType.none:
        return 'account_type_undefined'.tr;
    }
  }

  /// Parse stored account type string to ECommonConfigType
  /// Uses the same logic as AccountTypeBasedNavigation
  ECommonConfigType _parseStoredAccountType(String? accountTypeString) {
    if (accountTypeString == null || accountTypeString.isEmpty) {
      return ECommonConfigType.personal; // Default to personal
    }

    final lowerType = accountTypeString.toLowerCase().trim();

    switch (lowerType) {
      case 'hospital':
      case 'hopital':
      case 'hôpital':
        return ECommonConfigType.hospital;
      case 'blood_bank':
      case 'bloodbank':
      case 'banque_sang':
      case 'banque_de_sang':
        return ECommonConfigType.bloodBank;
      case 'customer':
      case 'consommateur':
      case 'consumer':
      case 'personal':
        return ECommonConfigType.personal;
      case 'delivery':
      case 'delivery_person':
      case 'livreur':
      case 'deliverer':
        return ECommonConfigType.deliveryPerson;
      case 'blood_donor':
      case 'blood donor':
      case 'blooddonor':
      case 'donneur':
      case 'donneur_sang':
      case 'donneur de sang':
        // Blood donor is treated as personal account type with donor profile
        return ECommonConfigType.personal;
      default:
        debugPrint('🤔 Unknown account type: $accountTypeString, defaulting to personal');
        return ECommonConfigType.personal;
    }
  }

  /// Get color for account type
  Color _getAccountTypeColor(ECommonConfigType type) {
    switch (type) {
      case ECommonConfigType.personal:
        return Colors.blue.shade600;
      case ECommonConfigType.hospital:
        return Colors.red.shade600;
      case ECommonConfigType.bloodBank:
        return Colors.orange.shade600;
      case ECommonConfigType.deliveryPerson:
        return Colors.green.shade600;
      case ECommonConfigType.system:
        return Colors.purple.shade600;
      case ECommonConfigType.none:
        return Colors.grey.shade600;
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
                  Iconsax.logout,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'sign_out'.tr,
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

  void _showLanguageBottomSheet(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              'select_language'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorPages.COLOR_PRINCIPAL,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'choose_preferred_language'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            // Language options
            Obx(() {
              return Column(
                children: languageService.availableLanguages.map((lang) {
                  final isSelected = languageService.currentLanguage == lang['code'];

                  return FadeInUp(
                    duration: const Duration(milliseconds: 300),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                            ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        ),
                        child: Center(
                          child: Text(
                            lang['flag']!,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      title: Text(
                        lang['name']!,
                        style: GoogleFonts.ubuntu(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        lang['nativeName']!,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: ColorPages.COLOR_PRINCIPAL,
                            )
                          : null,
                      selected: isSelected,
                      selectedTileColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.05),
                      onTap: () async {
                        final navigator = Navigator.of(bottomSheetContext);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        await languageService.changeLanguage(lang['code']!);
                        navigator.pop();

                        // Show success message
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'language_changed'.tr,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: ColorPages.COLOR_PRINCIPAL,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            }),

            const SizedBox(height: 20),
          ],
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
                  Iconsax.logout,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'sign_out'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'logout_confirmation'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'cancel'.tr,
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
                'sign_out'.tr,
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

  /// Check if current user is a hospital account
  bool _isHospitalAccount() {
    var state = ref.watch(profileCtrlProvider);
    
    // First try to get account type from user data
    var accountType = state.user?.accountType ?? ECommonConfigType.none;

    // If still undefined, try to get from stored account_type
    if (accountType == ECommonConfigType.none) {
      final storage = GetStorage();
      final storedAccountType = (storage.read('account_type') as String?)?.toLowerCase().trim() ?? '';
      accountType = _parseStoredAccountType(storedAccountType);
    }

    // Also check profil flags for mobile_app_health_structure_profil
    final storage = GetStorage();
    final userProfils = storage.read('user_profils');
    if (userProfils is List && userProfils.isNotEmpty) {
      for (var profil in userProfils) {
        if (profil is Map) {
          final flag = profil['profil']?.toString() ?? '';
          if (flag == 'mobile_app_health_structure_profil') {
            return true;
          }
        }
      }
    }

    return accountType == ECommonConfigType.hospital;
  }

  /// Build Hospital QR Code list tile
  Widget _buildHospitalQRCodeListTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => const HospitalQRCodeWidget(showInDialog: true),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Iconsax.scan_barcode,
            size: 20,
            color: ColorPages.COLOR_PRINCIPAL,
          ),
        ),
        title: Text(
          'hospital_qr_code'.tr.isEmpty ? 'Hospital QR Code' : 'hospital_qr_code'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          'view_qr_identifier'.tr.isEmpty 
              ? 'View and share your hospital identifier' 
              : 'view_qr_identifier'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(
          Iconsax.arrow_right_3,
          size: 18,
          color: Colors.grey,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    Navigator.of(context).pop(); // Close confirmation dialog

    // Save all context-dependent references before async operations
    final goRouter = GoRouter.of(context);

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Center(
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
                  'logging_out'.tr,
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

      // Perform full logout (clears all local data, calls backend, then clears token)
      await AuthService().logout();

      // Navigate to welcome IMMEDIATELY — goRouter.go() replaces the entire
      // route stack, which automatically removes the loading dialog overlay.
      // We must navigate before RBAC rebuild can show the no-access screen.
      goRouter.go('/welcome');
    } catch (e) {
      // On error, try to dismiss loading dialog and navigate anyway
      goRouter.go('/welcome');
    }
  }
}
