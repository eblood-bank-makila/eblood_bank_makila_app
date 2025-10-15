import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/donors_provider.dart';
import '../../models/donor.dart';
import '../widgets/PaginationWidget.dart';
import 'DonorRegistrationPage.dart';
import 'DonorDetailsPage.dart';

class BloodDonorsManagementPage extends ConsumerStatefulWidget {
  const BloodDonorsManagementPage({super.key});

  @override
  ConsumerState<BloodDonorsManagementPage> createState() =>
      _BloodDonorsManagementPageState();
}

class _ChartBarData {
  final String label;
  final double value;
  final Color color;

  const _ChartBarData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _BloodDonorsManagementPageState
    extends ConsumerState<BloodDonorsManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'donor_code'; // Default search type
  String? _selectedGender; // null means "All" genders
  String? _selectedBloodType; // null means "All" blood types
  bool _isSearchActive = false;

  static const List<Color> _chartPalette = [
    Color(0xFFE57373),
    Color(0xFF64B5F6),
    Color(0xFFFFB74D),
    Color(0xFF81C784),
    Color(0xFF9575CD),
    Color(0xFFFF8A65),
    Color(0xFF4DB6AC),
    Color(0xFFA1887F),
    Color(0xFFBA68C8),
    Color(0xFF7986CB),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch donors when the page loads
    Future.microtask(() => ref.read(donorsProvider.notifier).fetchDonors());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestion des Donneurs',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner un code donneur',
            onPressed: () {
              _launchQRCodeScanner();
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Recherche par photo',
            onPressed: () {
              setState(() {
                _searchType = 'photo';
                _launchCameraForFaceSearch();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Aide de recherche',
            onPressed: () {
              _showSearchHelpDialog();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Donneurs'),
            Tab(text: 'Statistiques'),
          ],
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDonorsTab(), _buildStatisticsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate directly to donor registration page
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DonorRegistrationPage(),
            ),
          );

          // If we get a result back (true), refresh the donor list
          if (result == true) {
            ref.read(donorsProvider.notifier).refreshDonors();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Liste des donneurs mise à jour'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Ajouter Donneur',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDonorsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Persistent Search Bar
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.search, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: _getSearchHintText(),
                            border: InputBorder.none,
                            hintStyle: GoogleFonts.poppins(fontSize: 14),
                          ),
                          style: GoogleFonts.poppins(),
                          keyboardType: _getKeyboardType(),
                          inputFormatters: _getInputFormatters(),
                          onChanged: _performSearch,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _resetSearch,
                        ),
                    ],
                  ),
                  const Divider(height: 8),
                  // Search type chips with scroll indicators
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Left scroll indicator
                        Container(
                          width: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade100.withOpacity(0.9),
                                Colors.grey.shade100.withOpacity(0.0),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.chevron_left,
                              size: 18,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        // Scrollable search chips
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSearchTypeChip(
                                    'donor_code',
                                    'Code Donneur',
                                    Icons.badge,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ), // Increased space between chips
                                  _buildSearchTypeChip(
                                    'photo',
                                    'Photo',
                                    Icons.camera_alt,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ), // Increased space between chips
                                  _buildSearchTypeChip(
                                    'name',
                                    'Nom',
                                    Icons.person,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ), // Increased space between chips
                                  _buildSearchTypeChip(
                                    'phone',
                                    'Téléphone',
                                    Icons.phone,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Right scroll indicator
                        Container(
                          width: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade100.withOpacity(0.0),
                                Colors.grey.shade100.withOpacity(0.9),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gender selection when name search is selected
                  if (_searchType == 'name')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Text(
                            'Genre:',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildGenderRadio('Tous', null),
                          const SizedBox(width: 16),
                          _buildGenderRadio('Homme', 'm'),
                          const SizedBox(width: 16),
                          _buildGenderRadio('Femme', 'f'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Blood Group Filter options
          Text(
            'Filtrer par groupe sanguin:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          // Blood type filters with scroll indicators
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Left scroll indicator
                Container(
                  width: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade100.withOpacity(0.9),
                        Colors.grey.shade100.withOpacity(0.0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                // Scrollable blood type chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          _buildFilterChip('Tous'),
                          _buildFilterChip('A+'),
                          _buildFilterChip('A-'),
                          _buildFilterChip('B+'),
                          _buildFilterChip('B-'),
                          _buildFilterChip('AB+'),
                          _buildFilterChip('AB-'),
                          _buildFilterChip('O+'),
                          _buildFilterChip('O-'),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right scroll indicator
                Container(
                  width: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade100.withOpacity(0.0),
                        Colors.grey.shade100.withOpacity(0.9),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Active Filters Display
          Consumer(
            builder: (context, ref, child) {
              final donorsState = ref.watch(donorsProvider);

              // Update local state based on provider state
              if (_isSearchActive != donorsState.isSearchActive) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _isSearchActive = donorsState.isSearchActive;
                  });
                });
              }

              if (donorsState.isSearchActive) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildActiveFilters(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Donors list
          Expanded(child: _buildDonorsList()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final String chipLabel = label;
    // For 'Tous', we set bloodType to null to indicate no filter
    // For specific blood types, we use the label value
    final String? bloodType = label == 'Tous' ? null : label;

    // Use dynamic sizing for better internationalization support
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      child: FilterChip(
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            chipLabel,
            style: GoogleFonts.poppins(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        showCheckmark: false, // Hide checkmark to save space
        visualDensity: VisualDensity.compact,
        // For 'Tous', it's selected when _selectedBloodType is null
        // For specific blood types, it's selected when _selectedBloodType matches the blood type
        selected:
            (label == 'Tous' && _selectedBloodType == null) ||
            _selectedBloodType == bloodType,
        onSelected: (selected) {
          setState(() {
            // If 'Tous' is selected, set _selectedBloodType to null
            // If a specific blood type is selected, set _selectedBloodType to that value
            // If deselected, set _selectedBloodType to null
            _selectedBloodType = selected ? bloodType : null;
          });

          // Update provider with blood type filter
          _performSearch(_searchController.text);
        },
      ),
    );
  }

  Widget _buildDonorsList() {
    // Use Consumer to watch the donorsProvider state
    return Consumer(
      builder: (context, ref, child) {
        final donorsState = ref.watch(donorsProvider);

        // Handle loading state
        if (donorsState.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        // Handle error state
        if (donorsState.isError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 70, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Une erreur est survenue',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  donorsState.errorMessage,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(donorsProvider.notifier).refreshDonors();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        // Handle empty state with search active
        if (donorsState.donors.isEmpty && donorsState.isSearchActive) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 70, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Aucun donneur trouvé',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Essayez avec d\'autres termes de recherche',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        // Handle empty state without search
        if (donorsState.donors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 70, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Aucun donneur enregistré',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez votre premier donneur avec le bouton ci-dessous',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Debug donor state
        debugPrint(
          'UI: Donor list contains ${donorsState.donors.length} items',
        );
        debugPrint(
          'UI: isLoading=${donorsState.isLoading}, hasMorePages=${donorsState.hasMorePages}',
        );

        // Display donors list with pagination
        return Column(
          children: [
            // Debug message at top
            donorsState.donors.isEmpty
                ? Container(
                    color: Colors.yellow.shade100,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Données chargées avec succès, mais la liste est vide',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  )
                : Container(
                    color: Colors.green.shade100,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '${donorsState.donors.length} donneurs trouvés',
                      style: TextStyle(color: Colors.green.shade900),
                    ),
                  ),
            Expanded(
              // RefreshIndicator needs a scrollable widget as its direct child
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(donorsProvider.notifier).refreshDonors(),
                color: Colors.red,
                child: ListView.separated(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator to work when content doesn't fill screen
                  itemCount:
                      donorsState.donors.length +
                      1, // +1 for the load more button
                  separatorBuilder: (context, index) =>
                      index < donorsState.donors.length
                      ? const Divider()
                      : const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    // Show donors
                    if (index < donorsState.donors.length) {
                      final donor = donorsState.donors[index];
                      debugPrint(
                        'Building donor card for: ${donor.firstName} ${donor.lastName}',
                      );
                      return _buildDonorCard(donor);
                    }
                    // Show load more button at the end
                    else {
                      return LoadMoreWidget(
                        isLoading: donorsState.isLoading,
                        onLoadMore: () =>
                            ref.read(donorsProvider.notifier).loadNextPage(),
                        hasMorePages: donorsState.hasMorePages,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDonorCard(Donor donor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Text(
                donor.bloodType,
                style: GoogleFonts.poppins(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Gender indicator
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: donor.gender.toLowerCase() == 'm'
                    ? Colors.blue.shade200
                    : Colors.pink.shade200,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Icon(
                donor.gender.toLowerCase() == 'm' ? Icons.male : Icons.female,
                size: 14,
                color: donor.gender.toLowerCase() == 'm'
                    ? Colors.blue.shade800
                    : Colors.pink.shade800,
              ),
            ),
          ],
        ),
        title: Text(
          donor.fullName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tél: ${donor.phoneNumber}',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            Row(
              children: [
                if (donor.lastDonationDate != null)
                  Expanded(
                    child: Text(
                      'Dernière donation: ${donor.lastDonationDate}',
                      style: GoogleFonts.poppins(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Dons: ${donor.totalDonations ?? 0}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: Colors.blue,
              onPressed: () {
                // Edit donor
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: Colors.red,
              onPressed: () {
                // Delete donor
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),
          ],
        ),
        onTap: () {
          // Navigate to donor details page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DonorDetailsPage(donor: donor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer(
      builder: (context, ref, _) {
        final donorsState = ref.watch(donorsProvider);
        final notifier = ref.read(donorsProvider.notifier);
        final stats = donorsState.statistics;

        if (donorsState.isStatisticsLoading &&
            (stats == null || stats.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Widget> children = [];

        if (donorsState.isStatisticsError && (stats == null || stats.isEmpty)) {
          children.add(
            _buildStatisticsErrorCard(
              message: donorsState.statisticsErrorMessage,
              onRetry: () => notifier.fetchDonorStatistics(),
            ),
          );
        } else {
          final statisticsData = stats ?? <String, dynamic>{};
          if (donorsState.isStatisticsLoading) {
            children.add(const LinearProgressIndicator());
            children.add(const SizedBox(height: 16));
          }

          children.add(
            Text(
              'Statistiques des Donneurs',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

          children.add(const SizedBox(height: 12));
          children.addAll(_buildStatisticsContent(statisticsData));

          if (donorsState.isStatisticsError &&
              stats != null &&
              stats.isNotEmpty) {
            children.insert(
              1,
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildStatisticsWarningBanner(
                  donorsState.statisticsErrorMessage,
                ),
              ),
            );
          }
        }

        return RefreshIndicator(
          onRefresh: () => notifier.fetchDonorStatistics(),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            physics: const AlwaysScrollableScrollPhysics(),
            children: children,
          ),
        );
      },
    );
  }

  List<Widget> _buildStatisticsContent(Map<String, dynamic> statistics) {
    final summary = _asMap(statistics['summary']);
    final bloodDistribution = _asMapList(statistics['blood_type_distribution']);
    final donationActivity = _asMap(statistics['donation_activity']);
    final genderDistribution = _asMapList(statistics['gender_distribution']);
    final ageDistribution = _asMapList(statistics['age_distribution']);
    final generatedAt = statistics['generated_at'] as String?;

    final widgets = <Widget>[];

    widgets.add(_buildStatisticsSummaryCard(summary, generatedAt));
    widgets.add(const SizedBox(height: 16));
    widgets.add(_buildBloodDistributionCard(bloodDistribution));
    widgets.add(const SizedBox(height: 16));
    widgets.add(_buildDonationActivityCard(donationActivity));

    if (genderDistribution.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(_buildGenderDistributionCard(genderDistribution));
    }

    if (ageDistribution.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(_buildAgeDistributionCard(ageDistribution));
    }

    return widgets;
  }

  Widget _buildStatisticsSummaryCard(
    Map<String, dynamic>? summary,
    String? generatedAt,
  ) {
    if (summary == null || summary.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Aucune donnée de synthèse disponible pour le moment.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }

    final metrics = <Widget>[
      _buildStatisticChip(
        label: 'Total donneurs',
        value: _formatNumber(summary['total_donors']),
        icon: Icons.people_alt,
        color: Colors.red.shade100,
      ),
      _buildStatisticChip(
        label: 'Donneurs actifs',
        value: _formatNumber(summary['active_donors']),
        icon: Icons.favorite,
        color: Colors.green.shade100,
      ),
      _buildStatisticChip(
        label: 'Nouveaux (30j)',
        value: _formatNumber(summary['new_donors_last_30_days']),
        icon: Icons.calendar_today,
        color: Colors.blue.shade100,
      ),
      _buildStatisticChip(
        label: 'Donneurs réguliers',
        value: _formatNumber(summary['regular_donors_last_year']),
        icon: Icons.repeat,
        color: Colors.orange.shade100,
      ),
      _buildStatisticChip(
        label: 'Âge moyen',
        value: summary['average_age'] != null
            ? '${_parseDouble(summary['average_age']).toStringAsFixed(1)} ans'
            : 'N/A',
        icon: Icons.cake,
        color: Colors.purple.shade100,
      ),
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vue d’ensemble',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: metrics),
            if (generatedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Actualisé le ${generatedAt.replaceAll('T', ' ').split('.').first}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBloodDistributionCard(List<Map<String, dynamic>> distribution) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribution par Groupe Sanguin',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (distribution.isEmpty)
              Text('Aucune donnée disponible.', style: GoogleFonts.poppins())
            else ...[
              SizedBox(
                height: 240,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: distribution.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final count = math.max(_parseDouble(data['count']), 0.0);
                      final percentage = _parseDouble(data['percentage']);

                      return PieChartSectionData(
                        color: _colorForIndex(index),
                        value: count,
                        showTitle: true,
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 90,
                        titleStyle: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: distribution.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final label = (data['blood_type'] ?? 'Inconnu').toString();
                  final count = _formatNumber(data['count']);
                  final percentage = _parseDouble(data['percentage']);
                  return _buildChartLegendItem(
                    color: _colorForIndex(index),
                    label: label,
                    value: '$count (${percentage.toStringAsFixed(1)}%)',
                  );
                }).toList(),
              ),
              const Divider(height: 32),
              ...distribution.map(_buildDistributionRow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(Map<String, dynamic> entry) {
    final label = (entry['blood_type'] ?? 'Inconnu').toString();
    final count = _formatNumber(entry['count']);
    final percentage = _parseDouble(entry['percentage']);
    final progress = (percentage / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationActivityCard(Map<String, dynamic>? donationActivity) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fréquence des Donations',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (donationActivity == null || donationActivity.isEmpty)
              Text(
                'Aucune donnée de donation récente.',
                style: GoogleFonts.poppins(),
              )
            else ...[
              _buildBarChart([
                _ChartBarData(
                  label: '30j',
                  value: math.max(
                    _parseDouble(donationActivity['donations_last_30_days']),
                    0.0,
                  ),
                  color: _colorForIndex(0),
                ),
                _ChartBarData(
                  label: '90j',
                  value: math.max(
                    _parseDouble(donationActivity['donations_last_90_days']),
                    0.0,
                  ),
                  color: _colorForIndex(1),
                ),
                _ChartBarData(
                  label: '12m',
                  value: math.max(
                    _parseDouble(donationActivity['donations_last_year']),
                    0.0,
                  ),
                  color: _colorForIndex(2),
                ),
                _ChartBarData(
                  label: 'Réguliers',
                  value: math.max(
                    _parseDouble(donationActivity['regular_donors']),
                    0.0,
                  ),
                  color: _colorForIndex(3),
                ),
                _ChartBarData(
                  label: 'Inactifs',
                  value: math.max(
                    _parseDouble(donationActivity['inactive_donors']),
                    0.0,
                  ),
                  color: _colorForIndex(4),
                ),
              ]),
              const SizedBox(height: 16),
              _buildStatisticValueRow(
                'Dons sur 30 jours',
                donationActivity['donations_last_30_days'],
                icon: Icons.timelapse,
              ),
              _buildStatisticValueRow(
                'Dons sur 90 jours',
                donationActivity['donations_last_90_days'],
                icon: Icons.auto_graph,
              ),
              _buildStatisticValueRow(
                'Dons sur 12 mois',
                donationActivity['donations_last_year'],
                icon: Icons.calendar_month,
              ),
              const Divider(height: 24),
              _buildStatisticValueRow(
                'Donneurs réguliers',
                donationActivity['regular_donors'],
                icon: Icons.repeat,
              ),
              _buildStatisticValueRow(
                'Donneurs inactifs',
                donationActivity['inactive_donors'],
                icon: Icons.pause_circle_filled,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDistributionCard(List<Map<String, dynamic>> distribution) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition par Genre',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (distribution.isEmpty)
              Text('Aucune donnée disponible.', style: GoogleFonts.poppins())
            else ...[
              _buildBarChart(
                distribution.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final label = (data['gender'] ?? 'Autre').toString();
                  final count = math.max(_parseDouble(data['count']), 0.0);
                  return _ChartBarData(
                    label: label,
                    value: count,
                    color: _colorForIndex(index),
                  );
                }).toList(),
                height: 200,
              ),
              const SizedBox(height: 16),
              ...distribution.map(
                (entry) => _buildStatisticValueRow(
                  entry['gender'] ?? 'Autre',
                  entry['count'],
                  subtitle:
                      '${_parseDouble(entry['percentage']).toStringAsFixed(1)}%',
                  icon: Icons.person,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAgeDistributionCard(List<Map<String, dynamic>> distribution) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition par Tranches d’âge',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (distribution.isEmpty)
              Text('Aucune donnée disponible.', style: GoogleFonts.poppins())
            else ...[
              _buildBarChart(
                distribution.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final label = (data['range'] ?? 'N/A').toString();
                  final count = math.max(_parseDouble(data['count']), 0.0);
                  return _ChartBarData(
                    label: label,
                    value: count,
                    color: _colorForIndex(index),
                  );
                }).toList(),
                height: 220,
              ),
              const SizedBox(height: 16),
              ...distribution.map(
                (entry) => _buildStatisticValueRow(
                  entry['range'] ?? 'N/A',
                  entry['count'],
                  subtitle:
                      '${_parseDouble(entry['percentage']).toStringAsFixed(1)}%',
                  icon: Icons.timeline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticValueRow(
    String title,
    dynamic value, {
    String? subtitle,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.red.shade400),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatNumber(value),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<_ChartBarData> data, {double height = 220}) {
    final hasNonZeroValues = data.any((item) => item.value > 0);
    if (!hasNonZeroValues) {
      return Text(
        'Aucune donnée graphique disponible.',
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
      );
    }

    final maxValue = data.fold<double>(
      0.0,
      (prev, item) => math.max(prev, item.value),
    );
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final interval = _computeAxisInterval(maxY);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade300, strokeWidth: 1),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = data[group.x.toInt()];
                return BarTooltipItem(
                  '${item.label}\n',
                  GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value < 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      value.toInt().toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      data[index].label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.value,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: item.color,
                  borderSide: BorderSide(
                    color: item.color.withOpacity(0.7),
                    width: 1,
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: item.color.withOpacity(0.08),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _computeAxisInterval(double maxY) {
    if (maxY <= 1) return 1.0;
    if (maxY <= 5) return 1.0;
    if (maxY <= 10) return 2.0;
    if (maxY <= 25) return 5.0;
    if (maxY <= 50) return 10.0;
    if (maxY <= 100) return 20.0;
    final rounded = (maxY / 5).ceilToDouble();
    return rounded <= 0 ? 10.0 : rounded;
  }

  Widget _buildStatisticChip({
    required String label,
    required String value,
    IconData? icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.black54),
            const SizedBox(width: 6),
          ],
          Text(
            '$label: ',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatisticsErrorCard({
    required String message,
    required Future<void> Function() onRetry,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 32),
            const SizedBox(height: 12),
            Text(
              message.isNotEmpty
                  ? message
                  : 'Impossible de récupérer les statistiques.',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('Réessayer', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsWarningBanner(String message) {
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  String _formatNumber(dynamic value) {
    if (value is int) {
      return value.toString();
    }
    if (value is double) {
      return value % 1 == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return '0';
  }

  double _parseDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    }
    if (value is double) {
      return value;
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Color _colorForIndex(int index) {
    if (_chartPalette.isEmpty) {
      return Colors.red;
    }
    return _chartPalette[index % _chartPalette.length];
  }

  // Dialog and helper methods removed as they're replaced by the DonorDetailsPage

  // Helper method to build gender radio selection
  Widget _buildGenderRadio(String label, String? value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String?>(
          value: value,
          groupValue: _selectedGender,
          activeColor: Colors.red,
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
              // Re-run search if there's a query
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            });
          },
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: _selectedGender == value
                ? FontWeight.w600
                : FontWeight.normal,
            color: _selectedGender == value ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }

  // Helper method to build search type selection chips
  Widget _buildSearchTypeChip(String value, String label, IconData iconData) {
    final bool isSelected = _searchType == value;

    // Use intrinsic sizing for better internationalization support
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      child: FilterChip(
        selected: isSelected,
        backgroundColor: Colors.grey.shade100,
        selectedColor: Colors.red.shade100,
        checkmarkColor: Colors.red,
        showCheckmark: false, // Hide checkmark to save space
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
        ), // Increased padding for better text visibility
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelStyle: GoogleFonts.poppins(
          color: isSelected ? Colors.red : Colors.black,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
        avatar: Icon(
          iconData,
          size: 16,
          color: isSelected ? Colors.red : Colors.grey,
        ),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.red : Colors.black,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
        // label: Padding(
        //   padding: const EdgeInsets.only(right: 4.0),
        //   child: Text(
        //     label,
        //     // overflow: TextOverflow.visible,
        //     // softWrap: true,
        //   ),
        // ),
        onSelected: (bool selected) {
          setState(() {
            // If changing to a different search type, clear the search input
            if (_searchType != value) {
              _searchController.clear();
            }

            _searchType = value;

            // Clear selected gender when not on name search
            if (value != 'name') {
              _selectedGender = null;
            }

            // If photo is selected, launch camera
            if (value == 'photo' && selected) {
              _launchCameraForFaceSearch();
            } else if (_searchController.text.isNotEmpty ||
                _selectedGender != null) {
              // Re-run search with new search type
              _performSearch(_searchController.text);
            }
          });
        },
      ),
    );
  }

  // Helper method to display active search filters
  Widget _buildActiveFilters() {
    final donorsState = ref.watch(donorsProvider);

    // Local variable for filter text that will be calculated fresh each time
    String localFilterText = '';

    // Check search type and build appropriate filter text
    if (donorsState.searchQuery != null &&
        donorsState.searchQuery!.isNotEmpty) {
      // Get the proper label based on search type
      String searchTypeLabel = _getSearchTypeLabel(
        searchType: donorsState.searchType,
      );
      localFilterText = '$searchTypeLabel: "${donorsState.searchQuery}"';

      // For name search only, also show gender if applicable
      if (donorsState.searchType == 'name' && donorsState.gender != null) {
        String genderText = donorsState.gender == 'm' ? 'Homme' : 'Femme';
        localFilterText += ', Genre: $genderText';
      }
    } else if (donorsState.searchType == 'name' && donorsState.gender != null) {
      // Handle case where only gender is selected for name search
      String genderText = donorsState.gender == 'm' ? 'Homme' : 'Femme';
      localFilterText = 'Genre: $genderText';
    }

    // Add blood type filter text if applicable
    if (donorsState.bloodType != null && donorsState.bloodType!.isNotEmpty) {
      if (localFilterText.isNotEmpty) {
        localFilterText += ', Groupe sanguin: ${donorsState.bloodType}';
      } else {
        localFilterText = 'Groupe sanguin: ${donorsState.bloodType}';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtres actifs: $localFilterText',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear, size: 16, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _resetSearch,
          ),
        ],
      ),
    );
  }

  String _getSearchTypeLabel({String? searchType}) {
    // Use the provided searchType or fall back to _searchType
    String type = searchType ?? _searchType;

    switch (type) {
      case 'name':
        return 'Nom';
      case 'phone':
        return 'Téléphone';
      case 'donor_code':
        return 'Code Donneur';
      case 'photo':
        return 'Photo';
      default:
        return 'Recherche';
    }
  }

  void _performSearch(String query) {
    // Determine if the search should be active based on actual filters
    bool searchActive =
        query.isNotEmpty ||
        (_selectedGender != null && _selectedGender!.isNotEmpty) ||
        (_selectedBloodType != null && _selectedBloodType!.isNotEmpty);

    setState(() {
      _isSearchActive = searchActive;
    });

    // Use the provider to perform the search
    ref
        .read(donorsProvider.notifier)
        .searchDonors(
          searchQuery: query.isEmpty ? null : query,
          searchType: _searchType,
          gender: _selectedGender,
          bloodType:
              _selectedBloodType, // This will be null for "All" blood types
        );

    // Debug log
    debugPrint(
      'Search performed with: query=$query, type=$_searchType, gender=$_selectedGender, bloodType=$_selectedBloodType, active=$searchActive',
    );
  }

  // Helper method to reset all search parameters
  void _resetSearch() {
    // First clear the controller and update local state
    setState(() {
      _searchController.clear();
      _searchType = 'donor_code';
      _selectedGender = null;
      _selectedBloodType = null;
      _isSearchActive = false;
    });

    // Instead of using the provider's clearSearch method, we'll manually force a
    // complete reset by first updating the provider state, then explicitly calling fetchDonors
    final notifier = ref.read(donorsProvider.notifier);

    // Update state with explicit nulls for all search parameters
    notifier.forceResetSearch();

    // Debug log
    debugPrint('Search reset executed: all filters explicitly cleared');
  }

  // Method to launch camera for face recognition search
  Future<void> _launchCameraForFaceSearch() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? captured = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (captured == null || !mounted) {
        return;
      }

      final Map<String, dynamic> hints = {};
      if (_selectedGender != null && _selectedGender!.isNotEmpty) {
        hints['gender'] = _selectedGender;
      }
      if (_selectedBloodType != null && _selectedBloodType!.isNotEmpty) {
        hints['blood_type'] = _selectedBloodType;
      }

      var loaderVisible = false;
      if (mounted) {
        loaderVisible = true;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            content: SizedBox(
              width: 200,
              height: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Recherche en cours...', style: GoogleFonts.poppins()),
                ],
              ),
            ),
          ),
        );
      }

      try {
        await ref
            .read(donorsProvider.notifier)
            .searchDonorsByPhoto(
              File(captured.path),
              hints: hints.isEmpty ? null : hints,
            );
      } finally {
        if (mounted && loaderVisible) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }

      if (!mounted) return;

      final donorsState = ref.read(donorsProvider);
      if (donorsState.isError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              donorsState.errorMessage.isNotEmpty
                  ? donorsState.errorMessage
                  : 'Une erreur est survenue pendant la recherche',
            ),
          ),
        );
      } else if (donorsState.donors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun donneur correspondant trouvé')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${donorsState.donors.length} donneur(s) trouvé(s)'),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission caméra refusée: ${e.message ?? e.code}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de lancer la recherche: $e')),
      );
    }
  }

  // Method to validate if a string is a valid donor code
  bool _isValidDonorCode(String code) {
    // Check if code matches the format XXX-XXXX-XXXXX-XX (e.g., 9EC-2510-Z41QT-1D)
    RegExp donorCodePattern = RegExp(
      r'^[A-Z0-9]{3}-[A-Z0-9]{4}-[A-Z0-9]{5}-[A-Z0-9]{2}$',
    );
    return donorCodePattern.hasMatch(code);
  }

  // Method to format a donor code if it's valid but missing dashes
  String _formatDonorCode(String code) {
    // Remove any existing dashes
    final rawCode = code.replaceAll('-', '');

    // Check if the raw code is the right length
    if (rawCode.length == 14) {
      // Format with dashes: XXX-XXXX-XXXXX-XX
      return '${rawCode.substring(0, 3)}-${rawCode.substring(3, 7)}-${rawCode.substring(7, 12)}-${rawCode.substring(12)}';
    }

    // Return the original code if it doesn't match the expected format
    return code;
  }

  // Method to launch QR code scanner
  void _launchQRCodeScanner() {
    // Create a controller for the scanner that we can dispose later
    final controller = MobileScannerController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => WillPopScope(
        // Prevent accidental back button press from closing both screens
        onWillPop: () async {
          // Make sure to dispose controller properly
          controller.dispose();
          return true;
        },
        child: Dialog(
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Scanner le Code Donneur',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // Explicitly dispose the controller before closing the dialog
                      controller.dispose();
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ),
                body: MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;

                    // Process the first detected barcode
                    if (barcodes.isNotEmpty &&
                        barcodes.first.rawValue != null) {
                      final String scannedCode = barcodes.first.rawValue!;
                      debugPrint('QR Code detected: $scannedCode');

                      // Check if the scanned code is a valid donor code or can be formatted as one
                      String formattedCode = _formatDonorCode(
                        scannedCode.toUpperCase(),
                      );

                      if (_isValidDonorCode(formattedCode)) {
                        // Store the valid code for use after dialog is closed
                        final String validFormattedCode = formattedCode;

                        // Dispose the controller properly before closing the dialog
                        controller.dispose();

                        // Close only the dialog
                        Navigator.of(dialogContext).pop();

                        // Then update the UI and search for the donor after dialog is closed
                        setState(() {
                          // Reset all filters before setting new search
                          _selectedGender = null;
                          _selectedBloodType = null;
                          _searchType = 'donor_code';
                          _searchController.text = validFormattedCode;
                          _isSearchActive = true; // Set search as active
                        });

                        // Use a single search call instead of clearing and then searching
                        ref
                            .read(donorsProvider.notifier)
                            .searchDonors(
                              searchQuery: validFormattedCode,
                              searchType:
                                  'donor_code', // Explicitly set search type to donor_code
                              gender: null,
                              bloodType: null,
                            );

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Code donneur scanné avec succès',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        // Invalid donor code - show error
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Code QR invalide. Format attendu: XXX-XXXX-XXXXX-XX',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      // Ensure controller is disposed if dialog is closed by tapping outside
      controller.dispose();
    });
  }

  // Helper method to show search help dialog
  void _showSearchHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Comment rechercher un donneur',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                'Recherche par nom',
                'Tapez le nom complet ou partiel du donneur.',
                Icons.person,
              ),
              const Divider(),
              _buildHelpItem(
                'Recherche par téléphone',
                'Entrez le numéro de téléphone complet ou partiel.',
                Icons.phone,
              ),
              const Divider(),
              _buildHelpItem(
                'Recherche par code donneur',
                'Entrez le code unique du donneur pour une recherche précise.',
                Icons.badge,
              ),
              const Divider(),
              _buildHelpItem(
                'Filtre par genre',
                'Utilisez les options Homme ou Femme pour filtrer par genre.',
                Icons.people,
              ),
              const Divider(),
              _buildHelpItem(
                'Filtre par groupe sanguin',
                'Sélectionnez un groupe sanguin pour affiner les résultats.',
                Icons.bloodtype,
              ),
              const Divider(),
              _buildHelpItem(
                'Recherche par photo',
                'Utilisez l\'icône appareil photo pour rechercher par reconnaissance faciale (démo).',
                Icons.camera_alt,
              ),
              const Divider(),
              _buildHelpItem(
                'Scanner un code donneur',
                'Utilisez l\'icône scanner pour lire un QR code et rechercher rapidement un donneur.',
                Icons.qr_code_scanner,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.red, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get appropriate hint text based on search type
  String _getSearchHintText() {
    switch (_searchType) {
      case 'name':
        return 'Entrez le nom du donneur...';
      case 'phone':
        return 'Entrez le numéro de téléphone...';
      case 'donor_code':
        return 'Format: XXX-XXXX-XXXXX-XX (ex: 9EC-2510-Z41QT-1D)';
      case 'photo':
        return 'Cliquez sur l\'icône appareil photo...';
      default:
        return 'Rechercher un donneur...';
    }
  }

  // Helper method to get appropriate keyboard type based on search type
  TextInputType _getKeyboardType() {
    switch (_searchType) {
      case 'phone':
        return TextInputType.phone;
      case 'donor_code':
        return TextInputType.text;
      case 'name':
        return TextInputType.name;
      default:
        return TextInputType.text;
    }
  }

  // Helper method to get appropriate input formatters based on search type
  List<TextInputFormatter>? _getInputFormatters() {
    switch (_searchType) {
      case 'phone':
        // Format phone numbers
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
          // Format phone numbers as XX-XX-XX-XX-XX
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = newValue.text;
            if (text.isEmpty) return newValue;

            // Add separators
            String formattedText = '';
            for (int i = 0; i < text.length; i++) {
              if (i == 2 || i == 4 || i == 6 || i == 8) {
                formattedText += '-';
              }
              formattedText += text[i];
            }

            return TextEditingValue(
              text: formattedText.length > 14
                  ? formattedText.substring(0, 14)
                  : formattedText,
              selection: TextSelection.collapsed(
                offset: formattedText.length > 14 ? 14 : formattedText.length,
              ),
            );
          }),
        ];
      case 'donor_code':
        // For donor code, format as 9EC-2510-Z41QT-1D
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
          LengthLimitingTextInputFormatter(17), // Max length including dashes
          // Upper case formatter and format with dashes
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = newValue.text.toUpperCase().replaceAll('-', '');
            if (text.isEmpty) return newValue;

            // Format with dashes: XXX-XXXX-XXXXX-XX
            String formattedText = '';
            for (int i = 0; i < text.length; i++) {
              if (i == 3 || i == 7 || i == 12) {
                formattedText += '-';
              }
              formattedText += text[i];
            }

            return TextEditingValue(
              text: formattedText,
              selection: TextSelection.collapsed(offset: formattedText.length),
            );
          }),
        ];
      default:
        return null;
    }
  }
}
