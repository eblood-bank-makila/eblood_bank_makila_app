// import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
// import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/PocheModel.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../../commande/ui/pages/panier/PanierPage.dart';
// import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
//
// class DetaiPocheBanquePage extends ConsumerStatefulWidget {
//   const DetaiPocheBanquePage(
//       {super.key, required PocheModel poche, required BanqueModele banque });
//
//   @override
//   ConsumerState createState() => _DetailPochelBanquePageState();
// }
//
// class _DetailPochelBanquePageState extends ConsumerState<DetaiPocheBanquePage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: ColorPages.COLOR_BLANCHE,
//
//       appBar: AppBar(
//         backgroundColor: ColorPages.COLOR_BLANCHE,
//
//         title: Text(
//           'Nom Banque',
//           style: TextStyle(
//             fontSize: 19,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.shopping_cart_outlined),
//             onPressed: () {
//               Navigator.push(context,
//                   MaterialPageRoute(builder: (context) => PanierPage(poche: poche,)));
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Image.asset(
//                     "images/poche.jfif",
//                     width: 100,
//                   ),
//                 ),
//                 const SizedBox(width: 16.0),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Poche A+",
//                         style: TextStyle(
//                           color: ColorPages.COLOR_NOIR,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 17,
//                         ),
//                       ),
//                       const SizedBox(height: 8.0),
//                       Row(
//                         children: [
//                           IconButton(
//                             onPressed: () {},
//                             icon: const Icon(
//                               Icons.do_not_disturb_on_outlined,
//                               size: 30,
//                               color: ColorPages.COLOR_PRINCIPAL,
//                             ),
//                           ),
//                           Text(
//                             "1",
//                             style: TextStyle(
//                               color: ColorPages.COLOR_NOIR,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           IconButton(
//                             onPressed: () {},
//                             icon: const Icon(
//                               Icons.add_circle_outline,
//                               size: 30,
//                               color: ColorPages.COLOR_PRINCIPAL,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16.0),
//                       Text(
//                         "\$5.0",
//                         style: TextStyle(
//                           color: ColorPages.COLOR_NOIR,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 17,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24.0),
//             Text(
//               "Le groupe sanguin A+ possède l'antigène A, Le groupe sanguin A+ possède l'antigène A Le groupe sanguin A+ possède l'antigène A Le groupe sanguin A+.",
//               style: TextStyle(
//                 color: ColorPages.COLOR_NOIR,
//                 fontSize: 17,
//               ),
//             ),
//             const SizedBox(height: 24.0),
//             Center(
//               child: SizedBox(
//                 width: 300,
//                 height: 40,
//                 child: ElevatedButton(
//                   onPressed: () {},
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: ColorPages.COLOR_PRINCIPAL,
//                     elevation: 0,
//                     side: BorderSide(
//                       color: ColorPages.COLOR_PRINCIPAL,
//                       width: 2.0,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       side: BorderSide(
//                         color: ColorPages.COLOR_PRINCIPAL,
//                       ),
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(
//                         Icons.shopping_cart_outlined,
//                         color: ColorPages.COLOR_BLANCHE,
//                         size: 16,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Ajouter au panier',
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
