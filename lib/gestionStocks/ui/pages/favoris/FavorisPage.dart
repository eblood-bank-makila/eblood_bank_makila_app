import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:eblood_bank_mak_app/apps/widgets/FavorisWidget.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/favoris/FavorisCtrl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../commande/ui/pages/panier/PanierCtrl.dart';
import '../../../../commande/ui/pages/panier/PanierPage.dart';

class FavorisPage extends ConsumerStatefulWidget {
  const FavorisPage({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _FavorisPageState();
}

class _FavorisPageState extends ConsumerState<FavorisPage> {
  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     // action initiale de la page et appel d'un controleur
  //     var ctrl = ref.read(favorisCtrlProvider.notifier);
  //     ctrl.recupererFavoris();
  //   });
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  Future<void> _loadFavorites() async {
    var ctrl = ref.read(favorisCtrlProvider.notifier);
     ctrl.recupererFavoris();
  }


  @override
  Widget build(BuildContext context) {
    var states = ref.watch(panierCtrlProvider);

    var state = ref.watch(favorisCtrlProvider);
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
                // Enhanced Header
                _buildModernHeader(context, state, states),

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
                    child: _buildFavoritesContent(state),
                  ),
                ),
              ],
            ),
          ),
        ),



        );
  }

  Widget _buildModernHeader(BuildContext context, state, states) {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Back Button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Iconsax.arrow_left_2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Title Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes Favoris',
                    style: GoogleFonts.ubuntu(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.favoris.length} banque${state.favoris.length > 1 ? 's' : ''}',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Cart Icon
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PanierPage()),
                );
              },
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Iconsax.shopping_cart,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if ((states.paniers?.data[0].cartItems.length ?? 0) > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${states.paniers?.data[0].cartItems.length ?? 0}',
                              style: GoogleFonts.ubuntu(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesContent(state) {
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: ColorPages.COLOR_PRINCIPAL,
      child: state.isLoading
          ? _buildModernLoading()
          : state.favoris.isNotEmpty
              ? _buildFavoritesList(state)
              : _buildEmptyState(),
    );
  }

  Widget _buildModernLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: AppSpinner.heartbeat(
          size: 80,
          showMessage: true,
          message: 'Chargement de vos favoris...',
        ),
      ),
    );
  }

  Widget _buildFavoritesList(state) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.favoris.length,
        itemBuilder: (context, index) {
          if (index >= state.favoris.length) {
            return const SizedBox.shrink();
          }
          final favoris = state.favoris[index];
          return FadeInUp(
            delay: Duration(milliseconds: 400 + (index * 100)),
            child: FavorisWidget(favoris: favoris),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Iconsax.heart,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Aucun favori',
                style: GoogleFonts.ubuntu(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vous n\'avez pas encore ajouté de banques\nde sang à vos favoris',
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Iconsax.heart, size: 18),
                label: Text('Découvrir les banques'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
