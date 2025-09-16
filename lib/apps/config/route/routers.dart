// import 'package:eblood_bank_mak_app/apps/demarrage/SplashPage.dart';
// import 'package:eblood_bank_mak_app/apps/widgets/BottomNavBarWidget.dart';
// import 'package:eblood_bank_mak_app/apps/widgets/DetailsPocheBanqueWidget.dart';
// import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BanquePage.dart';
// import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/favoris/FavorisCtrl.dart';
// import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/favoris/FavorisPage.dart';
// import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/localisationBanque/LocalisationBanquePage.dart';
// import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/poche/ListePocheBanquePage.dart';
// import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/recherchePoche/RecherchePochePage.dart';
// import 'package:eblood_bank_mak_app/paiement/ui/pages/DetailCommandePage.dart';
// import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/UtilisateurInteractor.dart';
// import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/authentification/AuthentificationPage.dart';
// import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/changerPassword/ChangerPasswordPage.dart';
// import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/motdepasse/ModifierPasswordPage.dart';
// import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/motdepasse/OtpCodePasswordPage.dart';
// import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/motdepasse/ReinitialiserMotDePassePage.dart';
// import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/otp_code/OtpCodePage.dart';
// import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/ProfilePage.dart';
// import 'package:flutter/material.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
// import 'package:go_router/go_router.dart';
//
// import '../../../gestionStocks/business/model/banque/BanqueModele.dart';
// import '../../../gestionStocks/business/model/poche/PocheModel.dart';
//
// part "routers.g.dart";
//
// enum Urls {
//   banquepage,
//   authentificationpage,
//   authentification,
//   otpcodepage,
//   reinitialisermotdepassepage,
//   profilpage,
//   otpcodepasswordpage,
//   modifierpasswordpage,
//   changerpasswordpage,
//   detailcommandepage,
//   favorispage,
//   localisationbanquepage,
//   listepochebanquepage,
//   detailpochebanquepage,
//   recherchepochepage,
//   panierpage,
//   commandepage,
//   notificationpage,
//   splashpage,
//   bottomnavbar
// }
//
// @Riverpod(keepAlive: true)
// GoRouter router(RouterRef ref) {
//   final userInteractor = ref.watch(utilisateurInteractorProvider);
//
//   return GoRouter(
//     debugLogDiagnostics: true,
//     initialLocation: "/home",
//     redirect: (context, state) async {
//       var usecase = userInteractor.getUserLocalCodeUseCase;
//       var res = await usecase.run();
//       if (res?.authBarear != 0 && state.matchedLocation.startsWith("/auth")) {
//         return "/home/banquepage";
//       }
//       if (res?.authBarear == 0 && state.matchedLocation.startsWith("/home")) {
//         return "/home"; // Changez cela pour correspondre au chemin
//       }
//       return null;
//     },
//     routes: <RouteBase>[
//       GoRoute(
//         path: "/home",
//         name: Urls.splashpage.name,
//         builder: (ctx, state) => SplashPage(),
//         routes: <RouteBase>[
//           GoRoute(
//             path: "banquepage",
//             name: Urls.banquepage.name,
//             builder: (ctx, state) => Banquepage(),
//           ),
//           GoRoute(
//             path: 'codeOtpAuth',
//             name: Urls.otpcodepage.name,
//             builder: (ctx, state) => OtpCodePage(),
//           ),
//           GoRoute(
//             path: 'profil',
//             name: Urls.profilpage.name,
//             builder: (ctx, state) => ProfilePage(),
//           ),
//           GoRoute(
//             path: "bottomnavbar",
//             name: Urls.bottomnavbar.name,
//             builder: (ctx, state) => BottomNavBarWidget(),
//           ),
//           // GoRoute(
//           //   path: "notification",
//           //   name: Urls.notificationpage.name,
//           //   builder: (ctx, state) => NotificationPage(),
//           // ),
//           GoRoute(
//             path: "recherche",
//             name: Urls.recherchepochepage.name,
//             builder: (ctx, state) => Recherchepage(query: ''),
//           ),
//           GoRoute(
//             path: 'Favoris',
//             name: Urls.favorispage.name,
//             pageBuilder: (context, state) {
//               final favorisModel = ref
//                   .read(favorisCtrlProvider)
//                   .favoris; // Vérifiez que c'est de type List<FavorisRecupererModel>
//               return MaterialPage(
//                   child: FavorisPage(
//                 favoris: [],
//               )); // Assurez-vous que favorisModel est le bon type
//             },
//           ),
//           GoRoute(
//             path: 'reinitialisermotdepasse',
//             name: Urls.reinitialisermotdepassepage.name,
//             builder: (ctx, state) => ReinitialiserMotDePassePage(),
//           ),
//           GoRoute(
//             path: 'otpcodepassword',
//             name: Urls.otpcodepasswordpage.name,
//             builder: (ctx, state) => OtpCodePasswordPage(),
//           ),
//           GoRoute(
//             path: 'modifierpassword',
//             name: Urls.modifierpasswordpage.name,
//             builder: (ctx, state) => ModifierPasswordPage(),
//           ),
//           GoRoute(
//             path: 'changerpassword',
//             name: Urls.changerpasswordpage.name,
//             builder: (ctx, state) => ChangerPasswordPage(),
//           ),
//           GoRoute(
//             path: 'paiement',
//             name: Urls.detailcommandepage.name,
//             builder: (ctx, state) => DetailCommandePage(),
//           ),
//           GoRoute(
//             path: 'localisationbanque',
//             name: Urls.localisationbanquepage.name,
//             builder: (ctx, state) => LocalisationBanquePage(bloodBanks: []),
//           ),
//           GoRoute(
//             path: 'listepochebanque',
//             name: Urls.listepochebanquepage.name,
//             pageBuilder: (context, state) {
//               final banque = state.extra as BanqueModele;
//               return MaterialPage(
//                 child: ListePocheBanquePage(
//                     banqueId: banque.id,
//                     banqueNom: banque.blood_bank_name,
//                     banque: banque),
//               );
//             },
//           ),
//           GoRoute(
//             path: 'detailpochebanque',
//             name: Urls.detailpochebanquepage.name,
//             pageBuilder: (context, state) {
//               final poche = state.extra as PocheModel;
//               final banque = state.extra as BanqueModele;
//               final banqueNom = poche.bloodBagInfo.bloodTypeInfo.bloodTypeName;
//               return MaterialPage(
//                 child: DetailPocheBanqueWidget(
//                   poche: poche,
//                   banqueNom: banqueNom,
//                   banque: banque,
//                 ),
//               );
//             },
//           )
//         ],
//       ),
//       GoRoute(
//         path: '/auth', // Chemin principal pour l'authentification
//         name: Urls.authentification.name,
//         builder: (ctx, state) => AuthentificationPage(),
//         routes: <RouteBase>[
//           GoRoute(
//             path: 'authentificationpage',
//             // Chemin spécifique pour l'authentification
//             name: Urls.authentificationpage.name,
//             builder: (ctx, state) => AuthentificationPage(),
//           ),
//         ],
//       ),
//     ],
//     errorBuilder: (ctx, state) => AuthentificationPage(),
//   );
// }
