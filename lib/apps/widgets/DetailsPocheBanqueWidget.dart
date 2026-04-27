// import 'package:eblood_bank_mak_app/orders/ui/pages/panier/PanierCtrl.dart';
// import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
// import 'package:eblood_bank_mak_app/stock_management/business/model/poche/PocheModel.dart';
// import 'package:eblood_bank_mak_app/orders/ui/pages/panier/PanierPage.dart';
// import '../../orders/business/interactor/CommandeInteractor.dart';
// import '../../orders/business/model/CartItemPanierModel.dart';
//
// class DetailPocheBanqueWidget extends ConsumerStatefulWidget {
//   final PocheModel poche; // Modèle de poche à afficher
//   final String banqueNom;
//   final BanqueModele banque;
//
//   //final CartItemPanierModel poches; // Modèle de l'élément
//
//   DetailPocheBanqueWidget({
//     required this.poche,
//     required this.banqueNom,
//     required this.banque,
//     // required this.poches
//   });
//
//   @override
//   _DetailPocheBanqueWidgetState createState() =>
//       _DetailPocheBanqueWidgetState();
// }
//
// class _DetailPocheBanqueWidgetState
//     extends ConsumerState<DetailPocheBanqueWidget> {
//   int _quantity = 1; // Quantité initiale
//   int get _totalPrice => _quantity * widget.poche.price;
//   bool _isAnimating = false;
//
//   @override
//   Widget build(BuildContext context) {
//     var state = ref.watch(panierCtrlProvider);
//
//     return Scaffold(
//       backgroundColor: ColorPages.COLOR_BLANCHE,
//       appBar: AppBar(
//         backgroundColor: ColorPages.COLOR_BLANCHE,
//         title: Text(
//           widget.banqueNom,
//           style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
//         ),
//         actions: [],
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(0.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Image.asset(
//                           "images/poche.jfif",
//                           fit: BoxFit.cover,
//                           height: 210,
//                         ),
//                       ),
//                       const SizedBox(width: 16.0),
//                     ],
//                   ),
//                   SizedBox(height: 8),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(height: 25),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "Poche ${widget.poche.bloodBagInfo.bloodTypeInfo.bloodTypeName} ${widget.poche.bloodBagInfo.bloodRhesusInfo.bloodRheususName}",
//                             style: TextStyle(
//                               color: ColorPages.COLOR_NOIR,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 20,
//                             ),
//                           ),
//                           Column(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               Text(
//                                 "${widget.poche.bloodBagInfo.bloodVolumeInfo.bloodVolumeName} ${widget.poche.bloodBagInfo.bloodVolumeInfo.bloodVolumeUnityInfo.bloodVolumeUnityName}",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 13.0,
//                                   color: ColorPages.COLOR_GRIS,
//                                 ),
//                               ),
//                               SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   Text(
//                                     "${widget.poche.bloodStockCount} poches",
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 15.0,
//                                       color: ColorPages.COLOR_PRINCIPAL,
//                                     ),
//                                   ),
//                                   Text(
//                                     " en stock",
//                                     style: TextStyle(
//                                         color: ColorPages.COLOR_NOIR,
//                                         fontWeight: FontWeight.bold),
//                                   )
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 10),
//                     ],
//                   ),
//                   SizedBox(
//                     height: 20,
//                   ),
//                   Container(
//                     child: Text(
//                       "Description",
//                       style:
//                           TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//                     ),
//                   ),
//                   SizedBox(
//                     height: 10,
//                   ),
//                   Center(
//                     child: Text(
//                       'Le groupe sanguin A+ possède l\'antigène A et le facteur Rhésus positif (Rh+). Les personnes avec ce groupe sanguin peuvent recevoir du sang des groupes A+ et O+, et sont donneurs pour les groupes A+ et AB+.',
//                       style: TextStyle(color: Colors.grey[700]),
//                     ),
//                   ),
//                   SizedBox(height: 50),
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
//                             onPressed: () {
//                               setState(() {
//                                 if (_quantity > 1) {
//                                   _quantity--;
//                                 }
//                               });
//                             },
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
//                       Text("$_quantity",
//                           style: TextStyle(
//                               fontSize: 17, fontWeight: FontWeight.bold)),
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
//                             onPressed: () {
//                               setState(() {
//                                 if (_quantity < widget.poche.bloodStockCount) {
//                                   _quantity++;
//                                 }
//                               });
//                             },
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
//                       Spacer(),
//                       Text('\$ ${_totalPrice.toStringAsFixed(2)}',
//                           style: TextStyle(
//                               fontSize: 20, fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//
//                 ],
//               ),
//             ),
//             // Spacer(),
//             // ElevatedButton(onPressed: () {}, child: Text("Ajouter au panier"))
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomAppBar(
//         color: ColorPages.COLOR_BLANCHE,
//         elevation: 20,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: <Widget>[
//             Container(
//               color: ColorPages.COLOR_BLANCHE,
//               child: Column(
//                 children: [
//                   Stack(
//                     children: [
//                       IconButton(
//                         icon: Icon(
//                           Icons.shopping_cart_outlined,
//                           size: 30,
//                           color: ColorPages.COLOR_NOIR,
//                         ),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => PanierPage()),
//                           );
//                         },
//                       ),
//                       Positioned(
//                         top: 10,
//                         right: 15,
//                         child: Badge(
//                           label: Text(
//                             "${state.paniers?.data.isNotEmpty == true ? state.paniers!.data[0].cartItems.length : 0}",
//                             style: TextStyle(color: ColorPages.COLOR_BLANCHE),
//                           ),
//                           child: SizedBox(),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 height: 55,
//                 decoration: BoxDecoration(
//                   color: ColorPages.COLOR_NOIR,
//                   border: Border.all(
//                     color: ColorPages.COLOR_NOIR,
//                     width: 2.0,
//                   ),
//                 ),
//                 child: ElevatedButton(
//                   onPressed: () {
//                     final usecase =
//                         ref.read(commandeInteractorProvider).panierusecase;
//                     usecase.run(widget.poche, widget.banque,
//                         quantity: _quantity);
//                   },
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'AJOUTER AU \n PANIER',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(color: ColorPages.COLOR_BLANCHE),
//                       ),
//                     ],
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: ColorPages.COLOR_NOIR,
//                     elevation: 0,
//                     side: BorderSide(
//                       color: ColorPages.COLOR_NOIR,
//                       // Couleur du bord
//                       width: 2.0, // Épaisseur du bord
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 height: 55,
//                 child: AnimatedContainer(
//                   duration: Duration(milliseconds: 300),
//                   decoration: BoxDecoration(
//                     color: ColorPages.COLOR_PRINCIPAL,
//                     border: Border.all(
//                       color: ColorPages.COLOR_PRINCIPAL,
//                       width: 2.0,
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'ACHETER \n MAINTENANT',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(color: ColorPages.COLOR_BLANCHE),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:eblood_bank_mak_app/orders/ui/pages/panier/PanierCtrl.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/poche/PocheModel.dart';
import 'package:eblood_bank_mak_app/orders/ui/pages/panier/PanierPage.dart';
import '../../orders/business/interactor/CommandeInteractor.dart';
import '../../orders/ui/pages/checkout/pages/DetailCommandePage.dart';

class DetailPocheBanqueWidget extends ConsumerStatefulWidget {
  final PocheModel poche; // Modèle de poche à afficher
  final String banqueNom;
  final BanqueModele banque;

  DetailPocheBanqueWidget({
    required this.poche,
    required this.banqueNom,
    required this.banque,
  });

  @override
  _DetailPocheBanqueWidgetState createState() =>
      _DetailPocheBanqueWidgetState();
}

class _DetailPocheBanqueWidgetState
    extends ConsumerState<DetailPocheBanqueWidget> {
  int _quantity = 1; // Quantité initiale
  int get _totalPrice => _quantity * widget.poche.price;
  bool _isLoading = false; // Variable de chargement

  @override
  Widget build(BuildContext context) {
    var state = ref.watch(panierCtrlProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorPages.COLOR_PRINCIPAL),
        title: Text(
          widget.banqueNom,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ColorPages.COLOR_PRINCIPAL),
        ),
        flexibleSpace: Container(
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
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Stack(
          children: [
            _body(context),
            if (_isLoading) _chargement(context), // Afficher le chargement
          ],
        ),
      ),
      bottomNavigationBar: _buildModernBottomBar(context, state),
    );
  }

  Widget _body(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.asset(
                        "assets/images/poche.jfif",
                        fit: BoxFit.cover,
                        height: 150,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                  ],
                ),
                SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Poche ${widget.poche.bloodBagInfo.bloodTypeInfo.bloodTypeName} ${widget.poche.bloodBagInfo.bloodRhesusInfo.bloodRheususName}",
                          style: TextStyle(
                            color: ColorPages.COLOR_NOIR,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${widget.poche.bloodBagInfo.bloodVolumeInfo.bloodVolumeName} ${widget.poche.bloodBagInfo.bloodVolumeInfo.bloodVolumeUnityInfo.bloodVolumeUnityName}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.0,
                                color: ColorPages.COLOR_GRIS,
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  "${widget.poche.bloodStockCount} poches",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                    color: ColorPages.COLOR_PRINCIPAL,
                                  ),
                                ),
                                Text(
                                  " en stock",
                                  style: TextStyle(
                                      color: ColorPages.COLOR_NOIR,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  child: Text(
                    "Description",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    widget.poche.description ?? 'Aucune description disponible.',
                    style: TextStyle(color: Colors.grey[700]),
                    textAlign: TextAlign.justify,
                  ),
                ),
                SizedBox(height: 30),
                _buildModernQuantitySelector(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showCustomSnackBar(String message, IconData icon) {
    final snackBar = SnackBar(
      content: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: ColorPages.COLOR_PRINCIPAL,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white), // Utiliser l'icône dynamique
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildModernQuantitySelector() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Quantity Label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantité',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.poche.bloodStockCount} en stock',
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Decrease Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_quantity > 1) {
                          _quantity--;
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _quantity > 1
                            ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Icon(
                        Iconsax.minus,
                        size: 18,
                        color: _quantity > 1
                            ? ColorPages.COLOR_PRINCIPAL
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),

                  // Quantity Display
                  Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.symmetric(
                        vertical: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$_quantity',
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  // Increase Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_quantity < widget.poche.bloodStockCount) {
                          _quantity++;
                        } else if (_quantity == widget.poche.bloodStockCount) {
                          showCustomSnackBar('Stock atteint', Icons.warning);
                        } else {
                          showCustomSnackBar('Poche insuffisant en stock', Icons.error);
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _quantity < widget.poche.bloodStockCount
                            ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Icon(
                        Iconsax.add,
                        size: 18,
                        color: _quantity < widget.poche.bloodStockCount
                            ? ColorPages.COLOR_PRINCIPAL
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // Total Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(widget.poche.currencySymbol ?? '\$').toUpperCase()}${_totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chargement(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20), // Ajout de padding
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(ColorPages.COLOR_PRINCIPAL),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBottomBar(BuildContext context, dynamic state) {
    final cartItemCount = state.paniers?.data.isNotEmpty == true
        ? state.paniers!.data[0].cartItems.length
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price and Quantity Summary
              _buildPriceSummary(),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  // Cart Button
                  _buildCartButton(cartItemCount),

                  const SizedBox(width: 16),

                  // Add to Cart Button
                  Expanded(
                    child: _buildAddToCartButton(),
                  ),

                  const SizedBox(width: 12),

                  // Buy Now Button
                  Expanded(
                    child: _buildBuyNowButton(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Blood Type Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Iconsax.health,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Poche ${widget.poche.bloodBagInfo.bloodTypeInfo.bloodTypeName}',
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Quantité: $_quantity × ${(widget.poche.currencySymbol ?? '\$').toUpperCase()}${widget.poche.price}',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Total Price
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(widget.poche.currencySymbol ?? '\$').toUpperCase()}${_totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton(int cartItemCount) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PanierPage()),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Iconsax.shopping_cart,
                  color: Colors.grey.shade700,
                  size: 24,
                ),
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$cartItemCount',
                        style: GoogleFonts.ubuntu(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : () async {
            // Check stock
            if (widget.poche.bloodStockCount < 1) {
              showCustomSnackBar(
                'Stock insuffisant pour passer une commande',
                Icons.warning,
              );
              return;
            }

            // Check if quantity exceeds stock
            if (_quantity > widget.poche.bloodStockCount) {
              showCustomSnackBar(
                'Quantité demandée supérieure au stock disponible',
                Icons.warning,
              );
              return;
            }

            setState(() {
              _isLoading = true;
            });

            try {
              final usecase = ref.read(commandeInteractorProvider).panierusecase;
              await usecase.run(widget.poche, widget.banque, quantity: _quantity);

              // Refresh cart count
              final panierCtrl = ref.read(panierCtrlProvider.notifier);
              await panierCtrl.listepanier();

              // Show success modal
              if (mounted) {
                _showSuccessModal();
              }
            } catch (e) {
              showCustomSnackBar('Erreur lors de l\'ajout au panier', Icons.error);
            } finally {
              setState(() {
                _isLoading = false;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.shopping_cart,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ajouter au panier',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showSuccessModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),

            // Success message
            Text(
              'Ajouté au panier !',
              style: GoogleFonts.ubuntu(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              '$_quantity poche(s) ajoutée(s) à votre panier',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continuer',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PanierPage(showBack: true,),
                        ),
                      );
                    }, 
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: ColorPages.COLOR_PRINCIPAL,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Voir le panier',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
  }

  Widget _buildBuyNowButton() {
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : () async {
            // Check stock
            if (widget.poche.bloodStockCount < 1) {
              showCustomSnackBar(
                'Stock insuffisant pour passer une commande',
                Icons.warning,
              );
              return;
            }

            setState(() {
              _isLoading = true;
            });

            try {
              // 1. Add to cart first
              final usecase = ref.read(commandeInteractorProvider).panierusecase;
              await usecase.run(widget.poche, widget.banque, quantity: _quantity);

              // 2. Get the updated cart
              final panierCtrl = ref.read(panierCtrlProvider.notifier);
              await panierCtrl.listepanier();

              final panierState = ref.read(panierCtrlProvider);

              if (panierState.paniers?.data.isNotEmpty == true) {
                // 3. Navigate directly to payment page
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailCommandePage(
                        paiement: panierState.paniers!.data[0],
                      ),
                    ),
                  );
                }
              } else {
                showCustomSnackBar(
                  'Erreur lors de la récupération du panier',
                  Icons.error,
                );
              }
            } catch (e) {
              debugPrint("💥 Buy now error: $e");
              showCustomSnackBar(
                'Erreur lors de l\'achat immédiat',
                Icons.error,
              );
            } finally {
              setState(() {
                _isLoading = false;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPages.COLOR_PRINCIPAL,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? AppSpinner.ring(size: 20, showMessage: false)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.flash_1,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Acheter',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
