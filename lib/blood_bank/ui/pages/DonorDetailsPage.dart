import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../business/interactors/BloodBankController.dart';
import '../../business/model/BloodEnums.dart';
import '../../business/model/BloodStock.dart';
import '../../models/donor.dart';
import '../../models/donor_eligibility.dart';

class DonorDetailsPage extends ConsumerStatefulWidget {
  final Donor donor;

  const DonorDetailsPage({
    Key? key,
    required this.donor,
  }) : super(key: key);

  @override
  ConsumerState<DonorDetailsPage> createState() => _DonorDetailsPageState();
}

class _DonorDetailsPageState extends ConsumerState<DonorDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // QR code widget with global key for capturing
  final GlobalKey _qrKey = GlobalKey();
  // Donor ID card widget for export/share
  final GlobalKey _idCardKey = GlobalKey();
  int? _totalDonationsOverride;
  String? _lastDonationDateOverride;
  late List<Map<String, String>> _donationHistory;
  bool _isProcessingIdCard = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _donationHistory = [
      {
        'date': '2025-09-15',
        'type': 'Sang total',
        'volume': '450 ml',
        'location': 'Centre de Don Kinshasa',
        'status': 'Complété',
        'batch': 'DN-2025-001',
        'description': '',
      },
      {
        'date': '2025-07-20',
        'type': 'Plaquettes',
        'volume': '200 ml',
        'location': 'Unité Mobile #3',
        'status': 'Complété',
        'batch': 'DN-2025-002',
        'description': '',
      },
      {
        'date': '2025-04-05',
        'type': 'Sang total',
        'volume': '450 ml',
        'location': 'Centre de Don Kinshasa',
        'status': 'Complété',
        'batch': 'DN-2025-003',
        'description': '',
      },
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _displayTotalDonations {
    return _totalDonationsOverride ?? (widget.donor.totalDonations ?? 0);
  }

  String get _displayLastDonationDate {
    final source = _lastDonationDateOverride ?? widget.donor.lastDonationDate;
    if (source == null || source.isEmpty) {
      return 'Aucun don enregistré';
    }
    return _formatDateFromString(source);
  }

  Future<DonorEligibility?> _checkDonorEligibility() async {
    if (!mounted) {
      return null;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    bool dialogActive = false;

    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogActive = true;

      final apiService = ref.read(bloodBankApiServiceProvider);
      final response = await apiService.checkDonorEligibility(widget.donor.id);

      if (dialogActive && mounted) {
        navigator.pop();
        dialogActive = false;
      }

      if (response.success && response.data != null) {
        return response.data;
      }

      if (mounted) {
        final message = response.error ?? "Impossible de vérifier l'éligibilité du donneur";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } catch (e) {
      if (dialogActive && mounted) {
        navigator.pop();
        dialogActive = false;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la vérification: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (dialogActive && mounted) {
        try {
          navigator.pop();
        } catch (_) {}
      }
    }
  }

  Future<void> _showIneligibilityDialog(DonorEligibility eligibility) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final reasons = eligibility.reasons;
        final deferrals = eligibility.deferrals;
        final nextEligibleDate = eligibility.nextEligibleDate;
        final recommendations = eligibility.recommendations;

        return AlertDialog(
          title: Text(
            'Donneur non éligible',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reasons.isNotEmpty) ...[
                  Text(
                    'Raisons',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...reasons.map(_buildDialogBullet),
                  const SizedBox(height: 12),
                ],
                if (deferrals.isNotEmpty) ...[
                  Text(
                    'Déferrals actifs',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...deferrals.map((deferral) {
                    final buffer = StringBuffer(deferral.reason ?? 'Raison inconnue');
                    if (deferral.endDate != null) {
                      buffer.write(" (jusqu'au ${_formatDate(deferral.endDate!)} )");
                    }
                    if ((deferral.type ?? '').isNotEmpty) {
                      buffer.write(' • ${deferral.type}');
                    }
                    return _buildDialogBullet(buffer.toString());
                  }),
                  const SizedBox(height: 12),
                ],
                if (nextEligibleDate != null) ...[
                  Text(
                    'Prochaine date admissible : ${_formatDate(nextEligibleDate)}',
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (recommendations.isNotEmpty) ...[
                  Text(
                    'Recommandations',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...recommendations.map(_buildDialogBullet),
                ],
                if (reasons.isEmpty && deferrals.isEmpty && nextEligibleDate == null)
                  Text(
                    "Le donneur n'est pas éligible pour le moment.",
                    style: GoogleFonts.poppins(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Compris',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNewDonationSheet() async {
    final eligibility = await _checkDonorEligibility();
    if (!mounted || eligibility == null) {
      return;
    }

    if (!eligibility.isEligible) {
      await _showIneligibilityDialog(eligibility);
      return;
    }

    final result = await showModalBottomSheet<_DonationSubmissionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _NewDonationSheet(donor: widget.donor);
      },
    );

    if (!mounted || result == null || !result.success) {
      return;
    }

    final formattedVolume = result.volume % 1 == 0
        ? result.volume.toStringAsFixed(0)
        : result.volume.toStringAsFixed(1);
    final location = widget.donor.address != null && widget.donor.address!.isNotEmpty
        ? widget.donor.address!
        : 'Centre de don principal';

    setState(() {
      _totalDonationsOverride = _displayTotalDonations + 1;
      _lastDonationDateOverride = result.newDonationDate.toIso8601String();
      _donationHistory = [
        {
          'date': result.newDonationDate.toIso8601String(),
          'type': 'Sang total',
          'volume': '$formattedVolume ml',
          'location': location,
          'status': 'Complété',
          'batch': result.batchNumber,
          'description': result.description ?? '',
        },
        ..._donationHistory,
      ];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Don enregistré avec succès',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails du Donneur',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: () {
              // Edit functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité à venir'),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Profil'),
            Tab(text: 'Historique'),
            Tab(text: 'Badges'),
          ],
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildHistoryTab(),
          _buildBadgesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewDonationSheet,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nouveau Don',
          style: GoogleFonts.poppins(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donor Header
          _buildDonorHeader(),
          
          const SizedBox(height: 16),
          
          // Donor QR Code
          _buildDonorQrCode(),
          
          const SizedBox(height: 24),

          _buildDonorIdCardSection(),
          
          const SizedBox(height: 24),
          
          // Personal Information Section
          _buildSectionTitle('Informations Personnelles'),
          _buildInfoCard(
            children: [
              _buildInfoRow('ID Donneur', widget.donor.donorCode ?? widget.donor.id),
              _buildInfoRow('Nom complet', widget.donor.fullName),
              _buildInfoRow(
                'Genre', 
                widget.donor.gender.toLowerCase() == 'm' ? 'Masculin' : 'Féminin'
              ),
              _buildInfoRow('Date de naissance', widget.donor.dateOfBirth),
              _buildInfoRow('Groupe sanguin', widget.donor.bloodType),
              _buildInfoRow('Status', 'Actif'),
              _buildInfoRow('Inscription', _formatDate(widget.donor.createdAt)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Contact Information Section
          _buildSectionTitle('Coordonnées'),
          _buildInfoCard(
            children: [
              _buildInfoRow('Téléphone', widget.donor.phoneNumber),
              _buildInfoRow('Email', widget.donor.email ?? 'Non renseigné'),
              _buildInfoRow('Adresse', widget.donor.address ?? 'Non renseignée'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Emergency Contact Section
          _buildSectionTitle('Contact d\'Urgence'),
          _buildInfoCard(
            children: [
              _buildInfoRow(
                'Nom', 
                widget.donor.emergencyContactName ?? 'Non renseigné'
              ),
              _buildInfoRow(
                'Téléphone', 
                widget.donor.emergencyContactPhone ?? 'Non renseigné'
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Medical Summary Section
          _buildSectionTitle('Résumé Médical'),
          _buildInfoCard(
            children: [
              _buildInfoRow(
                'Total de dons', 
                '$_displayTotalDonations dons'
              ),
              _buildInfoRow(
                'Dernier don', 
                _displayLastDonationDate
              ),
              _buildInfoRow('Éligibilité', 'Éligible'),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique des Dons',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_donationHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bloodtype_outlined,
                      size: 70,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun don enregistré',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les dons apparaîtront ici une fois enregistrés',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _donationHistory.length,
                itemBuilder: (context, index) {
                  final donation = _donationHistory[index];
                  final String rawDate = donation['date'] ?? '';
                  final String displayDate = rawDate.isEmpty
                      ? 'Date inconnue'
                      : _formatDateFromString(rawDate);
                  final String type = donation['type'] ?? 'Don';
                  final String volume = donation['volume'] ?? '';
                  final String location = donation['location'] ?? 'Centre inconnu';
                  final String status = donation['status'] ?? 'Enregistré';
                  final String batch = donation['batch'] ?? '';
                  final String description = donation['description'] ?? '';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Don du $displayDate',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDonationInfoRow('Type de don', type),
                          _buildDonationInfoRow('Volume', volume),
                          _buildDonationInfoRow('Centre de collecte', location),
                          batch.isNotEmpty
                              ? _buildDonationInfoRow('Numéro de lot', batch)
                              : const SizedBox.shrink(),
                          description.isNotEmpty
                              ? _buildDonationInfoRow('Notes', description)
                              : const SizedBox.shrink(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.visibility),
                                label: const Text('Voir détails'),
                                onPressed: () {
                                  // View donation details
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    // Mock badges for demonstration
    final mockBadges = [
      {
        'name': 'Badge de Bienvenue',
        'description': 'Décerné aux nouveaux donneurs lors de leur enregistrement.',
        'awarded_date': widget.donor.createdAt.toString(),
        'icon': Icons.emoji_events,
        'color': Colors.amber,
      },
      {
        'name': 'Premier Don',
        'description': 'Décerné après avoir complété le premier don de sang.',
        'awarded_date': '2025-09-15',
        'icon': Icons.favorite,
        'color': Colors.red,
      },
      {
        'name': 'Donneur Régulier',
        'description': 'Pour avoir effectué au moins 3 dons.',
        'awarded_date': '2025-09-15',
        'icon': Icons.repeat,
        'color': Colors.blue,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Badges et Récompenses',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: mockBadges.length,
              itemBuilder: (context, index) {
                final badge = mockBadges[index];
                final iconData = badge['icon'] as IconData;
                final color = badge['color'] as Color;
                
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            iconData,
                            size: 40,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          badge['name'] as String,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Obtenu le ${_formatDateFromString(badge['awarded_date'] as String)}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badge['description'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorHeader() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile image or blood type
            if (widget.donor.photoUrl != null && widget.donor.photoUrl!.isNotEmpty)
              GestureDetector(
                onTap: () => _showFullScreenImage(widget.donor.photoUrl!),
                child: Hero(
                  tag: 'donor_photo_${widget.donor.id}',
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(widget.donor.photoUrl!),
                  ),
                ),
              )
            else
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.red.shade100,
                child: Text(
                  widget.donor.bloodType,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
              
            const SizedBox(width: 16),
            
            // Donor info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.donor.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Donor code and gender
                  Row(
                    children: [
                      Icon(
                        widget.donor.gender.toLowerCase() == 'm' ? Icons.male : Icons.female,
                        size: 16,
                        color: widget.donor.gender.toLowerCase() == 'm' 
                            ? Colors.blue 
                            : Colors.pink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.donor.gender.toLowerCase() == 'm' ? 'Homme' : 'Femme',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.donor.donorCode ?? widget.donor.id,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.donor.phoneNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.donor.email != null && widget.donor.email!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.donor.email!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.donor.address != null && widget.donor.address!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.donor.address!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Donor statistics
                  Row(
                    children: [
                      _buildStatItem(
                        value: '${widget.donor.totalDonations ?? 0}',
                        label: 'Dons',
                        icon: Icons.bloodtype,
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        value: widget.donor.lastDonationDate != null
                            ? 'Récent'
                            : 'Aucun',
                        label: 'Dernier don',
                        icon: Icons.calendar_today,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label + ' :',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ' :',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        '• $text',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  String _buildInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'ID';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Widget _buildDonorIdCardSection() {
    final donor = widget.donor;
    final donorCode = donor.donorCode ?? donor.id;
    final formattedBirthDate = donor.dateOfBirth.isNotEmpty
        ? _formatDateFromString(donor.dateOfBirth)
        : '';
    final registrationDate = _formatDate(donor.createdAt);
  const Color cardStart = Color(0xFFF9E6F1);
  const Color cardEnd = Color(0xFFE4EEFF);
    const Color primaryTextColor = Color(0xFF2C1B52);
    const Color secondaryTextColor = Color(0x992C1B52);
    const Color accentColor = Color(0xFFE24C5C);

    final detailItems = <Map<String, String>>[
      {'label': 'Nom complet', 'value': donor.fullName},
      {'label': 'Code donneur', 'value': donorCode},
      if (formattedBirthDate.isNotEmpty)
        {'label': 'Date de naissance', 'value': formattedBirthDate},
      {'label': 'Téléphone', 'value': donor.phoneNumber},
      if ((donor.email ?? '').isNotEmpty)
        {'label': 'Email', 'value': donor.email!},
      if ((donor.address ?? '').isNotEmpty)
        {'label': 'Adresse', 'value': donor.address!},
      {'label': 'Inscription', 'value': registrationDate},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Carte d\'identité numérique'),
        const SizedBox(height: 12),
        RepaintBoundary(
          key: _idCardKey,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [cardStart, cardEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1AAE5D5D),
                  blurRadius: 20,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: const _SpiderWebPainter(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        width: 42,
                        height: 42,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'eBlood Connect',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'Carte d\'identité du donneur',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        donor.bloodType.isNotEmpty ? donor.bloodType : 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isCompact = constraints.maxWidth < 460;

                    Widget buildPortrait() {
                      return Container(
                        width: 94,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.1),
                          image: (donor.photoUrl != null && donor.photoUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(donor.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (donor.photoUrl == null || donor.photoUrl!.isEmpty)
                            ? Center(
                                child: Text(
                                  _buildInitials(donor.fullName),
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextColor,
                                  ),
                                ),
                              )
                            : null,
                      );
                    }

                    Widget buildDetails() {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final detail in detailItems)
                            _buildIdCardInfoField(detail['label']!, detail['value']!),
                        ],
                      );
                    }

                    Widget buildQr() {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: QrImageView(
                          data: donorCode,
                          version: QrVersions.auto,
                          size: 120,
                          backgroundColor: Colors.white,
                          gapless: true,
                        ),
                      );
                    }

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildPortrait(),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: SizedBox(
                                    width: 132,
                                    child: buildQr(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          buildDetails(),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildPortrait(),
                        const SizedBox(width: 20),
                        Expanded(child: buildDetails()),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 132,
                          child: buildQr(),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Valide dans tous les centres partenaires du réseau eBlood.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessingIdCard ? null : _downloadIdCard,
                icon: const Icon(Icons.download),
                label: Text(
                  'Télécharger la carte',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade700),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessingIdCard ? null : _shareIdCard,
                icon: const Icon(Icons.share, color: Colors.white),
                label: Text(
                  'Partager la carte',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isProcessingIdCard) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Génération de la carte...',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildIdCardInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0x992C1B52),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C1B52),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _captureWidgetAsImage(GlobalKey boundaryKey) async {
    try {
      final boundaryContext = boundaryKey.currentContext;
      if (boundaryContext == null) {
        return null;
      }

      final renderObject = boundaryContext.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        return null;
      }

      final image = await renderObject.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _downloadIdCard() async {
    if (_isProcessingIdCard) {
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessingIdCard = true;
      });
    }

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final pngBytes = await _captureWidgetAsImage(_idCardKey);

      if (pngBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Impossible de générer la carte du donneur',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final documentsDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${documentsDir.path}/eblood_id_cards');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final donorCode = widget.donor.donorCode ?? widget.donor.id;
      final fileName = 'carte_donneur_${donorCode}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${exportDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Carte enregistrée dans ${exportDir.path}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'enregistrement: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingIdCard = false;
        });
      }
    }
  }

  Future<void> _shareIdCard() async {
    if (_isProcessingIdCard) {
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessingIdCard = true;
      });
    }

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final pngBytes = await _captureWidgetAsImage(_idCardKey);

      if (pngBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Impossible de générer la carte du donneur',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final donorCode = widget.donor.donorCode ?? widget.donor.id;
      final fileName = 'carte_donneur_${donorCode}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: fileName)],
        text: 'Carte de donneur de ${widget.donor.fullName}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Carte partagée avec succès',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du partage: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingIdCard = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    // Format date as DD/MM/YYYY
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateFromString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
  
  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenPhotoView(
          imageUrl: imageUrl, 
          heroTag: 'donor_photo_${widget.donor.id}',
          donorName: widget.donor.fullName,
        ),
      ),
    );
  }
  
  // Method to share QR code as image
  Future<void> _shareQrCode() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final pngBytes = await _captureWidgetAsImage(_qrKey);

      if (pngBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Impossible de générer le QR Code',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'qr_donneur_${widget.donor.donorCode ?? widget.donor.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: fileName)],
        text: 'QR Code du donneur: ${widget.donor.fullName}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'QR Code partagé avec succès',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildDonorQrCode() {
    final donorCode = widget.donor.donorCode ?? widget.donor.id;
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Code Donneur',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // QR Code with center logo
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: RepaintBoundary(
                key: _qrKey,
                child: QrImageView(
                  data: donorCode,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  // embeddedImage: const AssetImage('assets/icons/icon.png'),
                  // embeddedImageStyle: QrEmbeddedImageStyle(
                  //   size: Size(40, 40),
                  // ),
                  errorStateBuilder: (cxt, err) {
                    return Center(
                      child: Text(
                        'Erreur de génération du QR Code',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              donorCode,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scannez pour identifier rapidement',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            // Share button
            ElevatedButton.icon(
              onPressed: _shareQrCode,
              icon: const Icon(Icons.share, color: Colors.white),
              label: Text(
                'Partager le QR Code',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpiderWebPainter extends CustomPainter {
  const _SpiderWebPainter();

  static const Color _lineColor = Color(0x142C1B52);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;

    final Offset center = Offset(size.width * 0.25, size.height * 0.38);
    final double maxRadius = math.sqrt(
          size.width * size.width + size.height * size.height,
        ) /
        2.4;

    const int ringCount = 6;
    for (int i = 1; i <= ringCount; i++) {
      canvas.drawCircle(center, (maxRadius / ringCount) * i, paint);
    }

    const int spokeCount = 12;
    for (int i = 0; i < spokeCount; i++) {
      final double angle = (2 * math.pi / spokeCount) * i;
      final Offset endPoint = Offset(
        center.dx + math.cos(angle) * maxRadius * 1.4,
        center.dy + math.sin(angle) * maxRadius * 1.4,
      );
      canvas.drawLine(center, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpiderWebPainter oldDelegate) {
    return false;
  }
}

class _DonationSubmissionResult {
  final bool success;
  final DateTime newDonationDate;
  final double volume;
  final String batchNumber;
  final String? description;

  const _DonationSubmissionResult({
    required this.success,
    required this.newDonationDate,
    required this.volume,
    required this.batchNumber,
    this.description,
  });
}

class _NewDonationSheet extends ConsumerStatefulWidget {
  final Donor donor;

  const _NewDonationSheet({
    required this.donor,
  });

  @override
  ConsumerState<_NewDonationSheet> createState() => _NewDonationSheetState();
}

class _NewDonationSheetState extends ConsumerState<_NewDonationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _batchNumberController;
  late final TextEditingController _volumeController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _batchNumberController = TextEditingController();
    _volumeController = TextEditingController(text: '450');
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _batchNumberController.dispose();
    _volumeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final String batchNumber = _batchNumberController.text.trim();
    final String description = _descriptionController.text.trim();
    final double volumeValue = double.parse(
      _volumeController.text.replaceAll(',', '.').trim(),
    );

    final DateTime now = DateTime.now();

    final bloodStock = BloodStock(
      id: '',
      bloodType: widget.donor.bloodType,
  volume: volumeValue,
      productType: BloodProductType.wholeBlood,
      status: BloodBagStatus.available,
      bagCondition: BloodBagConditionStatus.good,
      expirationDate: now.add(const Duration(days: 42)),
      collectionDate: now,
      donorId: widget.donor.id,
      batchNumber: batchNumber,
      description: description.isEmpty ? null : description,
      createdAt: now,
      updatedAt: now,
    );

    final controller = ref.read(bloodStockControllerProvider.notifier);
    final success = await controller.addBloodStock(bloodStock);
    final error = ref.read(bloodStockControllerProvider).error;

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success && (error == null || error.isEmpty)) {
      Navigator.of(context).pop(
        _DonationSubmissionResult(
          success: true,
          newDonationDate: now,
          volume: volumeValue,
          batchNumber: batchNumber,
          description: description.isEmpty ? null : description,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Impossible d\'enregistrer le don',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Text(
                    'Enregistrer un nouveau don',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Donneur: ${widget.donor.fullName} • ${widget.donor.bloodType}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _batchNumberController,
                    decoration: InputDecoration(
                      labelText: 'Numéro de lot',
                      hintText: 'Ex: BATCH-2025-001',
                      prefixIcon: Icon(Icons.qr_code_2, color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez renseigner le numéro de lot';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _volumeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Volume (ml)',
                      hintText: 'Ex: 450',
                      prefixIcon: Icon(Icons.local_drink, color: Colors.grey.shade600),
                      suffixText: 'ml',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez renseigner le volume du don';
                      }
                      final parsed = double.tryParse(value.replaceAll(',', '.').trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Volume invalide';
                      }
                      if (parsed < 250) {
                        return 'Le volume doit être supérieur à 250 ml';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Notes (optionnel)',
                      hintText: 'Observations ou détails complémentaires',
                      prefixIcon: Icon(Icons.note_alt, color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Enregistrer',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full screen photo viewer with zoom capabilities
class _FullScreenPhotoView extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final String donorName;
  
  const _FullScreenPhotoView({
    required this.imageUrl,
    required this.heroTag,
    required this.donorName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          donorName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: heroTag,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Impossible de charger l\'image',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}