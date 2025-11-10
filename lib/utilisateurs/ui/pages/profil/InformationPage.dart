import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/config/utils/Utils.dart';
import 'package:eblood_bank_mak_app/apps/config/enums/CommonConfigType.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/ProfileCtrl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

class InformationPage extends ConsumerStatefulWidget {
  const InformationPage({super.key});

  @override
  ConsumerState createState() => _InformationPageState();
}

class _InformationPageState extends ConsumerState<InformationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var ctrl = ref.read(profileCtrlProvider.notifier);
      ctrl.getUserCode();
    });
  }

  Widget build(BuildContext context) {
    var state = ref.watch(profileCtrlProvider);
    var emailList = state.user?.uCourriels ?? [];
    final String primaryEmail = emailList.isNotEmpty ? emailList[0].email : '';
    var prenom = state.user?.uPrenom ?? '';
    var nom = state.user?.uNom ?? '';
    var phoneList = state.user?.uTelephones ?? [];
    final String primaryPhone = phoneList.isNotEmpty ? phoneList[0].phoneNumber : '';
    var username = state.user?.uUserName ?? '';
    var accountType = state.user?.accountType;
    var accountTypeName = _localizedAccountType(accountType);

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
                  child: _buildProfileContent(context, prenom, nom, primaryEmail, primaryPhone, username, accountType, accountTypeName),
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
          // Header with back button
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: ColorPages.COLOR_PRINCIPAL),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'my_profile'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Profile Avatar and Info
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Large Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorPages.COLOR_PRINCIPAL,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundImage: AssetImage('assets/images/logo.png'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        prenom.capitalizeFirstLetter(),
                        style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        nom.capitalizeFirstLetter(),
                        style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Email
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: GoogleFonts.ubuntu(
                        color: ColorPages.COLOR_NOIR.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, String prenom, String nom, String email, String phone, String username, ECommonConfigType? accountType, String accountTypeName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Information Section
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'account_information'.tr.toUpperCase(),
              style: GoogleFonts.ubuntu(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Profile Information Cards
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildInfoCard(
              icon: Iconsax.user,
              title: 'full_name'.tr,
              value: '${prenom.capitalizeFirstLetter()} ${nom.capitalizeFirstLetter()}'.trim(),
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),

          const SizedBox(height: 16),

          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: _buildInfoCard(
              icon: Iconsax.sms,
              title: 'registered_email'.tr,
              value: email.isNotEmpty ? email : 'no_data'.tr,
              color: Colors.blue.shade600,
            ),
          ),

          const SizedBox(height: 16),

          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: _buildInfoCard(
              icon: Iconsax.call,
              title: 'phone_label'.tr,
              value: phone.isNotEmpty ? phone : 'no_data'.tr,
              color: Colors.green.shade600,
            ),
          ),

          const SizedBox(height: 16),

          FadeInUp(
            delay: const Duration(milliseconds: 700),
            child: _buildInfoCard(
              icon: Iconsax.user_tag,
              title: 'username'.tr,
              value: username.isNotEmpty ? username : 'no_data'.tr,
              color: Colors.orange.shade600,
            ),
          ),

          const SizedBox(height: 16),

          FadeInUp(
            delay: const Duration(milliseconds: 800),
            child: _buildAccountTypeCard(accountType, accountTypeName),
          ),

          const SizedBox(height: 32),

          // Edit Profile Button
          FadeInUp(
            delay: const Duration(milliseconds: 800),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorPages.COLOR_PRINCIPAL,
                    ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('edit_profile_coming_soon'.tr),
                        backgroundColor: ColorPages.COLOR_PRINCIPAL,
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Iconsax.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'edit_profile'.tr,
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
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
          width: 1,
        ),

        // color: Colors.white,
        // borderRadius: BorderRadius.circular(16),
        // border: Border.all(
        //   color: Colors.grey.shade200,
        //   width: 1,
        // ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
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
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build account type card
  Widget _buildAccountTypeCard(ECommonConfigType? accountType, String accountTypeName) {
    return _buildInfoCard(
      icon: _getAccountTypeIcon(accountType),
      title: 'account_type'.tr,
      value: accountTypeName,
      color: Color(accountType?.colorValue ?? 0xFF9CA3AF),
    );
  }

  /// Get icon for account type
  IconData _getAccountTypeIcon(ECommonConfigType? accountType) {
    if (accountType == null) return Iconsax.profile_circle;

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

  String _localizedAccountType(ECommonConfigType? type) {
    if (type == null) return 'account_type_undefined'.tr;
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
}
