import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:eblood_bank_mak_app/apps/config/api/ApiConfig.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_provider.dart';
import 'package:eblood_bank_mak_app/core/rbac/services/rbac_guard.dart';
import 'package:eblood_bank_mak_app/orders/ui/pages/checkout/pages/PaymentStatusPage.dart';
import 'package:eblood_bank_mak_app/orders/ui/pages/checkout/widgets/PhoneNumberBottomSheet.dart';
import 'package:eblood_bank_mak_app/payments/business/service/LokotroPayCheckoutService.dart';
import 'package:eblood_bank_mak_app/payments/business/service/PaymentApi.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/poche/PocheModel.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/HospitalBagPurchaseFlow.dart';
import 'package:eblood_bank_mak_app/stock_management/ui/pages/banque/BloodBankAddressSuccessPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Stepper page for the logged-in hospital to buy a blood bag or unlock a
/// blood bank's address.
///
/// Order mode ("Commander en ligne"):
///   Step 1: Select nearby blood bank
///   Step 2: Select the blood bag
///   Step 3: Confirm (server quote) + choose payment method
///   Step 4: Payment processing
/// Address mode ("Adresses des banques"):
///   Step 1: Select nearby blood bank
///   Step 2: Confirm the address-access fee + choose payment method
///   Step 3: Payment processing
///
/// The data/payment chain deliberately mirrors the welcome-QR (visitor)
/// flow — `blood-bags/search-simple`, `/payments/initiate/payment`
/// (address access, 10% of the bag price), `visitor/blood-bag/purchase-quote`
/// + `visitor/blood-bag/initiate-purchase` (single-bag delivery to this
/// hospital), the lokotro SDK, `/payments/confirm-collect`, then polling
/// `/payments/get-payment-status`. Those routes are the ones the backend
/// whitelists; the former `/eblood-connect/blood-bags`, `/pricing/*` and
/// `blood-bank-address-request/check-payment-status` calls are granted to
/// no profile and 403'd as "Client error" for every hospital user.
class BloodBagOrderStepperPage extends ConsumerStatefulWidget {
  final String bloodType;
  final List<BanqueModele> bloodBanks;
  final bool isViewAddressMode; // true for "voir l'adresse", false for "commander en ligne"

  const BloodBagOrderStepperPage({
    Key? key,
    required this.bloodType,
    required this.bloodBanks,
    this.isViewAddressMode = false,
  }) : super(key: key);

  @override
  ConsumerState<BloodBagOrderStepperPage> createState() => _BloodBagOrderStepperPageState();
}

class _BloodBagOrderStepperPageState extends ConsumerState<BloodBagOrderStepperPage> {
  static const String _methodMobileMoney = 'mobile_money';
  static const String _methodCard = 'card';

  int _currentStep = 0;
  BanqueModele? _selectedBloodBank;
  bool _isLoading = false;
  String? _errorMessage;

  // Bags of the selected bank matching widget.bloodType (from search-simple).
  List<PocheModel> _bloodBags = [];
  PocheModel? _selectedBloodBag;

  // Logged-in hospital (destination of the delivery), resolved from the
  // stored profiles → /eblood/hospitals/list. Null until resolved.
  String? _hospitalId;

  // Server-authoritative delivery quote (bag + eBlood fee + platform fee +
  // km delivery fee) for order mode. Null (quote failed) falls back to the
  // bag price for display; the backend still charges the real total.
  VisitorPurchaseQuote? _purchaseQuote;
  bool _isLoadingQuote = false;

  String _paymentMethod = _methodMobileMoney;
  bool _isProcessingPayment = false;

  // Payment step: customer_reference of the intent being polled.
  String? _systemRef;

  int get _confirmStep => widget.isViewAddressMode ? 1 : 2;
  int get _paymentStep => widget.isViewAddressMode ? 2 : 3;

  bool _hasFlag(String flag) =>
      ref.read(rbacProvider.notifier).hasMenuFlag(flag);

