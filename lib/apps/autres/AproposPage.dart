import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class AproposPage extends ConsumerStatefulWidget {
  const AproposPage({super.key});

  @override
  ConsumerState createState() => _AproposPageState();
}

class _AproposPageState extends ConsumerState<AproposPage> {
  @override
  Widget build(BuildContext context) {
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
              _buildHeader(context),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back Button
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // About Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Iconsax.info_circle,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'À propos',
                  style: GoogleFonts.ubuntu(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'E-Blood Bank Makila',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Info Section
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildInfoSection(),
          ),

          const SizedBox(height: 32),

          // Mission Section
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _buildMissionSection(),
          ),

          const SizedBox(height: 32),

          // Features Section
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildFeaturesSection(),
          ),

          const SizedBox(height: 32),

          // Partners Section
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: _buildPartnersSection(),
          ),

          const SizedBox(height: 32),

          // Contact Section
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: _buildContactSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.water_drop,
                  size: 30,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'E-Blood Bank Makila',
                      style: GoogleFonts.ubuntu(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                    Text(
                      'Version 2.0.0',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'E-Blood Bank Makila utilise des solutions innovantes pour révolutionner le processus de don et de transfusion sanguine. Grâce à sa plateforme numérique, l\'organisation facilite la connexion entre les donneurs de sang et les hôpitaux, améliorant ainsi l\'accessibilité et la disponibilité du sang pour les patients dans le besoin.',
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notre Mission',
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sauver des vies en facilitant l\'accès au sang pour tous. Nous mettons en œuvre des campagnes de sensibilisation numériques pour éduquer le public sur l\'importance du don de sang et encourager davantage de personnes à devenir des donneurs réguliers.',
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fonctionnalités',
          style: GoogleFonts.ubuntu(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
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
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: ColorPages.COLOR_PRINCIPAL,
              size: 20,
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
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nos Partenaires',
          style: GoogleFonts.ubuntu(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Ils nous accompagnent',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.global,
            size: 40,
            color: ColorPages.COLOR_PRINCIPAL,
          ),
          const SizedBox(height: 16),
          Text(
            'Visitez notre site web',
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _launchWebsite('https://e-bloodbank.org'),
            child: Text(
              'www.e-bloodbank.org',
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                color: ColorPages.COLOR_PRINCIPAL,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pour plus d\'informations sur nos services et notre mission.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _launchWebsite(String website) async {
    final Uri url = Uri.parse(website);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
