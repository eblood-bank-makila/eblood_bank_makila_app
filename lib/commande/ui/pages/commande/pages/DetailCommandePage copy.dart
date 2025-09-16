// import 'dart:math';
// import 'package:binoxuspay/model/binoxuspay_response.dart';
// import 'package:confetti/confetti.dart';
// import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
// import 'package:eblood_bank_mak_app/commande/business/model/DatumPanierModel.dart';
// import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierPageState.dart';
// import 'package:eblood_bank_mak_app/paiement/ui/pages/PaiementCtrl.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/src/widgets/framework.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../../../apps/config/utils/DottedDivider.dart';
// import '../../../../../apps/widgets/DetailCommandeWidget.dart';
// import '../../../../../paiement/ui/pages/message/MessagePaiementEchouer.dart';
// import '../../../../../paiement/ui/pages/message/MessagePaiementReussiPage.dart';
// import '../../panier/PanierCtrl.dart';
// import 'package:binoxuspay/binoxuspay.dart';

// class DetailCommandePage extends ConsumerStatefulWidget {
//   DatumModel paiement;

//   DetailCommandePage({required this.paiement});

//   @override
//   ConsumerState createState() => _DetailCommandePageState();
// }

// class _DetailCommandePageState extends ConsumerState<DetailCommandePage> {
//   bool _isAnimating = false;
//   List<Widget> _listOfPages = [];
//   bool _isLoading = false;

//   Path drawStar(Size size) {
//     // Method to convert degree to radians
//     double degToRad(double deg) => deg * (pi / 180.0);

//     const numberOfPoints = 5;
//     final halfWidth = size.width / 2;
//     final externalRadius = halfWidth;
//     final internalRadius = halfWidth / 2.5;
//     final degreesPerStep = degToRad(360 / numberOfPoints);
//     final halfDegreesPerStep = degreesPerStep / 2;
//     final path = Path();
//     final fullAngle = degToRad(360);
//     path.moveTo(size.width, halfWidth);

//     for (double step = 0; step < fullAngle; step += degreesPerStep) {
//       path.lineTo(halfWidth + externalRadius * cos(step),
//           halfWidth + externalRadius * sin(step));
//       path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
//           halfWidth + internalRadius * sin(step + halfDegreesPerStep));
//     }
//     path.close();
//     return path;
//   }

//   final _pageController = PageController();

//   late ConfettiController _confettiController;

//   @override
//   void initState() {
//     _confettiController =
//         ConfettiController(duration: const Duration(seconds: 10));
//     super.initState();
//   }

//   onPaymentResult(
//       {required int page,
//       required String title,
//       required String message,
//       required bool paymentSucceed}) {
//     Navigator.pop(context);

//     Future.delayed(const Duration(milliseconds: 700), () {
//       apiResponseMessageTitle = title;
//       apiResponseMessage = message;
//       setState(() {});
//       _pageController.jumpToPage(page);
//       if (paymentSucceed) {
//         _confettiController.play();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _confettiController.dispose();
//     super.dispose();
//   }

//   String apiResponseMessageTitle = '';

//   String apiResponseMessage = '';

//   @override
//   Widget build(BuildContext context) {
//     var state = ref.watch(panierCtrlProvider);

