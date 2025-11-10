import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme/ColorPages.dart';

class ConditionsGeneralesPage extends StatelessWidget {
  const ConditionsGeneralesPage({super.key});

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
          
          // Terms Icon
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
              Iconsax.document_text,
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
                  'Conditions générales',
                  style: GoogleFonts.ubuntu(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Conditions d\'utilisation',
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
              'Acceptation des conditions',
              'En utilisant l\'application E-Blood Bank, vous acceptez d\'être lié par ces conditions générales d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser notre service.',
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _buildSection(
              'Description du service',
              'E-Blood Bank est une plateforme qui facilite la recherche et la demande de poches de sang auprès des banques de sang partenaires. Nous ne stockons pas de sang et ne sommes pas une banque de sang.',
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildSection(
              'Responsabilités de l\'utilisateur',
              'En tant qu\'utilisateur, vous vous engagez à :\n\n• Fournir des informations exactes et à jour\n• Utiliser le service de manière légale et éthique\n• Ne pas partager vos identifiants de connexion\n• Respecter les droits des autres utilisateurs\n• Signaler tout problème ou abus',
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: _buildSection(
              'Disponibilité du service',
              'Nous nous efforçons de maintenir le service disponible 24h/24, 7j/7. Cependant, nous ne garantissons pas une disponibilité ininterrompue et nous réservons le droit d\'effectuer des maintenances.',
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: _buildSection(
              'Limitation de responsabilité',
              'E-Blood Bank agit comme intermédiaire entre les utilisateurs et les banques de sang. Nous ne sommes pas responsables de :\n\n• La qualité ou la disponibilité du sang\n• Les décisions médicales\n• Les retards de livraison\n• Les problèmes avec les banques de sang partenaires',
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 700),
            child: _buildSection(
              'Propriété intellectuelle',
              'Tous les contenus de l\'application (textes, images, logos, code) sont protégés par les droits d\'auteur et appartiennent à E-Blood Bank ou à ses partenaires.',
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 800),
            child: _buildSection(
              'Modification des conditions',
              'Nous nous réservons le droit de modifier ces conditions à tout moment. Les utilisateurs seront informés des changements importants par notification dans l\'application.',
            ),
          ),
          
          const SizedBox(height: 32),
          
          FadeInUp(
            delay: const Duration(milliseconds: 900),
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
                    Iconsax.message_question,
                    size: 40,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Questions sur les conditions ?',
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contactez notre équipe juridique à legal@e-bloodbank.org pour toute clarification.',
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
            delay: const Duration(milliseconds: 1000),
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
