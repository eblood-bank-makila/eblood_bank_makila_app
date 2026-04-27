
import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:eblood_bank_mak_app/apps/widgets/advertisement/AdvertisementCarousel.dart';
import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_provider.dart';
import 'package:eblood_bank_mak_app/core/rbac/services/rbac_guard.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BanqueCtrl.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BloodBagOrderStepperPage.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/recherchePoche/RecherchePochePage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/notification/NotificationPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

class Banquepage extends ConsumerStatefulWidget {
  //final List<DatumNotificationModel> notification;
  const Banquepage({super.key});

  @override
  ConsumerState createState() => _BanquepageState();
}

class _BanquepageState extends ConsumerState<Banquepage> {
  final TextEditingController searchController = TextEditingController();

  bool _hasFlag(String flag) =>
      ref.read(rbacProvider.notifier).hasMenuFlag(flag);

  @override
  void initState() {
    super.initState();
    // Entry guard: accessible to hospital users with the top-level
    // blood_bags app flag.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_hospital_blood_bags_app',
    );
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

              // Content - no rounded corners, transparent background
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
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
    return Padding(
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
                    Iconsax.box,
                    color: ColorPages.COLOR_PRINCIPAL,
                    size: 24,
                  ),
                ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'available_blood_bags'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                      Text(
                        'find_blood_quickly'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Notification Button
              Container(
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_BLANCHE.withValues(alpha: 0.4),
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
                      icon: Icon(
                        Iconsax.notification,
                        color: ColorPages.COLOR_PRINCIPAL,
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
                          color: ColorPages.COLOR_PRINCIPAL,
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
                    builder: (context) => Recherchepage(
                      query: searchController.text,
                      isModal: true, // Opened as modal from first tab
                    ),
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
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                        'search_blood_bag_placeholder'.tr,
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Advertisement Carousel - Fetches online advertisements
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: const AdvertisementCarousel(
              targetAudience: 'patient',
              height: 180,
              autoPlay: true,
              showIndicators: true,
              useMockData: false, // Using real API
            ),
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
                      'available_blood_bags'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'total_stock_available'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                // TextButton(
                //   onPressed: () {
                //     // Add "voir tout" functionality if needed
                //   },
                //   child: Text(
                //     'see_all'.tr,
                //     style: GoogleFonts.ubuntu(
                //       color: ColorPages.COLOR_PRINCIPAL,
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),
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
    );
  }

  Widget _buildBanksList(dynamic state) {
    if (state.isLoading) {
      return _buildModernLoading();
    }

    if (state.banques.isEmpty) {
      return _buildEmptyState();
    }

    // Aggregate inventory data from all blood banks
    final aggregatedData = _aggregateInventoryData(state.banques);

    return _buildAggregatedInventoryCard(aggregatedData);
  }

  /// Aggregate inventory data from all blood banks
  Map<String, dynamic> _aggregateInventoryData(List<dynamic> banques) {
    int totalBags = 0;
    Map<String, int> bloodTypeBagCount = {};
    Map<String, int> bloodTypeBankCount = {};

    for (var banque in banques) {
      final inventorySummary = banque.inventorySummary;
      if (inventorySummary != null) {
        final bankTotalBags = (inventorySummary['total_bags'] ?? 0) as int;
        totalBags += bankTotalBags;

        // Get blood types available in this bank
        final bloodTypes = (inventorySummary['available_blood_types'] as List?)?.cast<String>() ?? [];

        if (bloodTypes.isNotEmpty && bankTotalBags > 0) {
          // Estimate bags per blood type by dividing total bags by number of types
          final estimatedBagsPerType = (bankTotalBags / bloodTypes.length).round();

          for (var bloodType in bloodTypes) {
            // Accumulate estimated bags for each blood type
            bloodTypeBagCount[bloodType] = (bloodTypeBagCount[bloodType] ?? 0) + estimatedBagsPerType;
            // Track how many banks have this blood type
            bloodTypeBankCount[bloodType] = (bloodTypeBankCount[bloodType] ?? 0) + 1;
          }
        }
      }
    }

    return {
      'total_bags': totalBags,
      'blood_type_bag_count': bloodTypeBagCount,
      'blood_type_bank_count': bloodTypeBankCount,
      'total_banks': banques.length,
    };
  }

