// import 'package:eblood_bank_mak_app/apps/autres/CarouselPage.dart';
// import 'package:eblood_bank_mak_app/apps/widgets/BanqueWidget.dart';
// import 'package:eblood_bank_mak_app/commande/ui/pages/NotificationPage.dart';
// import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BanqueCtrl.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
//
// class Banquepage extends ConsumerStatefulWidget {
//   const Banquepage({super.key});
//
//   @override
//   ConsumerState createState() => _BanquepageState();
// }
//
// class _BanquepageState extends ConsumerState<Banquepage> {
//   int currentSlider = 0;
//   int selectedIndex = 0;
//
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // action initiale de la page et appel d'un controleur
//       var ctrl = ref.read(banqueCtrlProvider.notifier);
//       ctrl.listebanque();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var state = ref.watch(banqueCtrlProvider);
//
//     return Scaffold(
//       backgroundColor: ColorPages.COLOR_BLANCHE,
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         backgroundColor: ColorPages.COLOR_BLANCHE,
//         title: Image.asset(
//           'images/image4.png',
//           width: 60,
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: Stack(
//               children: [
//                 IconButton(
//                   onPressed: () {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => NotificationPage()));
//                   },
//                   icon: Icon(
//                     Icons.notifications_none,
//                     color: ColorPages.COLOR_NOIR,
//                   ),
//                 ),
//                 Positioned(
//                   right: 17,
//                   top: 15,
//                   child: Container(
//                     width: 7, // Largeur du point
//                     height: 7, // Hauteur du point
//                     decoration: BoxDecoration(
//                       color: ColorPages.COLOR_PRINCIPAL, // Couleur du point
//                       shape: BoxShape.circle, // Forme circulaire
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CarouselPage(),
//           Container(
//             margin: EdgeInsets.all(10),
//             padding: EdgeInsets.symmetric(vertical: 6, horizontal: 13),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Banques de sang",
//                     style: TextStyle(
//                         color: ColorPages.COLOR_GRIS,
//                         fontWeight: FontWeight.bold)),
//                 Text(
//                   "voir tout.",
//                   style: TextStyle(
//                       color: ColorPages.COLOR_NOIR,
//                       fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: SizedBox(
//               child: state.isLoading
//                   ? _chargement() // Affiche l'indicateur de chargement si `isLoading` est vrai
//                   : state.banques.isNotEmpty
//                       ? ListView.builder(
//                           itemCount: state.banques.length,
//                           itemBuilder: (context, page) {
//                             final banque = state.banques[page];
//                             return BanqueWidget(
//                               banque: banque,
//                               authToken: '',
//                             );
//                           },
//                         )
//                       : Center(
//                           child: _chargement() // Message pour les données vides
//                           ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /* Widget _chargement(BuildContext context){
//      var state=ref.watch(banqueCtrlProvider);
//     return Visibility(visible: state.isLoading, child: CircularProgressIndicator( valueColor:
//     AlwaysStoppedAnimation<Color>(ColorPages.COLOR_PRINCIPAL),));
//   } */
//
//   Widget _chargement() {
//     return CircularProgressIndicator(
//       valueColor: AlwaysStoppedAnimation<Color>(ColorPages.COLOR_PRINCIPAL),
//     );
//   }
// }

import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/autres/CarouselPage.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:eblood_bank_mak_app/apps/widgets/BanqueWidget.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BanqueCtrl.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/recherchePoche/RecherchePochePage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/notification/NotificationPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class Banquepage extends ConsumerStatefulWidget {
  //final List<DatumNotificationModel> notification;
  const Banquepage({super.key});

  @override
  ConsumerState createState() => _BanquepageState();
}

class _BanquepageState extends ConsumerState<Banquepage> {
  final TextEditingController searchController = TextEditingController();

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     var ctrl = ref.read(banqueCtrlProvider.notifier);
  //     ctrl.listebanque();
  //   });
  // }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBanqueList();
    });
  }

  Future<void> _fetchBanqueList() async {
    var ctrl = ref.read(banqueCtrlProvider.notifier);
    await ctrl.listebanque();
  }

  @override
  Widget build(BuildContext context) {
    var state = ref.watch(banqueCtrlProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorPages.COLOR_PRINCIPAL,
              ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
              Colors.grey.shade50,
            ],
            stops: const [0.0, 0.15, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(context),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: _buildHomeContent(context, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Top Row with Logo and Notifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo and Welcome Text
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E-Blood Bank',
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Trouvez du sang rapidement',
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Notification Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationPage(
                              notification: [],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Iconsax.notification,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Modern Search Bar
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Recherchepage(query: searchController.text),
                  ),
                );
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Icon(
                      Iconsax.search_normal,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'Rechercher une poche... ex. A+',
                        style: GoogleFonts.ubuntu(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorPages.COLOR_PRINCIPAL,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Iconsax.search_normal,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, dynamic state) {
    return RefreshIndicator(
      color: ColorPages.COLOR_PRINCIPAL,
      onRefresh: _fetchBanqueList,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel Section
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: CarouselPage(),
            ),

            const SizedBox(height: 24),

            // Section Header
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Banques de sang',
                        style: GoogleFonts.ubuntu(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Les plus proches de vous',
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // Add "voir tout" functionality if needed
                    },
                    child: Text(
                      'Voir tout',
                      style: GoogleFonts.ubuntu(
                        color: ColorPages.COLOR_PRINCIPAL,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Blood Banks List
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _buildBanksList(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanksList(dynamic state) {
    if (state.isLoading) {
      return _buildModernLoading();
    }

    if (state.banques.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.banques.length,
      itemBuilder: (context, index) {
        final banque = state.banques[index];
        return FadeInUp(
          delay: Duration(milliseconds: 600 + (index * 100)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: BanqueWidget(
              banque: banque,
              authToken: '',
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Iconsax.bank,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune banque disponible',
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tirez vers le bas pour actualiser',
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: AppSpinner.bloodDrop(
          size: 80,
          showMessage: true,
          message: 'Chargement des banques de sang...',
        ),
      ),
    );
  }
}
