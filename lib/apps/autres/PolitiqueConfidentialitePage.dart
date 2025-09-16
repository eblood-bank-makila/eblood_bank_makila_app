import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme/ColorPages.dart';

class PolitiqueConfidentialitePage extends StatelessWidget {
  const PolitiqueConfidentialitePage({super.key});

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
              Colors.grey.shade50,
            ],
            stops: const [0.0, 0.15, 1.0],
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
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
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
          
          // Privacy Icon
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
              Iconsax.security,
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
                  'Politique de confidentialité',
                  style: GoogleFonts.ubuntu(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Protection de vos données',
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
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildSection(
              'Introduction',
              'E-Blood Bank s\'engage à protéger votre vie privée et vos données personnelles. Cette politique de confidentialité explique comment nous collectons, utilisons et protégeons vos informations.',
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _buildSection(
              'Collecte des données',
              'Nous collectons les informations que vous nous fournissez directement, telles que :\n\n• Informations de compte (nom, email, téléphone)\n• Informations de localisation pour trouver les banques de sang\n• Historique des recherches et commandes\n• Données d\'utilisation de l\'application',
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildSection(
              'Utilisation des données',
              'Vos données sont utilisées pour :\n\n• Fournir nos services de recherche de sang\n• Améliorer l\'expérience utilisateur\n• Envoyer des notifications importantes\n• Assurer la sécurité de la plateforme\n• Respecter nos obligations légales',
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: _buildSection(
              'Protection des données',
              'Nous mettons en place des mesures de sécurité appropriées pour protéger vos données :\n\n• Chiffrement des données sensibles\n• Accès restreint aux informations\n• Surveillance continue de la sécurité\n• Mise à jour régulière des systèmes',
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: _buildSection(
              'Partage des données',
              'Nous ne vendons jamais vos données personnelles. Nous pouvons partager vos informations uniquement :\n\n• Avec les banques de sang pour traiter vos demandes\n• Avec nos partenaires de service (sous contrat strict)\n• Si requis par la loi\n• Avec votre consentement explicite',
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 700),
            child: _buildSection(
              'Vos droits',
              'Vous avez le droit de :\n\n• Accéder à vos données personnelles\n• Corriger les informations inexactes\n• Supprimer votre compte et vos données\n• Limiter le traitement de vos données\n• Recevoir une copie de vos données',
            ),
          ),
          
          const SizedBox(height: 32),
          
          FadeInUp(
            delay: const Duration(milliseconds: 800),
            child: Container(
              padding: const EdgeInsets.all(20),
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
                    Iconsax.call,
                    size: 40,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Questions sur la confidentialité ?',
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contactez-nous à privacy@e-bloodbank.org pour toute question concernant cette politique.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 900),
            child: Text(
              'Dernière mise à jour : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
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
}