  /// Build aggregated inventory card showing combined data from all banks
  Widget _buildAggregatedInventoryCard(Map<String, dynamic> aggregatedData) {
    final totalBags = aggregatedData['total_bags'] ?? 0;
    final bloodTypeBagCount = aggregatedData['blood_type_bag_count'] as Map<String, int>;
    final totalBanks = aggregatedData['total_banks'] ?? 0;

    if (totalBags == 0) {
      return _buildEmptyState();
    }

    // Sort blood types by count (descending)
    final sortedBloodTypes = bloodTypeBagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with total bags
            Row(
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
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'bags_available'.trParams({'count': totalBags.toString()}),
                        style: GoogleFonts.ubuntu(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'in_blood_banks'.trParams({'count': totalBanks.toString()}),
                        style: GoogleFonts.ubuntu(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Divider
            Divider(
              color: Colors.grey.shade200,
              thickness: 1,
            ),

            const SizedBox(height: 20),

            // Blood types section
            Text(
              'availability_by_blood_type'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            // Blood type grid with bag counts
            if (sortedBloodTypes.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: sortedBloodTypes.map((entry) {
                  final bloodType = entry.key;
                  final bagCount = entry.value;

                  return GestureDetector(
                    onTap: () => _showBloodBagOptionsDialog(context, bloodType, bagCount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade50,
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Blood type
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bloodType,
                              style: GoogleFonts.ubuntu(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Bag count
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$bagCount',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ColorPages.COLOR_PRINCIPAL,
                                ),
                              ),
                              Text(
                                bagCount == 1 ? 'bag'.tr : 'bags'.tr,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'no_blood_type_available'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 13,
                        color: Colors.grey.shade600,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Iconsax.bank,
              size: 40,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'no_bank_available'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'pull_down_to_refresh'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade600,
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
          message: 'loading_blood_banks'.tr,
        ),
      ),
    );
  }

  /// Show beautiful dialog with options when clicking on a blood bag
  void _showBloodBagOptionsDialog(BuildContext context, String bloodType, int bagCount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with blood type badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorPages.COLOR_PRINCIPAL,
                        Colors.red.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.health,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          Text(
                            bloodType,
                            style: GoogleFonts.ubuntu(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$bagCount ${bagCount == 1 ? 'bag'.tr : 'bags'.tr}',
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'how_would_you_like_to_proceed'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Option 1: View blood bank address
                _buildDialogOption(
                  context: context,
                  icon: Iconsax.location,
                  iconColor: Colors.blue,
                  title: "view_blood_bank_address".tr,
                  subtitle: "address_shown_after_payment".tr,
                  onTap: () {
                    Navigator.pop(context);
                    _showBloodBankAddresses(context, bloodType);
                  },
                ),

                const SizedBox(height: 16),

                // Option 2: Order online
                _buildDialogOption(
                  context: context,
                  icon: Iconsax.shopping_cart,
                  iconColor: ColorPages.COLOR_PRINCIPAL,
                  title: "order_online".tr,
                  subtitle: "order_and_deliver_to_hospital".tr,
                  onTap: () {
                    Navigator.pop(context);
                    _orderOnline(context, bloodType);
                  },
                ),

                const SizedBox(height: 20),

                // Close button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'cancel'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a dialog option card
  Widget _buildDialogOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ubuntu(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Show blood bank addresses for the selected blood type
  void _showBloodBankAddresses(BuildContext context, String bloodType) {
    if (!_hasFlag('flutter_apps_eblood_bank_hosp_blood_bag_order')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('access_denied'.tr)),
      );
      return;
    }
    final state = ref.read(banqueCtrlProvider);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BloodBagOrderStepperPage(
          bloodType: bloodType,
          bloodBanks: state.banques,
          isViewAddressMode: true,
        ),
      ),
    );
  }

  /// Order blood online
  void _orderOnline(BuildContext context, String bloodType) {
    if (!_hasFlag('flutter_apps_eblood_bank_hosp_blood_bag_order')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('access_denied'.tr)),
      );
      return;
    }
    final state = ref.read(banqueCtrlProvider);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BloodBagOrderStepperPage(
          bloodType: bloodType,
          bloodBanks: state.banques,
          isViewAddressMode: false,
        ),
      ),
    );
  }
}
