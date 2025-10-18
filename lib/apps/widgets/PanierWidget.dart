// import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
// import 'package:eblood_bank_mak_app/apps/config/utils/Utils.dart';
// import 'package:eblood_bank_mak_app/commande/business/model/DatumPanierModel.dart';
// import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierCtrl.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_svg/flutter_svg.dart';
//

import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/config/utils/Utils.dart';
import 'package:eblood_bank_mak_app/commande/business/model/DatumPanierModel.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierCtrl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../commande/business/model/CartItemPanierModel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';

class PanierWidget extends ConsumerStatefulWidget {
  final DatumModel paniers;
  final int index;
  final VoidCallback? onQuantityChanged;

  // final BanqueModele banque;
  // final PocheModel poche;

  const PanierWidget({
    super.key,
    required this.paniers,
    required this.index,
    this.onQuantityChanged,
  });

  @override
  ConsumerState createState() => _PanierWidgetState();
}

class _PanierWidgetState extends ConsumerState<PanierWidget> {
  late int quantity;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    quantity = widget.paniers.cartItems[widget.index].quantity;
  }

  // Removed quantity controls - each blood bag is unique and cannot be incremented

  @override
  Widget build(BuildContext context) {
    if (widget.paniers.cartItems.isEmpty) {
      return Center(
        child: Text(
          "Aucun article dans le panier.",
          style: GoogleFonts.ubuntu(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    final cartItem = widget.paniers.cartItems[widget.index];

    // Debug print to check data
    print("🩸 Cart Item Debug:");
    print("  - Blood Type: ${cartItem.bloodBagInfo.bloodTypeInfo.bloodTypeName}");
    print("  - Rhesus: ${cartItem.bloodBagInfo.bloodRhesusInfo.bloodRheususName}");
    print("  - Bank Name: ${cartItem.bloodBankInfo.bloodBankName}");
    print("  - Volume: ${cartItem.bloodBagInfo.bloodVolumeInfo.bloodVolumeName}");
    print("  - Volume Unit: ${cartItem.bloodBagInfo.bloodVolumeInfo.bloodVolumeUnityInfo.bloodVolumeUnityName}");

    // Safe data extraction
    final bloodTypeName = cartItem.bloodBagInfo.bloodTypeInfo.bloodTypeName;
    final rhesusName = cartItem.bloodBagInfo.bloodRhesusInfo.bloodRheususName;
    final bloodType = '$bloodTypeName $rhesusName';

    final bankName = cartItem.bloodBankInfo.bloodBankName.capitalizeFirstLetter();

    final volumeName = cartItem.bloodBagInfo.bloodVolumeInfo.bloodVolumeName;
    final volumeUnit = cartItem.bloodBagInfo.bloodVolumeInfo.bloodVolumeUnityInfo.bloodVolumeUnityName;
    final volume = '$volumeName $volumeUnit';

    final totalPrice = quantity * cartItem.price;

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Dismissible(
        key: Key(cartItem.id),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.trash,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                'Supprimer',
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          // Show confirmation dialog
          return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      color: Colors.orange.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Confirmer',
                      style: GoogleFonts.ubuntu(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Voulez-vous vraiment supprimer cette poche du panier ?',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Supprimer',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) async {
          // Delete item from cart
          try {
            var controller = ref.read(panierCtrlProvider.notifier);
            final result = await controller.supprimer_panier(
              widget.paniers,
              cartItem,
            );

            // Show success message
            if (result?.success == true) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Iconsax.tick_circle,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Poche supprimée du panier',
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } else {
              // Show error message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Iconsax.warning_2,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Erreur lors de la suppression',
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint("❌ Error deleting item: $e");
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Iconsax.warning_2,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Erreur de connexion',
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Blood Bag Image
                _buildBloodBagImage(),

                const SizedBox(width: 16),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Blood Type and Bank Name
                      _buildProductInfo(bloodType, bankName, volume),

                      const SizedBox(height: 8),

                      // Unique Item Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.box,
                              size: 12,
                              color: ColorPages.COLOR_PRINCIPAL,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Unité unique',
                              style: GoogleFonts.ubuntu(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ColorPages.COLOR_PRINCIPAL,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Price and Delete
                _buildPriceAndActions(totalPrice, cartItem.currency),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBloodBagImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/poche.jfif',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildProductInfo(String bloodType, String bankName, String volume) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Blood Type
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            bloodType,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Bank Name
        Text(
          bankName,
          style: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),

        const SizedBox(height: 4),

        // Volume
        Text(
          volume,
          style: GoogleFonts.ubuntu(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Removed _buildQuantityControls and _buildQuantityButton - each blood bag is unique

  Widget _buildPriceAndActions(int totalPrice, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Delete Button
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.red.shade200,
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => _showModernDeleteDialog(context),
            icon: Icon(
              Iconsax.trash,
              size: 18,
              color: Colors.red.shade600,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),

        const SizedBox(height: 12),

        // Price
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$currency $totalPrice',
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
        ),
      ],
    );
  }

  void _showModernDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Iconsax.warning_2,
                    size: 30,
                    color: Colors.red.shade600,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  'Supprimer l\'article',
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  'Êtes-vous sûr de vouloir supprimer cette poche de sang de votre panier ?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Delete Button
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade600.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteCartItem();
                          },
                          child: Text(
                            'Supprimer',
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteCartItem() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var controller = ref.read(panierCtrlProvider.notifier);
      var result = await controller.supprimer_panier(
        widget.paniers,
        widget.paniers.cartItems[widget.index],
      );

      setState(() {
        _isLoading = false;
      });

      if (result?.success == true) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Iconsax.tick_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Article supprimé avec succès',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Notify parent about the change
        widget.onQuantityChanged?.call();
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Iconsax.warning_2,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Erreur: ${result?.sms ?? 'Impossible de supprimer l\'article'}',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Iconsax.warning_2,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Erreur de connexion',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
//
// class PanierWidget extends ConsumerStatefulWidget {
//   final DatumModel paniers;
//   final int index;
//
//   PanierWidget({required this.paniers, required this.index});
//
//   @override
//   ConsumerState createState() => _PanierWidgetState();
// }
//
// class _PanierWidgetState extends ConsumerState<PanierWidget> {
//   late int quantity;
//
//   @override
//   void initState() {
//     super.initState();
//     quantity = widget.paniers.cartItems[widget.index].quantity;
//   }
//
//   void increaseQuantity() {
//     setState(() {
//       quantity++;
//     });
//   }
//
//   void decreaseQuantity() {
//     if (quantity > 1) {
//       // Prevent going below 1
//       setState(() {
//         quantity--;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (widget.paniers.cartItems.isEmpty) {
//       return Center(child: Text("Aucun article dans le panier."));
//     }
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               const SizedBox(
//                 width: 50,
//                 child: AspectRatio(
//                   aspectRatio: 1 / 1,
//                   child: CircleAvatar(
//                     backgroundImage: AssetImage('images/poche.jfif'),
//                     radius: 20,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//
//               // Quantity and Name
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(left: 3),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           '${widget.paniers.cartItems[widget.index].bloodBagInfo.bloodTypeInfo.bloodTypeName} ${widget.paniers.cartItems[widget.index].bloodBagInfo.bloodRhesusInfo.bloodRheususName}',
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodyLarge
//                               ?.copyWith(
//                                   color: Colors.black,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 12),
//                         ),
//                         Text(
//                           '${widget.paniers.bloodBankInfo.bloodBankName.capitalizeFirstLetter()}',
//                           style: Theme.of(context).textTheme.bodySmall,
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 15),
//                   Row(
//                     children: [
//                       Container(
//                         width: 30.0,
//                         height: 30.0,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: ColorPages.COLOR_BLANCHE,
//                           border: Border.all(
//                             color: ColorPages.COLOR_PRINCIPAL,
//                             width: 1.0,
//                           ),
//                         ),
//                         child: Center(
//                           child: IconButton(
//                             onPressed: decreaseQuantity,
//                             icon: Icon(
//                               Icons.remove,
//                               size: 16,
//                               color: ColorPages.COLOR_PRINCIPAL,
//                             ),
//                             padding: EdgeInsets.zero,
//                             constraints: const BoxConstraints(),
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 15),
//                       Padding(
//                         padding: const EdgeInsets.all(5.0),
//                         child: Text(
//                           '$quantity',
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodyLarge
//                               ?.copyWith(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black,
//                                   fontSize: 12),
//                         ),
//                       ),
//                       SizedBox(width: 15),
//                       Container(
//                         width: 30.0,
//                         height: 30.0,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: ColorPages.COLOR_BLANCHE,
//                           border: Border.all(
//                             color: ColorPages.COLOR_PRINCIPAL,
//                             width: 1.0,
//                           ),
//                         ),
//                         child: Center(
//                           child: IconButton(
//                             onPressed: increaseQuantity,
//                             icon: Icon(
//                               Icons.add,
//                               size: 16,
//                               color: ColorPages.COLOR_PRINCIPAL,
//                             ),
//                             padding: EdgeInsets.zero,
//                             constraints: const BoxConstraints(),
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//                 ],
//               ),
//               const Spacer(),
//
//               // Price and Delete labelLarge
//               Column(
//                 children: [
//                   IconButton(
//                     constraints: const BoxConstraints(),
//                     onPressed: () => BoiteSuppression(context),
//                     icon: SvgPicture.asset(
//                       "icones/delete.svg",
//                       width: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     '\$ ${widget.paniers.cartItems[widget.index].price}',
//                     style: TextStyle(
//                         color: ColorPages.COLOR_PRINCIPAL,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 11),
//                   ),
//                   Text(
//                     "${widget.paniers.cartItems[widget.index].bloodBagInfo.bloodVolumeInfo.bloodVolumeName} ${widget.paniers.cartItems[widget.index].bloodBagInfo.bloodVolumeInfo.bloodVolumeUnityInfo.bloodVolumeUnityName}",
//                     style:
//                         TextStyle(color: ColorPages.COLOR_GRIS, fontSize: 11),
//                   ),
//                 ],
//               )
//             ],
//           ),
//           const Divider(thickness: 0.3),
//         ],
//       ),
//     );
//   }
//
//   Future<void> BoiteSuppression(BuildContext context, DatumModel cardId, CartItemPanierModel bloodBagId) async {
//     final confirmation = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(0),
//           ),
//           backgroundColor: Colors.white,
//           content: Text(
//             "Vous êtes sûr de supprimer cette poche?",
//             style: TextStyle(fontSize: 16),
//             textAlign: TextAlign.center,
//           ),
//           actions: <Widget>[
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     width: 110.0,
//                     height: 40.0,
//                     decoration: BoxDecoration(
//                       color: ColorPages.COLOR_BLANCHE,
//                       border: Border.all(
//                         color: ColorPages.COLOR_PRINCIPAL,
//                         width: 1.0,
//                       ),
//                     ),
//                     child: TextButton(
//                       onPressed: () {
//                         Navigator.pop(context, false);
//                       },
//                       child: Text(
//                         "Annuler",
//                         style: TextStyle(
//                           color: ColorPages.COLOR_PRINCIPAL,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   Container(
//                     width: 120.0,
//                     height: 40.0,
//                     color: ColorPages.COLOR_PRINCIPAL,
//                     child: TextButton(
//                       onPressed: () async {
//                 var ctrl=ref.read(panierCtrlProvider.notifier);
//                           var result = await ctrl.supprimer_panier(cardId, bloodBagId);
//                           if (result != null) {
//                             // Handle successful deletion (e.g., show a success message)
//                             Navigator.pop(context, true);
//                           } else {
//                             // Handle failure case
//                             Navigator.pop(context, false);
//                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Échec de la suppression")));
//                           }
//
//                       },
//                       child: Text(
//                         "Supprimer",
//                         style: TextStyle(
//                           color: ColorPages.COLOR_BLANCHE,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           ],
//         );
//       },
//     );
//
//     // Optionally handle the confirmation result if needed
//     if (confirmation == true) {
//       // Do something if needed after user confirms
//     }
//   }
//
//
// // Future<void> BoiteSuppression(BuildContext context) async {
//   //   final confirmation = await showDialog<bool>(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return AlertDialog(
//   //         shape: RoundedRectangleBorder(
//   //           borderRadius: BorderRadius.circular(0),
//   //         ),
//   //         backgroundColor: Colors.white,
//   //         content: Text(
//   //           "Vous êtes sûr de supprimer cette poche?",
//   //           style: TextStyle(fontSize: 16),
//   //           textAlign: TextAlign.center,
//   //         ),
//   //         actions: <Widget>[
//   //           SingleChildScrollView(
//   //             scrollDirection: Axis.horizontal,
//   //             child: Row(
//   //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //               children: [
//   //                 Container(
//   //                   width: 110.0,
//   //                   height: 40.0,
//   //                   decoration: BoxDecoration(
//   //                     color: ColorPages.COLOR_BLANCHE,
//   //                     border: Border.all(
//   //                       color: ColorPages.COLOR_PRINCIPAL,
//   //                       width: 1.0,
//   //                     ),
//   //                   ),
//   //                   child: TextButton(
//   //                     onPressed: () {
//   //                       Navigator.pop(context, false);
//   //                     },
//   //                     child: Text(
//   //                       "Annuler",
//   //                       style: TextStyle(
//   //                         color: ColorPages.COLOR_PRINCIPAL,
//   //                         fontSize: 14,
//   //                       ),
//   //                     ),
//   //                   ),
//   //                 ),
//   //                 SizedBox(width: 10),
//   //                 Container(
//   //                   width: 120.0,
//   //                   height: 40.0,
//   //                   color: ColorPages.COLOR_PRINCIPAL,
//   //                   child: TextButton(
//   //                     onPressed: () async {
//   //
//   //                     },
//   //                     child: Text(
//   //                       "Supprimer",
//   //                       style: TextStyle(
//   //                         color: ColorPages.COLOR_BLANCHE,
//   //                         fontSize: 14,
//   //                       ),
//   //                     ),
//   //                   ),
//   //                 ),
//   //               ],
//   //             ),
//   //           )
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }
// }
