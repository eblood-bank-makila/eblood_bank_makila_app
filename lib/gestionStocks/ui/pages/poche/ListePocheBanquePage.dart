import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/config/utils/Utils.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:eblood_bank_mak_app/apps/widgets/PocheBanqueWidget.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/localisationBanque/LocalisationBanquePage.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BanqueCtrl.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/poche/PocheController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ListePocheBanquePage extends ConsumerStatefulWidget {
  final String banqueId;
  final String banqueNom;
  final BanqueModele banque;
  final String localisation;

  ListePocheBanquePage(
      {required this.banqueId,
      required this.banque,
      required this.banqueNom,
      required this.localisation});

  @override
  ConsumerState createState() => _ListePocheBanquePageState();
}

class _ListePocheBanquePageState extends ConsumerState<ListePocheBanquePage> {
  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) async {
  //     var banquesCtrl = ref.read(banqueCtrlProvider);
  //     var rechercheBanque =
  //         banquesCtrl.banques.where((e) => e.id == widget.banqueId).toList();
  //
  //     if (rechercheBanque.isNotEmpty) {
  //       var ctrl = ref.read(pocheControllerProvider.notifier);
  //       ctrl.setBanque(rechercheBanque.first);
  //     } else {
  //       print('Aucune banque trouvée avec l\'ID: ${widget.banqueId}');
  //     }
  //   });
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPoches();
    });
  }

  Future<void> _loadPoches() async {
    var banquesCtrl = ref.read(banqueCtrlProvider);
    var rechercheBanque =
        banquesCtrl.banques.where((e) => e.id == widget.banqueId).toList();

    if (rechercheBanque.isNotEmpty) {
      var ctrl = ref.read(pocheControllerProvider.notifier);
      ctrl.setBanque(rechercheBanque.first);
    } else {
      print('Aucune banque trouvée avec l\'ID: ${widget.banqueId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    var state = ref.watch(pocheControllerProvider);
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
              _buildModernHeader(context),

              // Bank Info Card
              _buildBankInfoCard(context),
              const SizedBox(height: 16),
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
                  child: RefreshIndicator(
                    color: ColorPages.COLOR_PRINCIPAL,
                    onRefresh: _loadPoches,
                    child: Column(
                      children: [
                        // Blood Bags Header
                        _buildBloodBagsHeader(state),
                        const SizedBox(height: 16),
                        // Blood Bags List
                        Expanded(
                          child: state.isLoading
                              ? _buildModernLoading()
                              : state.poches.isNotEmpty
                                  ? _buildBloodBagsList(state)
                                  : _buildEmptyState(),
                        ),
                      ],
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

  Widget _chargement() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(ColorPages.COLOR_PRINCIPAL),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
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
                    widget.banqueNom.capitalizeFirstLetter(),
                    style: GoogleFonts.ubuntu(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Iconsax.location,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.localisation,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Direction Button
            GestureDetector(
              onTap: () => _openDirections(),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Iconsax.routing_2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Map Button
            GestureDetector(
              onTap: () => _openMap(),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Iconsax.map,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankInfoCard(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.hospital,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Banque de Sang',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Poches de sang disponibles',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.heart,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Actif',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodBagsHeader(dynamic state) {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.health,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Poches Disponibles',
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.poches.length} poche${state.poches.length > 1 ? 's' : ''} en stock',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: Text(
                'Disponible',
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: AppSpinner.heartbeat(
          size: 80,
          showMessage: true,
          message: 'Chargement des poches de sang...',
        ),
      ),
    );
  }

  Widget _buildBloodBagsList(dynamic state) {
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.poches.length,
        itemBuilder: (context, index) {
          final poche = state.poches[index];
          return FadeInUp(
            delay: Duration(milliseconds: 600 + (index * 100)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    // color: Colors.white,
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: PocheBanqueWidget(
                poches: poche,
                banque: widget.banque,
              ),
            ),
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
                  Iconsax.health,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Aucune poche disponible',
                style: GoogleFonts.ubuntu(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cette banque de sang n\'a pas de poches\ndisponibles pour le moment',
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _loadPoches(),
                icon: Icon(Iconsax.refresh, size: 18),
                label: Text('Actualiser'),
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

  Future<void> _openDirections() async {
    try {
      // Show loading indicator
      _showSnackBar('Obtention de votre position...');

      // Get current position with better error handling
      Position? currentPosition = await _getCurrentPositionWithRetry();

      if (currentPosition == null) {
        _showEnhancedErrorDialog(
          'Position non disponible',
          'Impossible d\'obtenir votre position actuelle. Vérifiez que:\n\n• Les services de localisation sont activés\n• L\'application a les permissions nécessaires\n• Vous êtes dans une zone avec signal GPS',
          showRetry: true,
          retryAction: () => _openDirections(),
        );
        return;
      }

      // Bank coordinates with validation
      double bankLat = double.tryParse(widget.banque.latitude.toString()) ?? 0.0;
      double bankLng = double.tryParse(widget.banque.longitude.toString()) ?? 0.0;

      if (bankLat == 0.0 || bankLng == 0.0) {
        _showEnhancedErrorDialog(
          'Coordonnées manquantes',
          'Les coordonnées de la banque ne sont pas disponibles. Contactez le support pour résoudre ce problème.',
          showRetry: false,
        );
        return;
      }

      _showSnackBar('Ouverture de l\'application de navigation...');

      // Try multiple navigation options
      bool success = await _launchNavigation(currentPosition, bankLat, bankLng);

      if (!success) {
        _showNavigationFallbackDialog(currentPosition, bankLat, bankLng);
      }
    } catch (e) {
      debugPrint('Direction error: $e');
      _showEnhancedErrorDialog(
        'Erreur de navigation',
        'Une erreur inattendue s\'est produite lors de l\'ouverture des directions.\n\nErreur: ${e.toString()}',
        showRetry: true,
        retryAction: () => _openDirections(),
      );
    }
  }

  Future<bool> _launchNavigation(Position currentPosition, double bankLat, double bankLng) async {
    try {
      debugPrint('Attempting to launch navigation from ${currentPosition.latitude},${currentPosition.longitude} to $bankLat,$bankLng');

      // Try Google Maps first
      String googleMapsUrl = 'https://www.google.com/maps/dir/'
          '${currentPosition.latitude},${currentPosition.longitude}/'
          '$bankLat,$bankLng';

      debugPrint('Trying Google Maps URL: $googleMapsUrl');

      try {
        bool canLaunchGoogle = await canLaunchUrl(Uri.parse(googleMapsUrl));
        debugPrint('Can launch Google Maps: $canLaunchGoogle');

        if (canLaunchGoogle) {
          await launchUrl(
            Uri.parse(googleMapsUrl),
            mode: LaunchMode.externalApplication,
          );
          _showSnackBar('Navigation ouverte avec succès');
          return true;
        }
      } catch (e) {
        debugPrint('Google Maps launch error: $e');
      }

      // Try Apple Maps (iOS)
      String appleMapsUrl = 'http://maps.apple.com/?saddr='
          '${currentPosition.latitude},${currentPosition.longitude}'
          '&daddr=$bankLat,$bankLng&dirflg=d';

      debugPrint('Trying Apple Maps URL: $appleMapsUrl');

      try {
        bool canLaunchApple = await canLaunchUrl(Uri.parse(appleMapsUrl));
        debugPrint('Can launch Apple Maps: $canLaunchApple');

        if (canLaunchApple) {
          await launchUrl(
            Uri.parse(appleMapsUrl),
            mode: LaunchMode.externalApplication,
          );
          _showSnackBar('Navigation ouverte avec succès');
          return true;
        }
      } catch (e) {
        debugPrint('Apple Maps launch error: $e');
      }

      // Try generic geo URL
      String geoUrl = 'geo:$bankLat,$bankLng?q=$bankLat,$bankLng(Banque de Sang)';

      debugPrint('Trying geo URL: $geoUrl');

      try {
        bool canLaunchGeo = await canLaunchUrl(Uri.parse(geoUrl));
        debugPrint('Can launch geo URL: $canLaunchGeo');

        if (canLaunchGeo) {
          await launchUrl(
            Uri.parse(geoUrl),
            mode: LaunchMode.externalApplication,
          );
          _showSnackBar('Navigation ouverte avec succès');
          return true;
        }
      } catch (e) {
        debugPrint('Geo URL launch error: $e');
      }

      debugPrint('All navigation methods failed');
      return false;
    } catch (e) {
      debugPrint('Launch navigation error: $e');
      return false;
    }
  }



  Future<Position?> _getCurrentPositionWithRetry() async {
    int maxRetries = 3;
    int currentRetry = 0;

    while (currentRetry < maxRetries) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('Location services disabled');
          return null;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            debugPrint('Location permission denied');
            return null;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          debugPrint('Location permission denied forever');
          return null;
        }

        // Try to get position with timeout
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            timeLimit: Duration(seconds: 30),
          ),
        );

        debugPrint('Position obtained: ${position.latitude}, ${position.longitude}');
        return position;

      } catch (e) {
        currentRetry++;
        debugPrint('Position attempt $currentRetry failed: $e');

        if (currentRetry < maxRetries) {
          // Wait before retry
          await Future.delayed(Duration(seconds: 2));
        } else {
          debugPrint('All position attempts failed');
          return null;
        }
      }
    }

    return null;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showEnhancedErrorDialog(String title, String message, {bool showRetry = false, VoidCallback? retryAction}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.warning_2,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Si le problème persiste, contactez le support technique.',
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fermer',
                style: GoogleFonts.ubuntu(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showRetry && retryAction != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  retryAction();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Réessayer',
                  style: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openMap() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSpinner.pulse(size: 50, showMessage: false),
                const SizedBox(height: 20),
                Text(
                  'Préparation de la carte...',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérification des permissions de localisation',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _showLocationPermissionDialog(
            'Services de localisation désactivés',
            'Veuillez activer les services de localisation dans les paramètres pour voir votre position sur la carte.',
            showOpenSettings: true,
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showLocationPermissionDialog(
            'Permission de localisation refusée',
            'L\'accès à votre localisation est nécessaire pour afficher votre position sur la carte. Vous pouvez l\'activer dans les paramètres.',
            showOpenSettings: true,
          );
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showLocationPermissionDialog(
            'Permission de localisation requise',
            'L\'application a besoin d\'accéder à votre localisation pour vous montrer votre position sur la carte et calculer les itinéraires.',
            showOpenSettings: false,
          );
        }
        return;
      }

      // Permission granted, open map
      if (mounted) {
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocalisationBanquePage(
                bloodBanks: [widget.banque],
              ),
            ),
          );
        } catch (mapError) {
          debugPrint('Map navigation error: $mapError');
          _showEnhancedErrorDialog(
            'Erreur de carte',
            'Impossible d\'ouvrir la page de carte. Vérifiez que:\n\n• L\'application a suffisamment de mémoire\n• Votre connexion internet fonctionne\n• L\'application n\'est pas corrompue',
            showRetry: true,
            retryAction: () => _openMap(),
          );
        }
      }
    } catch (e) {
      debugPrint('Map opening error: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        _showEnhancedErrorDialog(
          'Erreur d\'ouverture',
          'Une erreur inattendue s\'est produite lors de l\'ouverture de la carte.\n\nErreur: ${e.toString()}',
          showRetry: true,
          retryAction: () => _openMap(),
        );
      }
    }
  }

  void _showLocationPermissionDialog(String title, String message, {required bool showOpenSettings}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.location_cross,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La carte fonctionnera sans localisation, mais vous ne verrez pas votre position ni les itinéraires.',
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Open map anyway without location
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocalisationBanquePage(
                      bloodBanks: [widget.banque],
                    ),
                  ),
                );
              },
              child: Text(
                'Continuer sans GPS',
                style: GoogleFonts.ubuntu(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showOpenSettings)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Paramètres',
                  style: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openMap(); // Retry
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Réessayer',
                  style: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNavigationFallbackDialog(Position currentPosition, double bankLat, double bankLng) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.routing,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Navigation manuelle',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Impossible d\'ouvrir automatiquement l\'application de navigation. Voici les coordonnées pour naviguer manuellement:',
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Current Position
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          color: Colors.blue.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Votre position:',
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      '${currentPosition.latitude.toStringAsFixed(6)}, ${currentPosition.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Bank Position
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.hospital,
                          color: Colors.red.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Banque de sang:',
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      '${bankLat.toStringAsFixed(6)}, ${bankLng.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Copiez ces coordonnées dans votre application de navigation préférée.',
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fermer',
                style: GoogleFonts.ubuntu(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openDirections(); // Retry
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Réessayer',
                style: GoogleFonts.ubuntu(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
