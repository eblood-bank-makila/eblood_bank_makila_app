import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/utils/Utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/favoris/DactumFavorisModel.dart';
import 'package:eblood_bank_mak_app/stock_management/ui/pages/poche/ListePocheBanquePage.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';

import '../config/theme/ColorPages.dart';

class FavorisWidget extends StatelessWidget {
  final DactumFavorisModel favoris;

  const FavorisWidget({Key? key, required this.favoris}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: GestureDetector(
        onTap: () {
          // Navigate to bank details
          _navigateToBankDetails(context);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // Bank Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  ColorPages.COLOR_PRINCIPAL,
                                  ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Iconsax.hospital,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Bank Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  favoris.bloodBankName.capitalizeFirstLetter(),
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Iconsax.location,
                                      size: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Banque de sang disponible',
                                        style: GoogleFonts.ubuntu(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Favorite Heart Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.shade100,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Iconsax.heart5,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Features Row
                      Row(
                        children: [
                          // Available Badge
                          _buildFeatureBadge(
                            icon: Iconsax.health,
                            label: 'Disponible',
                            color: Colors.green,
                          ),

                          const SizedBox(width: 12),

                          // Blood Bank Badge
                          _buildFeatureBadge(
                            icon: Iconsax.heart,
                            label: 'Banque de sang',
                            color: Colors.blue,
                          ),

                          const Spacer(),

                          // Action Button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.arrow_right_3,
                                  size: 14,
                                  color: ColorPages.COLOR_PRINCIPAL,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Voir',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 12,
                                    color: ColorPages.COLOR_PRINCIPAL,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Subtle border highlight
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.6),
                          ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBankDetails(BuildContext context) {
    // Show a snackbar for now since we don't have complete bank data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Iconsax.heart5,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${favoris.bloodBankName} - Banque favorite',
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
