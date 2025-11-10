import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/PocheBanqueWidget.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/PocheModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/recherchePoche/RechercheCtrl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../business/model/recherche/DatumRecherchePocheModel.dart';

class Recherchepage extends ConsumerStatefulWidget {
  final String query;
  final bool isModal; // True if opened as modal/route, false if part of bottom nav
  final bool showBack; // Show back button when opened from Home

  const Recherchepage({super.key, required this.query, this.isModal = false, this.showBack = false});

  @override
  ConsumerState createState() => _RecherchepageState();
}

class _RecherchepageState extends ConsumerState<Recherchepage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching =
      true; // Initialiser à true pour afficher le champ de saisie par défaut
  List<DatumRecherchePocheModel> _results = [];
  bool _isLoading = false;

  void _performSearch(String query) async {
    print('🔍 Starting search for query: "$query"');

    setState(() {
      _isLoading = true; // Afficher le chargement
    });

    try {
      // Utilisez le contrôleur pour effectuer la recherche
      print('📡 Calling search API...');
      final results = await ref
          .read(rechercheCtrlProvider.notifier)
          .rechercheListeBanque(query, ""); // Token will be retrieved in the use case

      print('✅ Search completed. Results count: ${results.length}');
      if (results.isNotEmpty) {
        print('📄 First result: ${results.first.bloodBank.bloodBankName}');
        print('📄 Blood type: ${results.first.bloodBagInfo.bloodTypeInfo.bloodTypeName}');
        print('📄 Stock count: ${results.first.bloodStockCount}');
      } else {
        print('❌ No results found for query: "$query"');
      }

      setState(() {
        _results = results; // Mettez à jour l'état avec les résultats
        _isLoading = false; // Cacher le chargement après la recherche
      });
    } catch (error) {
      print('💥 Erreur lors de la recherche : $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la recherche. Veuillez réessayer.')),
      );
      setState(() {
        _isLoading = false; // Cacher le chargement en cas d'erreur
      });
    }
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear(); // Effacer le champ de recherche
      _results.clear(); // Effacer les résultats
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style to dark (black icons/text)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        statusBarBrightness: Brightness.light, // For iOS
      ),
    );

    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(context),

              // Content - transparent background
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: _isSearching
                      ? _buildSearchResults()
                      : Center(child: Text('Recherche...')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Top Row with Logo and Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo and Title
              Row(
                children: [
                  if (widget.showBack)
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Iconsax.arrow_left_2,
                          color: ColorPages.COLOR_PRINCIPAL,
                          size: 22,
                        ),
                      ),
                    ),
                  if (widget.showBack) const SizedBox(width: 8),
                  // Cart Icon
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.search_normal,
                    color: ColorPages.COLOR_PRINCIPAL,
                    size: 24,
                  ),
                ),
                  
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recherche',
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                      Text(
                        'Trouvez votre poche de sang',
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Close button (only if modal)
              if (widget.isModal && !widget.showBack)
                Container(
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_BLANCHE.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      _searchController.clear();
                      setState(() {
                        _results.clear();
                        _isLoading = false;
                      });
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Iconsax.close_circle,
                      color: ColorPages.COLOR_PRINCIPAL,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Rechercher une poche... ex. A+',
                  hintStyle: GoogleFonts.ubuntu(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 15),
                    child: Icon(
                      Iconsax.search_normal,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  suffixIcon: Container(
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
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                style: GoogleFonts.ubuntu(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (value) {
                  setState(() {});
                  if (value.isNotEmpty) {
                    _performSearch(value);
                  } else {
                    setState(() {
                      _results.clear();
                    });
                  }
                },
                onSubmitted: (value) {
                  FocusScope.of(context).unfocus();
                  _performSearch(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ColorPages.COLOR_PRINCIPAL),
            ),
            const SizedBox(height: 16),
            Text(
              'Recherche en cours...',
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyState();
    }

    if (_results.isEmpty) {
      return _buildInitialState();
    }

    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final item = _results[index];

          // Convert DatumRecherchePocheModel to PocheModel
          PocheModel poche =
              PocheModel.fromRecherche(item); // Ensure this method exists

          // Convert BloodBankRecherchePocheModel to BanqueModele
          BanqueModele banque = BanqueModele.fromRecherche(
              item.bloodBank); // Ensure this method exists

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
              child: PocheBanqueWidget(
                poches: poche,
                banque: banque,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Empty state icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Iconsax.search_normal,
                  size: 60,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Aucun résultat trouvé',
                style: GoogleFonts.ubuntu(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Nous n\'avons trouvé aucune poche de sang correspondant à "${_searchController.text}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Suggestions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggestions:',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Vérifiez l\'orthographe\n• Essayez des termes plus généraux\n• Utilisez des abréviations (ex: A+, O-, AB+)',
                      style: GoogleFonts.ubuntu(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Retry button
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _results.clear();
                  });
                },
                icon: Icon(Iconsax.refresh),
                label: Text('Nouvelle recherche'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Search icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Iconsax.search_favorite,
                  size: 50,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Rechercher des poches de sang',
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),

              const SizedBox(height: 12),

              // Instructions
              Text(
                'Tapez le type de sang recherché dans la barre de recherche ci-dessus',
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // Examples
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['A+', 'O-', 'B+', 'AB+', 'O+','A-','B-','AB-'].map((type) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = type;
                      _performSearch(type);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
