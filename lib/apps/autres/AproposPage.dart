import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class AproposPage extends ConsumerStatefulWidget {
  const AproposPage({super.key});

  @override
  ConsumerState createState() => _AproposPageState();
}

class _AproposPageState extends ConsumerState<AproposPage> {
  final String appVersion = "2.0.0";
  final String buildNumber = "1";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorPages.COLOR_PRINCIPAL,
              ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
              Colors.red.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Modern SliverAppBar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'À propos',
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: _buildContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Header Card
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: _buildAppHeader(),
          ),

          const SizedBox(height: 24),

          // App Info Section
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildInfoSection(),
          ),

          const SizedBox(height: 24),

          // Mission Section
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _buildMissionSection(),
          ),

          const SizedBox(height: 24),

          // Features Section
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildFeaturesSection(),
          ),

          const SizedBox(height: 24),

          // Partners Section
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: _buildPartnersSection(),
          ),

          const SizedBox(height: 24),

          // Contact Section
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: _buildContactSection(),
          ),

          const SizedBox(height: 24),

          // Legal Section
          FadeInUp(
            delay: const Duration(milliseconds: 700),
            child: _buildLegalSection(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // App Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorPages.COLOR_PRINCIPAL,
                  Colors.red.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Iconsax.heart5,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // App Name
          Text(
            'E-Blood Bank Makila',
            style: GoogleFonts.ubuntu(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          const SizedBox(height: 8),

          // Version Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Version $appVersion ($buildNumber)',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: ColorPages.COLOR_PRINCIPAL,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tagline
          Text(
            'Sauver des vies, une goutte à la fois',
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return _buildSection(
      title: 'À propos de l\'application',
      icon: Iconsax.info_circle,
      child: Text(
        'E-Blood Bank Makila utilise des solutions innovantes pour révolutionner le processus de don et de transfusion sanguine. Grâce à sa plateforme numérique, l\'organisation facilite la connexion entre les donneurs de sang et les hôpitaux, améliorant ainsi l\'accessibilité et la disponibilité du sang pour les patients dans le besoin.',
        style: GoogleFonts.ubuntu(
          fontSize: 14,
          color: Colors.grey.shade700,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildMissionSection() {
    return _buildSection(
      title: 'Notre Mission',
      icon: Iconsax.flag,
      backgroundColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.05),
      borderColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
      child: Text(
        'Sauver des vies en facilitant l\'accès au sang pour tous. Nous mettons en œuvre des campagnes de sensibilisation numériques pour éduquer le public sur l\'importance du don de sang et encourager davantage de personnes à devenir des donneurs réguliers.',
        style: GoogleFonts.ubuntu(
          fontSize: 14,
          color: Colors.grey.shade700,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return _buildSection(
      title: 'Fonctionnalités',
      icon: Iconsax.star,
      child: Column(
        children: [
          _buildFeatureItem(
            Iconsax.search_normal,
            'Recherche intelligente',
            'Trouvez rapidement les poches de sang disponibles',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Iconsax.location,
            'Géolocalisation',
            'Localisez les banques de sang les plus proches',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Iconsax.scan_barcode,
            'Scan QR',
            'Identifiez rapidement les hôpitaux partenaires',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Iconsax.truck_fast,
            'Livraison',
            'Suivi en temps réel de vos commandes',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Iconsax.wallet,
            'Paiement facile',
            'Plusieurs options de paiement disponibles',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Iconsax.notification,
            'Notifications',
            'Restez informé des disponibilités en temps réel',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Iconsax.security,
            'Sécurisé',
            'Vos données sont protégées et sécurisées',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
                ColorPages.COLOR_PRINCIPAL,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
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
              Text(
                description,
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartnersSection() {
    return _buildSection(
      title: 'Nos Partenaires',
      icon: Iconsax.people,
      child: Column(
        children: [
          Text(
            'Ils nous accompagnent',
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.center,
            children: [
              _buildPartnerLogo('assets/logo/orange.png'),
              _buildPartnerLogo('assets/logo/ana.jpg'),
              _buildPartnerLogo('assets/logo/drone.jpg'),
              _buildPartnerLogo('assets/logo/isha.jpg'),
              _buildPartnerLogo('assets/logo/jeune.jpg'),
              _buildPartnerLogo('assets/logo/numerique.jpg'),
              _buildPartnerLogo('assets/logo/pad.jpg'),
              _buildPartnerLogo('assets/logo/rfi.jpg'),
              _buildPartnerLogo('assets/logo/viva.jpg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerLogo(String assetPath) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildSection(
      title: 'Contactez-nous',
      icon: Iconsax.call,
      child: Column(
        children: [
          _buildContactItem(
            Iconsax.sms,
            'Email',
            'contact@e-bloodbank.org',
            () => _launchUrl('mailto:contact@e-bloodbank.org'),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Iconsax.call,
            'Téléphone',
            '+243 XXX XXX XXX',
            () => _launchUrl('tel:+243XXXXXXXX'),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Iconsax.global,
            'Site web',
            'www.e-bloodbank.org',
            () => _launchUrl('https://e-bloodbank.org'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return _buildSection(
      title: 'Informations légales',
      icon: Iconsax.document,
      child: Column(
        children: [
          _buildLegalItem(
            'Politique de confidentialité',
            () => _launchUrl('https://e-bloodbank.org/privacy'),
          ),
          const Divider(height: 1),
          _buildLegalItem(
            'Conditions d\'utilisation',
            () => _launchUrl('https://e-bloodbank.org/terms'),
          ),
          const Divider(height: 1),
          _buildLegalItem(
            'Licences Open Source',
            () => showLicensePage(
              context: context,
              applicationName: 'E-Blood Bank Makila',
              applicationVersion: appVersion,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ColorPages.COLOR_PRINCIPAL, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: Colors.blue.shade600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