//     _listOfPages = [
//       _verification(state),
//       Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           Container(
//             padding: const EdgeInsets.only(
//               top: 10.0,
//               bottom: 10.0,
//             ),
//             margin:
//                 const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
//             decoration: const BoxDecoration(
//               borderRadius: BorderRadius.all(Radius.circular(10.0)),
//               color: CupertinoColors.extraLightBackgroundGray,
//             ),
//             child: OpsErrorScreen(
//               can_show_go_back_btn: true,
//               hidde_all_btn: false,
//               goBack: () {
//                 _pageController.jumpToPage(
//                   0,
//                 );
//               },
//               message: apiResponseMessage,
//               title: apiResponseMessageTitle,
//               onClosing: () {
//                 Navigator.pop(context);
//               },
//             ),
//           ),
//         ],
//       ),
//       Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           ConfettiWidget(
//             confettiController: _confettiController,
//             blastDirectionality: BlastDirectionality.explosive,
//             // don't specify a direction, blast randomly
//             shouldLoop: false,
//             // start again as soon as the animation is finished
//             // manually specify the colors to be used
//             createParticlePath: drawStar, // define a custom shape/path.
//           ),
//           Container(
//             padding: const EdgeInsets.only(
//               top: 10.0,
//               bottom: 10.0,
//             ),
//             margin:
//                 const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
//             decoration: const BoxDecoration(
//               borderRadius: BorderRadius.all(Radius.circular(10.0)),
//               color: CupertinoColors.extraLightBackgroundGray,
//             ),
//             child: OpsSuccessScreen(
//               message: apiResponseMessage,
//               hidde_all_btn: false,
//               title: apiResponseMessageTitle,
//               onClosing: () {
//                 Navigator.pop(context);
//               },
//             ),
//           ),
//         ],
//       ),
//     ];
//     return Scaffold(
//         backgroundColor: ColorPages.COLOR_BLANCHE,
//         appBar: AppBar(
//           backgroundColor: ColorPages.COLOR_BLANCHE,
//           title: const Center(
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.verified_outlined,
//                   color: Colors.green,
//                 ),
//                 SizedBox(
//                   width: 10,
//                 ),
//                 Text(
//                   "Vérifier",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         body: Stack(
//           children: [
//             _body(context),
//             if (_isLoading) _chargement(context), // Afficher le chargement
//           ],
//         ));
//   }

//   Widget _body(BuildContext context) {
//     return PageView.builder(
//       controller: _pageController,
//       scrollDirection: Axis.horizontal,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: _listOfPages.length,
//       itemBuilder: (context, index) {
//         return _listOfPages[index];
//       },
//     );
//   }

