
import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/config/utils/Utils.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/FavorisModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BanqueCtrl.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/favoris/FavorisCtrl.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/poche/ListePocheBanquePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';

class BanqueWidget extends ConsumerWidget {
  final BanqueModele banque;
  final String authToken;

  BanqueWidget({required this.banque, required this.authToken});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No need for local variables since we use banque.isFavorite directly

    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListePocheBanquePage(
                  banqueId: banque.id, // Passer l'ID de la banque
                  banque: banque,
                  banqueNom: banque.blood_bank_name,
                  localisation: banque.townInfo.townName),
            ),
          );
        },
        child: Column(
          children: [
            Card(
              color: ColorPages.COLOR_CARD,
              elevation: .2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),

                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                    child: Stack(
                      children: [
                        // HIDDEN: Blood bank details (name, logo, location)
                        // Only show aggregated blood inventory for commercial purposes
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Generic header without bank identification
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Iconsax.health,
                                        color: ColorPages.COLOR_PRINCIPAL,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Banque de sang',
                                          style: GoogleFonts.ubuntu(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.0,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (banque.distance != null)
                                          Text(
                                            banque.distance!,
                                            style: GoogleFonts.ubuntu(
                                              fontSize: 12.0,
                                              color: _getDistanceColor(banque.distance!),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Favorite heart icon
                                GestureDetector(
                                  onTap: () => _toggleFavorite(banque, ref, context),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: banque.isFavorite
                                          ? Colors.red.shade50
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: banque.isFavorite
                                            ? Colors.red.shade200
                                            : Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      banque.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                                      size: 16,
                                      color: banque.isFavorite
                                          ? Colors.red.shade600
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Inventory Summary Section (if available)
                            if (banque.inventorySummary != null) ...[
                              const SizedBox(height: 12),
                              _buildInventorySummaryAnonymous(banque.inventorySummary!),
                            ] else ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Iconsax.info_circle,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Inventaire non disponible',
                                      style: GoogleFonts.ubuntu(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),


                        // Icône de favori
                        // Positioned(
                        //   top: 8,
                        //   right: 0,
                        //   child: CircleAvatar(
                        //     radius: 15,
                        //     backgroundColor: Colors.transparent,
                        //     child: PopupMenuButton<int>(
                        //       icon: Icon(
                        //         Icons.more_vert,
                        //         size: 16,
                        //         color: Colors.black,
                        //       ),
                        //       itemBuilder: (context) => [
                        //         PopupMenuItem<int>(
                        //           value: 1,
                        //           child: Row(
                        //             children: [
                        //               Icon(Icons.favorite,
                        //                   color: ColorPages.COLOR_PRINCIPAL),
                        //               SizedBox(width: 12),
                        //               Text('Ajouter aux favorites'),
                        //             ],
                        //           ),
                        //         ),
                        //         PopupMenuItem<int>(
                        //           value: 2,
                        //           child: Row(
                        //             children: [
                        //               Icon(Icons.favorite_border,
                        //                   color: ColorPages.COLOR_PRINCIPAL),
                        //               SizedBox(width: 12),
                        //               Text('Rétirer des favorites'),
                        //             ],
                        //           ),
                        //         ),
                        //       ],
                        //       onSelected: (value) async {
                        //         if (value == 1) {
                        //           // Logic to add to favorites
                        //           await favorisCtrl.ajouterFavoris(
                        //             authToken,
                        //             FavorisModele(blood_bank_id: banque.id),
                        //           );
                        //           ref.refresh(favorisCtrlProvider);
                        //         } else if (value == 2) {
                        //           favorisCtrl.supprimerFavoris(
                        //             FavorisModele(
                        //                 blood_bank_id: banque
                        //                     .id), // Pass the required argument
                        //           );
                        //           ref.refresh(favorisCtrlProvider);
                        //         }
                        //       },
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
            ),
            const SizedBox(
              height: 0,
            ),
          ],
        ),
      ),
    );
  }

  /// Get color based on distance for UI
  Color _getDistanceColor(String distance) {
    // Extract numeric value from distance string (e.g., "2.72 km" -> 2.72)
    final numericDistance = double.tryParse(distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (numericDistance < 1.0) {
      return Colors.green.shade600; // Very close - green
    } else if (numericDistance < 3.0) {
      return Colors.blue.shade600; // Close - blue
    } else if (numericDistance < 5.0) {
      return Colors.orange.shade600; // Medium - orange
    } else {
      return Colors.grey.shade600; // Far - grey
    }
  }

  /// Toggle favorite status for a bank
  void _toggleFavorite(BanqueModele banque, WidgetRef ref, BuildContext context) async {
    try {
      // Optimistically update the UI immediately
      final newFavoriteStatus = !banque.isFavorite;
      ref.read(banqueCtrlProvider.notifier).updateBankFavoriteStatus(
        banque.id,
        newFavoriteStatus,
      );

      // Call the toggle endpoint (it handles both add and remove)
      final result = await ref.read(favorisCtrlProvider.notifier).ajouterFavoris(
          "", FavorisModele(blood_bank_id: banque.id));

      // Get action from result
      final action = result['action'] ?? 'added';

      // Verify the action matches our optimistic update
      final expectedFavorite = action == 'added';
      if (expectedFavorite != newFavoriteStatus) {
        // If backend returned different result, correct the UI
        ref.read(banqueCtrlProvider.notifier).updateBankFavoriteStatus(
          banque.id,
          expectedFavorite,
        );
      }

      // Show appropriate message based on action
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'added'
                ? '${banque.blood_bank_name} ajouté aux favoris'
                : '${banque.blood_bank_name} retiré des favoris'),
            backgroundColor: action == 'added' ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Revert the optimistic update on error
      ref.read(banqueCtrlProvider.notifier).updateBankFavoriteStatus(
        banque.id,
        banque.isFavorite, // Revert to original state
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Build anonymous inventory summary widget (hides blood bank details)
  /// Shows only aggregated blood type availability for commercial purposes
  Widget _buildInventorySummaryAnonymous(Map<String, dynamic> inventorySummary) {
    // Extract data from inventory summary
    final totalBags = inventorySummary['total_bags'] ?? 0;
    final bloodTypes = (inventorySummary['available_blood_types'] as List?)?.cast<String>() ?? [];

    if (totalBags == 0 || bloodTypes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Iconsax.info_circle,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Aucun stock disponible',
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with total bags
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.health,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$totalBags ${totalBags == 1 ? 'poche' : 'poches'}',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'disponible${totalBags > 1 ? 's' : ''}',
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Blood types available
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bloodTypes.map((bloodType) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.shade200,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  bloodType,
                  style: GoogleFonts.ubuntu(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Exemple de provider pour gérer les favoris
final favoriteProvider =
    StateNotifierProvider.family<FavoriteNotifier, bool, String>(
        (ref, banqueId) {
  return FavoriteNotifier();
});

class FavoriteNotifier extends StateNotifier<bool> {
  FavoriteNotifier() : super(false);

  void toggleFavorite() {
    state = !state; // Basculer l'état des favoris
  }
}
