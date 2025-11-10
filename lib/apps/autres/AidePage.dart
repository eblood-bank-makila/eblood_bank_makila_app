import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme/ColorPages.dart';

class AidePage extends StatelessWidget {
  const AidePage({super.key});

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
          
          // Help Icon
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
                  'Aide',
                  style: GoogleFonts.ubuntu(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Comment utiliser E-Blood Bank',
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
            child: _buildHelpSection(
              'Comment rechercher du sang ?',
              'Utilisez la barre de recherche sur la page d\'accueil pour trouver des poches de sang par groupe sanguin (ex: A+, O-, AB+). Vous pouvez également parcourir les banques de sang disponibles.',
              Iconsax.search_normal,
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _buildHelpSection(
              'Comment ajouter au panier ?',
              'Sur la page d\'une banque de sang, sélectionnez les poches dont vous avez besoin et ajoutez-les à votre panier. Vous pouvez modifier les quantités depuis votre panier.',
              Iconsax.shopping_cart,
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildHelpSection(
              'Comment passer une commande ?',
              'Depuis votre panier, vérifiez vos articles et procédez au paiement. Suivez les étapes de vérification pour finaliser votre commande.',
              Iconsax.verify,
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: _buildHelpSection(
              'Comment gérer mes favoris ?',
              'Ajoutez vos banques de sang préférées aux favoris pour un accès rapide. Retrouvez-les dans votre profil > Favoris.',
              Iconsax.heart,
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: _buildHelpSection(
              'Notifications',
              'Activez les notifications pour être informé des nouvelles disponibilités de sang et des mises à jour importantes.',
              Iconsax.notification,
            ),
          ),
          
          const SizedBox(height: 32),
          
          FadeInUp(
            delay: const Duration(milliseconds: 700),
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
                    'Besoin d\'aide supplémentaire ?',
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contactez notre équipe de support pour une assistance personnalisée.',
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
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String content, IconData icon) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