//   Widget _verification(PanierPageState state) {
//     return Column(children: [
//       Expanded(
//         child: Container(
//           child: state.paniers?.data.isNotEmpty == true
//               ? ListView.builder(
//                   itemCount: state.paniers!.data[0].cartItems.length,
//                   itemBuilder: (context, index) {
//                     final paniers = state.paniers!.data[0];
//                     return DetailCommandeWidget(
//                       paniers: paniers,
//                       index: index,
//                     );
//                   },
//                 )
//               : const Center(child: Text("Aucun article dans le panier.")),
//         ),
//       ),
//       const SizedBox(
//         height: 15,
//       ),
//       Card(
//         color: ColorPages.COLOR_BLANCHE,
//         elevation: 1,
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 15),
//                   child: const Text(
//                     "Prix Total des poches",
//                     style: TextStyle(fontStyle: FontStyle.italic),
//                   ),
//                 ),
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 15),
//                   child: Text(
//                       "\$ ${state.paniers?.data.isNotEmpty == true ? state.paniers!.data[0].totalPrice : 0}"),
//                 ),
//               ],
//             ),
//             const SizedBox(
//               height: 15,
//             ),
//             const DottedDivider(),
//             const SizedBox(
//               height: 15,
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 15),
//                   child: const Text(
//                     "Total",
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 15),
//                   child: Text(
//                       "\$ ${state.paniers?.data.isNotEmpty == true ? state.paniers!.data[0].totalPrice : 0}",
//                       style: const TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//               ],
//             ),
//             const SizedBox(
//               height: 20,
//             )
//           ],
//         ),
//       ),
//       const Spacer(),
//       Container(
//           height: 40,
//           padding: EdgeInsets.zero,
//           //margin: EdgeInsets.all(20),
//           child: Center(
//               child:
//                   Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//             Expanded(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 10),
//                     color: ColorPages.COLOR_BLANCHE,
//                     child: Row(
//                       children: [
//                         const Text(
//                           "Total : ",
//                           style: TextStyle(
//                               color: ColorPages.COLOR_GRIS,
//                               fontStyle: FontStyle.italic),
//                         ),
//                         const SizedBox(
//                           width: 15,
//                         ),
//                         Text(
//                           "\$ ${state.paniers?.data.isNotEmpty == true ? state.paniers!.data[0].totalPrice : 0}",
//                           style: const TextStyle(
//                               color: ColorPages.COLOR_NOIR,
//                               fontSize: 17,
//                               fontWeight: FontWeight.bold),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     width: 180,
//                     child: ElevatedButton(
//                       onPressed: () async {
//                         // setState(() {
//                         //   _isAnimating = true;
//                         // });
//                         //
//                         // Future.delayed(Duration(milliseconds: 300), () {
//                         //   final usecase = ref.read(paiementInteractorProvider).ajouterPochePaiementUseCase;
//                         //   usecase.run(widget.paiement,);
//                         //
//                         //   // Réinitialiser l'animation
//                         //   setState(() {
//                         //     _isAnimating = false;
//                         //   });
//                         // });
//                         setState(() {
//                           _isLoading = true; // Démarrer le chargement
//                         });
//                         var ctrl = ref.read(paiementCtrlProvider.notifier);
//                         var resultat =
//                             await ctrl.ajouterPaiment(widget.paiement);
//                         debugPrint("resultatbbbbbbbbbbbbbbb $resultat");
//                         setState(() {
//                           _isLoading = false; // Démarrer le chargement
//                         });
//                         if (resultat?.success == true) {
//                           // CONFIG
//                           var configs = IBinoxusPayConfigs(
//                             token: 'ONE_TIME_TOKEN',
//                           );
//                           var paymentBody = IBinoxusPaymentBody(
//                             systemRef: resultat!.data?.systemRef ?? '',
//                           );
//                           Navigator.of(context).push(
//                               // OUVRIR LA PAGE DE PAIEMENT
//                               MaterialPageRoute(
//                             builder: (context) => BinoxusPayCheckout(
//                               title: "Paiement",
//                               titleBackgroundColor: ColorPages.COLOR_PRINCIPAL,
//                               titleStyle: const TextStyle(
//                                   color: ColorPages.COLOR_BLANCHE),
//                               configs: configs,
//                               paymentBody: paymentBody,
//                               onResponse: (value) {
//                                 debugPrint("onResponse : $value");
//                                 if (value.binStatus ==
//                                     EApiResponseStatusCode.bIN000) {
//                                   // CHECK PAYMENT STATUS
//                                   if (value.paymentStatus ==
//                                       IPaymentStatus.approved) {
//                                     // PAYMENT SUCCEED
//                                     onPaymentResult(
//                                       message: value.message,
//                                       title: value.title,
//                                       page: 2,
//                                       paymentSucceed: true,
//                                     );
//                                   } else {
//                                     // PAYMENT FAILS
//                                     onPaymentResult(
//                                       message: value.message,
//                                       title: value.title,
//                                       page: 1,
//                                       paymentSucceed: false,
//                                     );
//                                   }
//                                 } else {
//                                   // PAYMENT FAILS
//                                   onPaymentResult(
//                                     message: value.message,
//                                     title: value.title,
//                                     page: 1,
//                                     paymentSucceed: false,
//                                   );
//                                 }
//                                 setState(() {
//                                   _isLoading = false; // Arrêter le chargement
//                                 });
//                               },
//                               onError: (value) {
//                                 debugPrint("onError : $value");
//                                 // PAYMENT FAILS
//                                 onPaymentResult(
//                                   message: value.message,
//                                   title: value.title,
//                                   page: 1,
//                                   paymentSucceed: false,
//                                 );
//                               },
//                             ),
//                           ));
//                         } else {
//                           setState(() {
//                             _isLoading =
//                                 false; // Arrêter le chargement en cas d'échec
//                           });
//                         }
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: ColorPages.COLOR_PRINCIPAL,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(0),
//                         ),
//                       ),
//                       child: const Text(
//                         'COMMANDER',
//                         style: TextStyle(color: ColorPages.COLOR_BLANCHE),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ])))
//     ]);
//   }

//   Widget _chargement(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20), // Ajout de padding
//       child: const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               valueColor:
//                   AlwaysStoppedAnimation<Color>(ColorPages.COLOR_PRINCIPAL),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
