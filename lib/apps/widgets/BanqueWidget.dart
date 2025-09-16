
import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/config/utils/Utils.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/FavorisModel.dart';
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
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  banque.blood_bank_logo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (BuildContext context,
                                      Object error, StackTrace? stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.local_hospital,
                                        color: ColorPages.COLOR_PRINCIPAL,
                                        size: 28,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Bank name
                                  Text(
                                    banque.blood_bank_name.capitalizeFirstLetter(),
                                    style: GoogleFonts.ubuntu(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6.0),
              
                                  // Location with icon
                                  Row(
                                    children: [
                                      Icon(
                                        Iconsax.location,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          banque.townInfo.townName.capitalizeFirstLetter(),
                                          style: GoogleFonts.ubuntu(
                                            fontSize: 13.0,
                                            color: Colors.grey.shade600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
              
                                  const SizedBox(height: 8.0),
              
                                  // Distance and favorite row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Distance badge
                                      if (banque.distance != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getDistanceColor(banque.distance!).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getDistanceColor(banque.distance!).withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Iconsax.routing,
                                                size: 12,
                                                color: _getDistanceColor(banque.distance!),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                banque.distance!,
                                                style: GoogleFonts.ubuntu(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getDistanceColor(banque.distance!),
                                                ),
                                              ),
                                            ],
                                          ),
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
                                ],
                              ),
                            ),
                            // Expanded(
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       Text(
                            //         banque.blood_bank_name
                            //             .capitalizeFirstLetter(),
                            //         style: TextStyle(
                            //           fontWeight: FontWeight.bold,
                            //           fontSize: 13.0,
                            //         ),
                            //       ),
                            //       SizedBox(height: 4.0),
                            //       Row(
                            //         children: [
                            //           Expanded(
                            //             child: Text(
                            //               banque.townInfo.townName
                            //                   .capitalizeFirstLetter(),
                            //               style: TextStyle(
                            //                 fontSize: 12.0,
                            //                 color: Colors.grey,
                            //               ),
                            //               overflow: TextOverflow.ellipsis,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ],
                            //   ),
                            // ),
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
      if (!banque.isFavorite) {
        // Add to favorites
        await ref.read(favorisCtrlProvider.notifier).ajouterFavoris(
            "", FavorisModele(blood_bank_id: banque.id));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${banque.blood_bank_name} ajouté aux favoris'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Remove from favorites
        await ref.read(favorisCtrlProvider.notifier).supprimerFavoris(
            FavorisModele(blood_bank_id: banque.id));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${banque.blood_bank_name} retiré des favoris'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Toggle the provider state
      ref.read(favoriteProvider(banque.id).notifier).toggleFavorite();

    } catch (e) {
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