  @override
  void initState() {
    super.initState();
    // RBAC entry guard.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_hosp_blood_bag_order',
    );
    // Resolve the hospital early so the confirm step can quote the km leg.
    _resolveHospitalId();
  }

  /// Hospital of the logged-in staff: stored profile org → hospitals/list.
  /// Cached in [_hospitalId]; returns the cached value on later calls.
  Future<String?> _resolveHospitalId() async {
    if (_hospitalId != null && _hospitalId!.isNotEmpty) return _hospitalId;
    try {
      final storage = GetStorage();
      final dynamic storedProfiles = storage.read('user_profiles') ?? storage.read('user_profils');

      String? sysOrgId;
      if (storedProfiles is List) {
        for (final p in storedProfiles) {
          if (p is Map) {
            final candidate = (p['sys_organization_id'] ?? p['organization_id'] ?? p['org_id'])?.toString();
            if (candidate != null && candidate.isNotEmpty) {
              sysOrgId = candidate;
              break;
            }
          }
        }
      } else if (storedProfiles is Map) {
        sysOrgId = (storedProfiles['sys_organization_id'] ?? storedProfiles['organization_id'])?.toString();
      }

      if (sysOrgId == null || sysOrgId.isEmpty) {
        final userData = storage.read('user_data');
        if (userData is Map) {
          sysOrgId = (userData['sys_organization_id'] ?? userData['organization_id'])?.toString();
        }
      }

      if (sysOrgId == null || sysOrgId.isEmpty) return null;

      // Fetch hospital by organization ID
      final res = await getWithDio(
        ApiConfig.hospitalsList,
        queryParams: {
          'filter__sys_organization_id': sysOrgId,
          'limit': 1,
          'page': 0,
        },
      );

      if (res.success) {
        final data = res.data;
        if (data is Map && data['data'] is List && (data['data'] as List).isNotEmpty) {
          final hospital = (data['data'] as List).first;
          final id = (hospital['_id'] ?? hospital['id'])?.toString();
          debugPrint("🏥 Got hospital ID from user profile: $id");
          if (id != null && id.isNotEmpty && mounted) {
            setState(() => _hospitalId = id);
          }
          return id;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error getting hospital ID from profiles: $e");
      return null;
    }
  }

  /// Get filtered blood banks that have the selected blood type
  List<BanqueModele> get _filteredBloodBanks {
    return widget.bloodBanks.where((bank) {
      final inventorySummary = bank.inventorySummary;
      if (inventorySummary == null) return false;

      final availableBloodTypes = (inventorySummary['available_blood_types'] as List?)?.cast<String>() ?? [];
      return availableBloodTypes.contains(widget.bloodType);
    }).toList()
      ..sort((a, b) {
        // Sort by distance (closest first)
        final distanceA = double.tryParse(a.distance ?? '999') ?? 999;
        final distanceB = double.tryParse(b.distance ?? '999') ?? 999;
        return distanceA.compareTo(distanceB);
      });
  }

  String get _currencySymbol => _selectedBloodBag?.currencySymbol ?? '\$';

  String get _currencyCode =>
      (_selectedBloodBag?.currencyCode ?? 'USD').toUpperCase();

  /// Address-access fee (10% of the bag price), as the visitor flow prices it.
  double get _addressAccessFee =>
      HospitalBagPurchaseFlow.addressAccessFeeCents(_selectedBloodBag?.price ?? 0) / 100.0;

  /// Amount shown on the pay button / total row.
  double get _displayTotal {
    if (widget.isViewAddressMode) return _addressAccessFee;
    return _purchaseQuote?.total ?? (_selectedBloodBag?.price ?? 0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isViewAddressMode ? 'blood_bank_addresses'.tr : 'order_online'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stepper header
          _buildStepperHeader(),

          // Content
          Expanded(
            child: _buildStepContent(),
          ),
        ],
      ),
    );
  }

  /// Build stepper header with progress indicator
  Widget _buildStepperHeader() {
    // For view address mode: only 3 steps (bank, confirm, payment)
    // For order mode: 4 steps (bank, bag, confirm, payment)
    if (widget.isViewAddressMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStepIndicator(0, 'bank'.tr, Iconsax.bank),
            _buildStepConnector(0),
            _buildStepIndicator(1, 'confirm'.tr, Iconsax.tick_circle),
            _buildStepConnector(1),
            _buildStepIndicator(2, 'payment'.tr, Iconsax.wallet_check),
          ],
        ),
      );
    }

    // Order mode: 4 steps
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, 'bank'.tr, Iconsax.bank),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'bag'.tr, Iconsax.box),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'confirm'.tr, Iconsax.tick_circle),
          _buildStepConnector(2),
          _buildStepIndicator(3, 'payment'.tr, Iconsax.wallet_check),
        ],
      ),
    );
  }

  /// Build step indicator circle
  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isCompleted || isActive
                  ? ColorPages.COLOR_PRINCIPAL
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isCompleted ? Iconsax.chart_success : icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build step connector line
  Widget _buildStepConnector(int step) {
    final isCompleted = _currentStep > step;

    return Container(
      height: 2,
      width: 30,
      margin: const EdgeInsets.only(bottom: 30),
      color: isCompleted ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade300,
    );
  }

  /// Build step content based on current step
  Widget _buildStepContent() {
    if (widget.isViewAddressMode) {
      // View address mode: 3 steps (bank, confirm fee, payment)
      switch (_currentStep) {
        case 0:
          return _buildStep1SelectBloodBank();
        case 1:
          return _buildConfirmStep();
        case 2:
          return _buildStep4PaymentProcessing();
        default:
          return Container();
      }
    }

    // Order mode: 4 steps (bank, bag, confirm, payment)
    switch (_currentStep) {
      case 0:
        return _buildStep1SelectBloodBank();
      case 1:
        return _buildStep2SelectBloodBag();
      case 2:
        return _buildConfirmStep();
      case 3:
        return _buildStep4PaymentProcessing();
      default:
        return Container();
    }
  }

  /// Step 1: Select nearby blood bank
  Widget _buildStep1SelectBloodBank() {
    final filteredBanks = _filteredBloodBanks;

    if (filteredBanks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Iconsax.health,
                      color: ColorPages.COLOR_PRINCIPAL,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'blood_type'.tr} ${widget.bloodType}',
                          style: GoogleFonts.ubuntu(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          filteredBanks.length == 1
                              ? 'bank_available_singular'.trParams({'count': filteredBanks.length.toString()})
                              : 'bank_available_plural'.trParams({'count': filteredBanks.length.toString()}),
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
            ],
          ),
        ),

        // List of blood banks
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBanks.length,
            itemBuilder: (context, index) {
              final bank = filteredBanks[index];
              return _buildBloodBankCard(bank);
            },
          ),
        ),
      ],
    );
  }

  /// Build blood bank card
  Widget _buildBloodBankCard(BanqueModele bank) {
    final distance = double.tryParse(bank.distance ?? '0') ?? 0;
    final distanceText = distance < 1
        ? '${(distance * 1000).toInt()} m'
        : '${distance.toStringAsFixed(1)} km';

    // Estimate price (default $10 per bag)
    final pricePerBag = 10.0;

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () => _selectBloodBank(bank),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedBloodBank?.id == bank.id
                  ? ColorPages.COLOR_PRINCIPAL
                  : Colors.grey.shade200,
              width: _selectedBloodBank?.id == bank.id ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Blood type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.bloodType,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Bank info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Distance
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'distance_from_you'.trParams({'distance': distanceText}),
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Price
                    Row(
                      children: [
                        Icon(
                          Iconsax.dollar_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'price_per_bag'.trParams({'price': '\$${pricePerBag.toStringAsFixed(0)}'}),
                          style: GoogleFonts.ubuntu(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow or checkmark
              Icon(
                _selectedBloodBank?.id == bank.id
                    ? Iconsax.tick_circle5
                    : Iconsax.arrow_right_3,
                color: _selectedBloodBank?.id == bank.id
                    ? ColorPages.COLOR_PRINCIPAL
                    : Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Select blood bank and load its bags (both modes need a bag: the order
  /// buys it, the address fee is priced off it).
  void _selectBloodBank(BanqueModele bank) {
    setState(() {
      _selectedBloodBank = bank;
      _selectedBloodBag = null;
      _purchaseQuote = null;
    });
    _fetchBloodBags(bank);
  }

  /// Fetch the bank's bags of the requested blood type via the
  /// whitelisted search-simple route (same rows the old
  /// `/eblood-connect/blood-bags` returned, which no profile is granted).
  Future<void> _fetchBloodBags(BanqueModele bank) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentStep = 1; // Move to step 2 (bag list / address fee)
    });

    try {
      debugPrint('🩸 Fetching ${widget.bloodType} blood bags for bank: ${bank.id}');

      final bags = await HospitalBagPurchaseFlow.fetchBankBags(
        bloodBankId: bank.id,
        bloodType: widget.bloodType,
      );

      debugPrint('✅ ${bags.length} bags of type ${widget.bloodType} at ${bank.blood_bank_name}');

      if (!mounted) return;
      setState(() {
        _bloodBags = bags;
        // Address mode prices the fee off one bag; the address unlocked is
        // the bank's, so the first available bag is enough.
        _selectedBloodBag = widget.isViewAddressMode && bags.isNotEmpty ? bags.first : null;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching blood bags: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _errorMessage = '${'error_loading_bags'.tr}: $e';
        _isLoading = false;
      });
    }
  }

  /// Order mode: pick the bag to buy and move to the confirmation step.
  void _selectBloodBag(PocheModel bag) {
    setState(() {
      _selectedBloodBag = bag;
      _purchaseQuote = null;
      _currentStep = _confirmStep;
    });
    _fetchPurchaseQuote();
  }

  /// Server-side price breakdown for the delivery purchase (bag + eBlood
  /// fee + platform fee + km leg to this hospital). Read-only; the charge
  /// is recomputed by initiate-purchase with the same helpers.
  Future<void> _fetchPurchaseQuote() async {
    final bag = _selectedBloodBag;
    if (widget.isViewAddressMode || bag == null) return;
    if (!mounted) return;
    setState(() => _isLoadingQuote = true);
    final hospitalId = await _resolveHospitalId();
    final quote = await PaymentApi.getVisitorDeliveryQuote(
      bloodBagId: bag.bloodBagInfo.id,
      hospitalId: hospitalId,
    );
    debugPrint(quote != null
        ? '💰 Delivery quote: total=${quote.total} km_fee=${quote.kmFee} distance=${quote.distanceKm}'
        : '⚠️ Delivery quote unavailable — falling back to the bag price');
    if (!mounted) return;
    setState(() {
      _purchaseQuote = quote;
      _isLoadingQuote = false;
    });
  }

  /// Step 2 (order mode): pick the blood bag
  Widget _buildStep2SelectBloodBag() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: AppSpinner.bloodDrop(
            size: 80,
            showMessage: true,
            message: 'loading_available_bags'.tr,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_bloodBags.isEmpty) {
      return _buildNoBloodBagsState();
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Iconsax.box,
                  color: ColorPages.COLOR_PRINCIPAL,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'select_blood_bag'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _bloodBags.length == 1
                          ? 'bag_available_singular'.trParams({'count': _bloodBags.length.toString()})
                          : 'bag_available_plural'.trParams({'count': _bloodBags.length.toString()}),
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

        // Bag list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _bloodBags.length,
            itemBuilder: (context, index) => _buildBloodBagCard(_bloodBags[index]),
          ),
        ),
      ],
    );
  }

  /// Build blood bag card (order mode step 2)
  Widget _buildBloodBagCard(PocheModel bag) {
    final isSelected = _selectedBloodBag?.bloodBagInfo.id == bag.bloodBagInfo.id;
    final volume = bag.bloodBagInfo.bloodVolumeInfo.bloodVolumeName;
    final symbol = bag.currencySymbol ?? '\$';

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () => _selectBloodBag(bag),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.bloodType,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'bag'.tr} ${bag.bloodBagInfo.identifier}',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Iconsax.dollar_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'price_per_bag'.trParams({'price': '$symbol${bag.price}'}),
                          style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (volume.isNotEmpty && volume != 'N/A') '$volume ml',
                        if (bag.daysUntilExpiry != null)
                          'bag_expires_in_days'.trParams({'days': bag.daysUntilExpiry.toString()}),
                      ].join(' · '),
                      style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Iconsax.tick_circle5 : Iconsax.arrow_right_3,
                color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirm step: summary + payment method + pay (both modes)
  Widget _buildConfirmStep() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: AppSpinner.bloodDrop(
            size: 80,
            showMessage: true,
            message: widget.isViewAddressMode ? 'loading_prices'.tr : 'preparing_order'.tr,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_selectedBloodBag == null) {
      return _buildNoBloodBagsState();
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.isViewAddressMode ? Iconsax.wallet : Iconsax.tick_circle,
                  color: ColorPages.COLOR_PRINCIPAL,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isViewAddressMode ? 'select_payment_option'.tr : 'confirm_order'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'verify_and_pay'.tr,
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

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isViewAddressMode) ...[
                  // Info message (don't show blood bank details until payment succeeds)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.info_circle,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'address_info_after_payment'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                _buildOrderSummaryCard(),

                const SizedBox(height: 20),

                _buildPaymentMethodSelector(),

                const SizedBox(height: 20),

                _buildPayButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.search_status,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_bank_available'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'no_bank_has_blood_type'.trParams({'bloodType': widget.bloodType}),
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.close_circle,
                size: 50,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'error'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                      _errorMessage = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPages.COLOR_PRINCIPAL,
                    side: BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'back'.tr,
                    style: GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedBloodBank != null) {
                      _fetchBloodBags(_selectedBloodBank!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'retry'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build no blood bags state
  Widget _buildNoBloodBagsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.box_remove,
                size: 50,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_bags_available'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'bank_no_bags_in_stock'.trParams({'bloodType': widget.bloodType}),
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                  _errorMessage = null;
                });
              },
              icon: const Icon(Iconsax.arrow_left),
              label: Text('back'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build order summary card
  Widget _buildOrderSummaryCard() {
    final bag = _selectedBloodBag!;
    final currencySymbol = _currencySymbol;

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'order_summary'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // Blood type
            _buildSummaryRow(
              icon: Iconsax.health,
              label: 'blood_type'.tr,
              value: widget.bloodType,
              valueColor: ColorPages.COLOR_PRINCIPAL,
            ),

            const SizedBox(height: 12),

            // Blood bank
            _buildSummaryRow(
              icon: Iconsax.bank,
              label: 'blood_bank'.tr,
              value: _selectedBloodBank?.blood_bank_name ?? '',
            ),

            if (!widget.isViewAddressMode) ...[
              const SizedBox(height: 12),

              // Bag
              _buildSummaryRow(
                icon: Iconsax.box,
                label: 'bag'.tr,
                value: bag.bloodBagInfo.identifier,
              ),
            ],

            const SizedBox(height: 12),

            // Price per unit
            _buildSummaryRow(
              icon: Iconsax.dollar_circle,
              label: 'unit_price'.tr,
              value: '$currencySymbol${bag.price}',
            ),

            if (widget.isViewAddressMode) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                icon: Iconsax.location,
                label: '${'address_access_fee'.tr} (${'address_fee_explainer'.tr})',
                value: '$currencySymbol${_addressAccessFee.toStringAsFixed(2)}',
              ),
            ],

            // Server-side fees — only once the quote has loaded. The km row
            // only shows when the distance ladder actually priced a fee.
            if (!widget.isViewAddressMode && _purchaseQuote != null) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                icon: Iconsax.wallet_3,
                label: 'eblood_fee_label'.tr,
                value:
                    '$currencySymbol${_purchaseQuote!.ebloodFee.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                icon: Iconsax.wallet,
                label: 'service_fees'.tr,
                value:
                    '$currencySymbol${_purchaseQuote!.platformFee.toStringAsFixed(2)}',
              ),
              if (_purchaseQuote!.kmFee > 0) ...[
                const SizedBox(height: 12),
                _buildSummaryRow(
                  icon: Iconsax.routing,
                  label: _purchaseQuote!.distanceKm != null
                      ? 'km_delivery_fee_with_distance'.trParams({
                          'distance':
                              _purchaseQuote!.distanceKm!.toStringAsFixed(1),
                        })
                      : 'km_delivery_fee'.tr,
                  value:
                      '$currencySymbol${_purchaseQuote!.kmFee.toStringAsFixed(2)}',
                ),
              ],
            ],

            const SizedBox(height: 20),

            // Divider
            Divider(color: Colors.grey.shade300),

            const SizedBox(height: 20),

            // Total — the server quote (fees included) for a delivery, the
            // 10% fee for an address; the bag price while the quote loads.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'total'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                _isLoadingQuote
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      )
                    : Text(
                        '$currencySymbol${_displayTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.ubuntu(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build summary row
  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.ubuntu(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Payment method — mobile money (phone asked before checkout) or card,
  /// the two online methods the visitor payment page offers.
  Widget _buildPaymentMethodSelector() {
    return FadeInUp(
      duration: const Duration(milliseconds: 350),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'payment_method'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPaymentMethodTile(
                  id: _methodMobileMoney,
                  label: 'mobile_money'.tr,
                  icon: Iconsax.mobile,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentMethodTile(
                  id: _methodCard,
                  label: 'card_payment'.tr,
                  icon: Iconsax.card,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == id;
    return GestureDetector(
      onTap: _isProcessingPayment ? null : () => setState(() => _paymentMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade600,
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.ubuntu(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pay button (amount = quote total / address fee)
  Widget _buildPayButton() {
    final canPay = !_isProcessingPayment && !_isLoadingQuote && _selectedBloodBag != null;
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: ElevatedButton(
        onPressed: canPay ? _startPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPages.COLOR_PRINCIPAL,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessingPayment)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(Iconsax.lock, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              _isProcessingPayment
                  ? 'processing'.tr
                  : 'pay_amount'.trParams({
                      'amount': '$_currencySymbol${_displayTotal.toStringAsFixed(2)}',
                    }),
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 4: Payment processing with embedded PaymentStatusPage
  Widget _buildStep4PaymentProcessing() {
    if (_systemRef == null) {
      // Still submitting payment
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'submitting_payment'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'please_wait'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Payment collected by the SDK — poll /payments/get-payment-status (the
    // canonical server state) until it is terminal.
    String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.30.132:3101/eblood-hstdapi/v1';

    return PaymentStatusPage(
      systemRef: _systemRef!,
      baseUrl: baseUrl,
      onPaymentResult: ({
        required int page,
        required String title,
        required String message,
        required bool paymentSucceed,
      }) {
        debugPrint("💳 Payment result: $paymentSucceed - $message");
        if (paymentSucceed && mounted) {
          if (widget.isViewAddressMode && _selectedBloodBank != null) {
            // For view address mode, navigate to blood bank address details page
            // This callback is called after the confetti screen (2 seconds delay in PaymentStatusPage)
            debugPrint("🎯 View address mode: Navigating to blood bank details page");
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => BloodBankAddressSuccessPage(
                  bloodBank: _selectedBloodBank!,
                ),
              ),
            );
          } else {
            // For order mode, show success message and navigate back
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${'payment_successful'.tr}! $message'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // Navigate back to home
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (!paymentSucceed && mounted) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'payment_failed'.tr}: $message'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  /// Show phone number bottom sheet and return the phone number
  Future<String?> _showPhoneNumberBottomSheet() async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => PhoneNumberBottomSheet(
        onPhoneNumberSubmitted: (phoneNumber) {
          Navigator.of(context).pop(phoneNumber);
        },
      ),
    );
  }

  void _showSnack(String text, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  /// PHASE 1 create the intent + gateway session, PHASE 2 launch the lokotro
  /// SDK, PHASE 3 confirm-collect in the background and poll the server
  /// state on the payment step — the visitor payment page's `_processPayment`.
  Future<void> _startPayment() async {
    final bag = _selectedBloodBag;
    if (bag == null || _isProcessingPayment) return;

    // Checkout-level RBAC gate. The page's entry guard checks the
    // broader "order" flag; the final checkout requires a stricter
    // checkout sub_menu flag.
    if (!_hasFlag('flutter_apps_eblood_bank_hosp_blood_bag_checkout')) {
      _showSnack('access_denied'.tr);
      return;
    }

    // Mobile money: collect the phone number up-front (prefilled into the SDK).
    String? momoPhone;
    if (_paymentMethod == _methodMobileMoney) {
      final typed = await _showPhoneNumberBottomSheet();
      momoPhone = HospitalBagPurchaseFlow.normalizeMomoPhone(typed ?? '');
      if (momoPhone == null) {
        debugPrint('❌ Payment cancelled: no phone number provided');
        return;
      }
    }
    if (!mounted) return;

    setState(() => _isProcessingPayment = true);

    try {
      final PaymentInitiateResult initiate;
      if (widget.isViewAddressMode) {
        // Address access: 10% of the bag price, entity = the bag. The
        // backend rejects amount_cents < 1, so an unpriced bag cannot be
        // unlocked — say so instead of surfacing a 422.
        final feeCents = HospitalBagPurchaseFlow.addressAccessFeeCents(bag.price);
        if (feeCents < 1) {
          setState(() => _isProcessingPayment = false);
          _showSnack('payment_error'.tr);
          return;
        }
        debugPrint('💳 POST /payments/initiate/payment (address_access) for bag ${bag.bloodBagInfo.id}');
        initiate = await PaymentApi.initiate(
          purpose: 'address_access',
          entityId: bag.bloodBagInfo.id,
          amountCents: feeCents,
          currency: _currencyCode,
        );
      } else {
        // Delivery purchase of this bag to the logged-in hospital. The
        // backend resolves the price server-side and dispatches the
        // courier on the gateway's SUCCEEDED webhook.
        final hospitalId = await _resolveHospitalId();
        if (hospitalId == null || hospitalId.isEmpty) {
          setState(() => _isProcessingPayment = false);
          _showSnack('hospital_not_identified'.tr);
          return;
        }
        debugPrint('💳 POST /eblood-connect/visitor/blood-bag/initiate-purchase for bag ${bag.bloodBagInfo.id} → hospital $hospitalId');
        initiate = await PaymentApi.initiateVisitorDeliveryPurchase(
          bloodBagId: bag.bloodBagInfo.id,
          hospitalId: hospitalId,
          phoneNumber: momoPhone,
        );
      }

      if (!mounted) return;

      if (!initiate.isSuccess || initiate.customerReference == null) {
        setState(() => _isProcessingPayment = false);
        _showSnack(initiate.errorMessage ?? 'payment_error'.tr);
        return;
      }

      final customerRef = initiate.customerReference!;

      // PHASE 2 — the lokotro_pay checkout collects the money.
      final result = await LokotroPayCheckoutService.launchFromInitiate(
        context,
        initiate: initiate,
        paymentMethod: _paymentMethod == _methodMobileMoney ? _methodMobileMoney : _methodCard,
        phoneNumberOverride: momoPhone,
        mobileMoneyPhoneNumber: momoPhone,
        title: widget.isViewAddressMode ? 'Paiement adresse' : 'Paiement de la commande',
      );

      if (!mounted) return;

      if (!result.isSuccess) {
        // Cancelled or errored — stay on the confirm step. Surface real
        // errors only (a user-cancelled checkout is silent-ish).
        setState(() => _isProcessingPayment = false);
        if (result.outcome == LokotroPayCheckoutOutcome.error) {
          final sdkMessage = (result.message ?? '').trim();
          _showSnack(sdkMessage.isNotEmpty ? sdkMessage : 'payment_error'.tr);
        } else {
          _showSnack('payment_cancelled'.tr, color: Colors.orange);
        }
        return;
      }

      // PHASE 3 — server-side verification: card payments never fire the
      // gateway webhook, so hand the backend the SDK's transaction id and
      // let it re-check with the gateway. Non-blocking: the payment step
      // polls the intent until it flips.
      final txId = (result.transactionId ?? '').trim();
      if (txId.isNotEmpty) {
        unawaited(
          PaymentApi.confirmCollect(
            customerReference: result.customerReference,
            gatewayTransactionId: txId,
          ).then((confirmed) {
            debugPrint('✅ confirm-collect: ${result.customerReference} → ${confirmed.state}');
          }).catchError((e) {
            debugPrint('⚠️ confirm-collect failed (non-blocking): $e');
          }),
        );
      } else {
        debugPrint(
          '🚨 confirm-collect SKIPPED for ${result.customerReference}: '
          'SDK returned no transaction id — relying on the gateway webhook',
        );
      }

      setState(() {
        _isProcessingPayment = false;
        _systemRef = customerRef;
        _currentStep = _paymentStep;
      });
    } catch (e) {
      debugPrint('❌ Error processing payment: $e');
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      _showSnack('${'payment_error'.tr}: $e');
    }
  }
}
