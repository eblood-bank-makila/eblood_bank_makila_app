import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:eblood_bank_mak_app/apps/config/api/ApiConfig.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:eblood_bank_mak_app/blood_search_flow/providers/search_flow_provider.dart';
import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_provider.dart';
import 'package:eblood_bank_mak_app/core/rbac/services/rbac_guard.dart';
import 'package:eblood_bank_mak_app/commande/business/model/CurrencyExchangeModel.dart';
import 'package:eblood_bank_mak_app/commande/business/service/CurrencyExchangeService.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/commande/pages/BloodRequestConfigDialog.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/commande/pages/PaymentStatusPage.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/commande/widgets/PhoneNumberBottomSheet.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/PocheModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BloodBankAddressSuccessPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Stepper page for ordering blood bags
/// Step 1: Select nearby blood bank
/// Step 2: Select blood bag quantity
/// Step 3: Confirm order details
/// Step 4: Payment processing
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
  int _currentStep = 0;
  BanqueModele? _selectedBloodBank;
  int _selectedQuantity = 1;
  bool _isLoading = false;

  // Blood bags data
  List<PocheModel> _bloodBags = [];
  List<PocheModel> _filteredBloodBags = [];
  int _maxQuantity = 0;
  String? _errorMessage;

  // Step 3: Payment data
  String? _cartId;
  String? _requestFor; // 'patient' | 'storage'
  String? _patientId;
  String? _requestType;
  String? _urgencyLevel;
  String? _requestReason;
  CurrencyExchangeResponse? _currencyExchangeResponse;
  bool _isCreatingCart = false;
  bool _isProcessingPayment = false;

  // Step 4: Payment processing data
  String? _systemRef;
  String? _phoneNumber;
  String? _selectedCurrencyId;

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
  }

  /// Get hospital ID - first check searchFlowProvider (for visitors), then fallback to profile lookup (for hospital staff)
  Future<String?> _getHospitalId() async {
    // 1. First try to get from blood_search_flow's identified hospital (for visitors)
    try {
      final searchFlowState = ref.read(searchFlowProvider);
      if (searchFlowState.identifiedHospital != null) {
        final hospitalId = searchFlowState.identifiedHospital!.id;
        debugPrint("🏥 Got hospital ID from searchFlowProvider: $hospitalId");
        return hospitalId;
      }
    } catch (e) {
      debugPrint("Could not read searchFlowProvider: $e");
    }

    // 2. Fallback: get from user profile (for hospital staff)
    return _getHospitalIdFromProfiles();
  }

  /// Get hospital ID from user profiles (for hospital staff)
  Future<String?> _getHospitalIdFromProfiles() async {
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
          debugPrint("🏥 Got hospital ID from user profile: ${hospital['_id']}");
          return hospital['_id']?.toString();
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
    // For order mode: 4 steps (bank, quantity, confirm, payment)
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
          _buildStepIndicator(1, 'quantity'.tr, Iconsax.box),
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
      // View address mode: 3 steps (bank, price selection, payment)
      switch (_currentStep) {
        case 0:
          return _buildStep1SelectBloodBank();
        case 1:
          return _buildAddressPriceSelection(); // Show price selection for address access
        case 2:
          return _buildStep4PaymentProcessing();
        default:
          return Container();
      }
    }

    // Order mode: 4 steps (bank, quantity, confirm, payment)
    switch (_currentStep) {
      case 0:
        return _buildStep1SelectBloodBank();
      case 1:
        return _buildStep2SelectQuantity();
      case 2:
        return _buildStep3ConfirmOrder();
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

  /// Select blood bank and move to next step
  void _selectBloodBank(BanqueModele bank) {
    setState(() {
      _selectedBloodBank = bank;
    });

    // For view address mode, fetch address access price
    // For order mode, fetch blood bags
    if (widget.isViewAddressMode) {
      _fetchAddressAccessPrice(bank);
    } else {
      _fetchBloodBags(bank);
    }
  }

  /// Fetch address access price for view address mode
  Future<void> _fetchAddressAccessPrice(BanqueModele bank) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentStep = 1; // Move to confirm step (step 2 in view address mode)
    });

    try {
      debugPrint('📍 Fetching address access price for bank: ${bank.id}');

      // Call API to get address access price
      final response = await getWithDio(
        '/eblood-connect/address-access-price',
      );

      debugPrint('📍 Address access price response: ${response.data}');

      if (response.success && response.data != null) {
        // Parse currency exchange response (same format as amount-exchances)
        final currencyResponse = CurrencyExchangeResponse.fromJson({
          'success': response.success,
          'message': response.message ?? 'Address access price fetched successfully',
          'data': response.data,
        });

        setState(() {
          _currencyExchangeResponse = currencyResponse;
          _isLoading = false;
        });

        debugPrint('✅ Address access price fetched successfully');
      } else {
        throw Exception(response.message ?? 'Failed to fetch address access price');
      }
    } catch (e) {
      debugPrint('❌ Error fetching address access price: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Fetch blood bags from selected blood bank
  Future<void> _fetchBloodBags(BanqueModele bank) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentStep = 1; // Move to step 2
    });

    try {
      debugPrint('🩸 Fetching blood bags for bank: ${bank.id}');

      // Call API to fetch blood bags
      final response = await getWithDio(
        '/eblood-connect/blood-bags',
        queryParams: {'blood_bank_id': bank.id},
      );

      debugPrint('📡 Response success: ${response.success}');
      debugPrint('📡 Response data type: ${response.data.runtimeType}');

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to fetch blood bags');
      }

      // Parse response - handle nested data structure
      final dynamic responseData = response.data;
      List<dynamic> items = [];

      if (responseData is Map) {
        // Check for nested data.data structure
        if (responseData.containsKey('data')) {
          final nestedData = responseData['data'];
          if (nestedData is Map && nestedData.containsKey('data')) {
            items = nestedData['data'] as List;
          } else if (nestedData is List) {
            items = nestedData;
          }
        }
      } else if (responseData is List) {
        items = responseData;
      }

      debugPrint('📦 Found ${items.length} blood bags');

      // Parse blood bags directly (no transformation needed)
      final bloodBags = items
          .whereType<Map>()
          .map((e) {
            try {
              return PocheModel.fromJson(e as Map<String, dynamic>);
            } catch (parseError) {
              debugPrint('⚠️ Error parsing blood bag: $parseError');
              return null;
            }
          })
          .whereType<PocheModel>()
          .toList();

      debugPrint('✅ Parsed ${bloodBags.length} blood bags');

      // Filter by selected blood type
      final filteredBags = bloodBags.where((bag) {
        final bloodType = bag.bloodBagInfo.bloodTypeInfo.bloodTypeName;
        final rhesus = bag.bloodBagInfo.bloodRhesusInfo.bloodRheususName;
        final fullType = '$bloodType$rhesus';
        debugPrint('🔍 Checking bag: $fullType vs ${widget.bloodType}');
        return fullType == widget.bloodType;
      }).toList();

      debugPrint('✅ Filtered to ${filteredBags.length} bags of type ${widget.bloodType}');

      setState(() {
        _bloodBags = bloodBags;
        _filteredBloodBags = filteredBags;
        _maxQuantity = filteredBags.fold(0, (sum, bag) => sum + bag.bloodStockCount);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching blood bags: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = '${'error_loading_bags'.tr}: $e';
        _isLoading = false;
      });
    }
  }

  /// Step 2: Select quantity
  Widget _buildStep2SelectQuantity() {
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

    if (_filteredBloodBags.isEmpty) {
      return _buildNoBloodBagsState();
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
                          'select_quantity'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _maxQuantity == 1
                              ? 'bag_available_singular'.trParams({'count': _maxQuantity.toString()})
                              : 'bag_available_plural'.trParams({'count': _maxQuantity.toString()}),
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

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Quantity selector card
                _buildQuantitySelectorCard(),
              ],
            ),
          ),
        ),

        // Bottom button
        _buildBottomButton(),
      ],
    );
  }

  /// Build address price selection (for view address mode)
  Widget _buildAddressPriceSelection() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: AppSpinner.bloodDrop(
            size: 80,
            showMessage: true,
            message: 'loading_prices'.tr,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.info_circle,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'error'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.wallet,
                      color: ColorPages.COLOR_PRINCIPAL,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'select_payment_option'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'choose_currency_to_pay'.tr,
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

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
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

                // Payment options
                _buildAddressPaymentOptions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Step 3: Confirm order and payment
  Widget _buildStep3ConfirmOrder() {
    if (_isCreatingCart) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: AppSpinner.bloodDrop(
            size: 80,
            showMessage: true,
            message: 'creating_cart'.tr,
          ),
        ),
      );
    }

    if (_cartId == null) {
      // Create cart first
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _createCart();
      });
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: AppSpinner.bloodDrop(
            size: 80,
            showMessage: true,
            message: 'preparing_order'.tr,
          ),
        ),
      );
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
                      Iconsax.tick_circle,
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
                          'confirm_order'.tr,
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
                // Order summary card
                _buildOrderSummaryCard(),

                const SizedBox(height: 20),

                // Payment options
                _buildPaymentOptions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Create cart with selected blood bags
  Future<void> _createCart() async {
    if (_isCreatingCart || _cartId != null) return;

    // Checkout-level RBAC gate. The page's entry guard checks the
    // broader "order" flag; the final checkout requires a stricter
    // checkout sub_menu flag.
    if (!_hasFlag('flutter_apps_eblood_bank_hosp_blood_bag_checkout')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('access_denied'.tr)),
        );
      }
      return;
    }

    setState(() {
      _isCreatingCart = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🛒 Creating cart...');

      // Get the first filtered blood bag (we'll use its ID)
      if (_filteredBloodBags.isEmpty) {
        throw Exception('No blood bags selected');
      }

      final bloodBag = _filteredBloodBags.first;
      final bloodBagId = bloodBag.bloodBagInfo.id;

      debugPrint('🛒 Adding blood bag to cart: $bloodBagId');
      debugPrint('🛒 Blood bank: ${_selectedBloodBank?.id}');
      debugPrint('🛒 Quantity: $_selectedQuantity');

      // Add to cart
      final response = await postWithDio(
        '/eblood-connect/cart/add',
        body: {
          'blood_bag_id': bloodBagId,
          'blood_bank_id': _selectedBloodBank!.id,
          'quantity': _selectedQuantity,
        },
      );

      debugPrint('🛒 Cart response: ${response.success}');

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to create cart');
      }

      final cartData = response.data;
      final cartId = cartData['id'] ?? cartData['_id'];

      debugPrint('✅ Cart created: $cartId');
      debugPrint('📦 Cart data: $cartData');

      // Calculate total amount ourselves: quantity × price
      final totalAmount = (_selectedQuantity * bloodBag.price).toDouble();

      // Get currency info from blood bag
      final refCurrencyId = bloodBag.currencyId ?? cartData['ref_currency_id'] ?? '';

      debugPrint('💱 Calculated total amount: $totalAmount (quantity: $_selectedQuantity × price: ${bloodBag.price})');
      debugPrint('💱 Fetching currency exchanges for: $refCurrencyId, amount: $totalAmount');

      if (refCurrencyId.isNotEmpty) {
        final currencyService = ref.read(currencyExchangeServiceProvider);
        final currencyResponse = await currencyService.getCurrencyExchanges(
          totalAmount,
          refCurrencyId,
        );

        setState(() {
          _cartId = cartId;
          _currencyExchangeResponse = currencyResponse;
          _isCreatingCart = false;
        });
      } else {
        setState(() {
          _cartId = cartId;
          _isCreatingCart = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating cart: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = '${'error_creating_cart'.tr}: $e';
        _isCreatingCart = false;
      });
    }
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
          ],
        ),
      ),
    );
  }

  /// Build quantity selector card
  Widget _buildQuantitySelectorCard() {
    final totalPrice = _selectedQuantity * (_filteredBloodBags.isNotEmpty ? _filteredBloodBags.first.price : 0);
    final currencySymbol = _filteredBloodBags.isNotEmpty ? (_filteredBloodBags.first.currencySymbol ?? '\$') : '\$';

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(24),
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
          children: [
            // Blood type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorPages.COLOR_PRINCIPAL,
                    Colors.red.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.bloodType,
                style: GoogleFonts.ubuntu(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Quantity selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decrement button
                _buildQuantityButton(
                  icon: Iconsax.minus,
                  onTap: _selectedQuantity > 1
                      ? () {
                          setState(() {
                            _selectedQuantity--;
                          });
                        }
                      : null,
                ),

                const SizedBox(width: 32),

                // Quantity display
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ColorPages.COLOR_PRINCIPAL,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$_selectedQuantity',
                      style: GoogleFonts.ubuntu(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 32),

                // Increment button
                _buildQuantityButton(
                  icon: Iconsax.add,
                  onTap: _selectedQuantity < _maxQuantity
                      ? () {
                          setState(() {
                            _selectedQuantity++;
                          });
                        }
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Price display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'total_price'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '$currencySymbol$totalPrice',
                    style: GoogleFonts.ubuntu(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
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

  /// Build quantity button (increment/decrement)
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isEnabled
              ? ColorPages.COLOR_PRINCIPAL
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// Build bottom button
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _currentStep = 2; // Move to confirmation step
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPages.COLOR_PRINCIPAL,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _selectedQuantity == 1
                    ? 'request_bag_singular'.trParams({'count': _selectedQuantity.toString()})
                    : 'request_bag_plural'.trParams({'count': _selectedQuantity.toString()}),
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Iconsax.arrow_right_3,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build order summary card
  Widget _buildOrderSummaryCard() {
    final totalPrice = _selectedQuantity * (_filteredBloodBags.isNotEmpty ? _filteredBloodBags.first.price : 0);
    final currencySymbol = _filteredBloodBags.isNotEmpty ? (_filteredBloodBags.first.currencySymbol ?? '\$') : '\$';

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

            // Quantity
            _buildSummaryRow(
              icon: Iconsax.box,
              label: 'quantity'.tr,
              value: _selectedQuantity == 1 ? '1 ${'bag'.tr}' : '$_selectedQuantity ${'bags'.tr}',
            ),

            const SizedBox(height: 12),

            // Price per unit
            _buildSummaryRow(
              icon: Iconsax.dollar_circle,
              label: 'unit_price'.tr,
              value: '$currencySymbol${_filteredBloodBags.isNotEmpty ? _filteredBloodBags.first.price : 0}',
            ),

            const SizedBox(height: 20),

            // Divider
            Divider(color: Colors.grey.shade300),

            const SizedBox(height: 20),

            // Total
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
                Text(
                  '$currencySymbol$totalPrice',
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

  /// Build payment options
  Widget _buildPaymentOptions() {
    if (_currencyExchangeResponse == null || _currencyExchangeResponse!.data.isEmpty) {
      // No currency conversion available, show single payment button
      return _buildSinglePaymentButton();
    }

    // Filter out same-currency conversions (e.g., USD -> USD)
    final differentCurrencyOptions = _currencyExchangeResponse!.data.where((option) {
      final fromCode = option.currencyFromCode.toLowerCase();
      final toCode = option.currencyToCode.toLowerCase();
      return fromCode != toCode;
    }).toList();

    if (differentCurrencyOptions.isEmpty) {
      // No different currency conversion available, show single payment button
      return _buildSinglePaymentButton();
    }

    // Show currency conversion options
    return _buildCurrencyConversionOptions(differentCurrencyOptions.first);
  }

  /// Build single payment button (no currency conversion)
  Widget _buildSinglePaymentButton() {
    final totalPrice = _selectedQuantity * (_filteredBloodBags.isNotEmpty ? _filteredBloodBags.first.price : 0);
    final currencySymbol = _filteredBloodBags.isNotEmpty ? (_filteredBloodBags.first.currencySymbol ?? '\$') : '\$';

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: ElevatedButton(
        onPressed: _isProcessingPayment ? null : () => _processPaymentWithCurrency(null),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPages.COLOR_PRINCIPAL,
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
              Icon(Iconsax.wallet, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              _isProcessingPayment ? 'processing'.tr : 'pay_amount'.trParams({'amount': '$currencySymbol$totalPrice'}),
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

  /// Build currency conversion options
  Widget _buildCurrencyConversionOptions(CurrencyExchangeModel convertedOption) {
    final totalPrice = _selectedQuantity * (_filteredBloodBags.isNotEmpty ? _filteredBloodBags.first.price : 0);
    final cartCurrency = _filteredBloodBags.isNotEmpty ? (_filteredBloodBags.first.currencyCode ?? 'usd') : 'usd';
    final currencySymbol = _filteredBloodBags.isNotEmpty ? (_filteredBloodBags.first.currencySymbol ?? '\$') : '\$';

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Currency exchange info
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
                  Iconsax.money_change,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'exchange_rate'.trParams({
                      'from': convertedOption.currencyFromCode.toUpperCase(),
                      'to': convertedOption.currencyToCode.toUpperCase(),
                      'rate': convertedOption.exchangedValue.toStringAsFixed(0)
                    }),
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Two payment buttons
          Row(
            children: [
              // Original currency button
              Expanded(
                child: _buildPaymentButton(
                  label: 'pay_amount'.trParams({'amount': '$currencySymbol${totalPrice.toStringAsFixed(0)}'}),
                  subtitle: '${cartCurrency.toUpperCase()} (${'original'.tr})',
                  onPressed: () => _processPaymentWithCurrency(null),
                  isPrimary: true,
                ),
              ),

              const SizedBox(width: 12),

              // Converted currency button
              Expanded(
                child: _buildPaymentButton(
                  label: 'pay_amount'.trParams({'amount': '${convertedOption.convertedAmount.toStringAsFixed(0)} ${convertedOption.currencyToCode.toUpperCase()}'}),
                  subtitle: '${convertedOption.currencyToCode.toUpperCase()} (${'converted'.tr})',
                  onPressed: () => _processPaymentWithCurrency(convertedOption.currencyTo),
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build address payment options (for view address mode)
  Widget _buildAddressPaymentOptions() {
    if (_currencyExchangeResponse == null || _currencyExchangeResponse!.data.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the first currency option (address access price)
    final priceOption = _currencyExchangeResponse!.data.first;

    // Get currency symbol based on currency code
    String getCurrencySymbol(String currencyCode) {
      switch (currencyCode.toLowerCase()) {
        case 'usd':
          return '\$';
        case 'cdf':
          return 'FC';
        case 'eur':
          return '€';
        default:
          return currencyCode.toUpperCase();
      }
    }

    final currencySymbol = getCurrencySymbol(priceOption.currencyFromCode);

    // Filter out same-currency conversions
    final differentCurrencyOptions = _currencyExchangeResponse!.data.where((option) {
      final fromCode = option.currencyFromCode.toLowerCase();
      final toCode = option.currencyToCode.toLowerCase();
      return fromCode != toCode;
    }).toList();

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Original currency payment button
          _buildPaymentButton(
            label: 'pay_amount'.trParams({
              'amount': '$currencySymbol${priceOption.amount.toStringAsFixed(0)}'
            }),
            subtitle: '${priceOption.currencyFromCode.toUpperCase()} (${'original'.tr})',
            onPressed: () => _processPaymentWithCurrency(priceOption.currencyFrom),
            isPrimary: true,
          ),

          // Show converted currency option if available
          if (differentCurrencyOptions.isNotEmpty) ...[
            const SizedBox(height: 16),

            // Exchange rate info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.money_change,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'exchange_rate'.trParams({
                        'from': differentCurrencyOptions.first.currencyFromCode.toUpperCase(),
                        'to': differentCurrencyOptions.first.currencyToCode.toUpperCase(),
                        'rate': differentCurrencyOptions.first.exchangedValue.toStringAsFixed(0)
                      }),
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Converted currency payment button
            _buildPaymentButton(
              label: 'pay_amount'.trParams({
                'amount': '${differentCurrencyOptions.first.convertedAmount.toStringAsFixed(0)} ${differentCurrencyOptions.first.currencyToCode.toUpperCase()}'
              }),
              subtitle: '${differentCurrencyOptions.first.currencyToCode.toUpperCase()} (${'converted'.tr})',
              onPressed: () => _processPaymentWithCurrency(differentCurrencyOptions.first.currencyTo),
              isPrimary: false,
            ),
          ],
        ],
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

    // Payment submitted successfully, show PaymentStatusPage embedded
    String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.30.132:3101/eblood-hstdapi/v1';

    // Use custom endpoint for view address mode
    String? customCheckStatusEndpoint;
    if (widget.isViewAddressMode) {
      customCheckStatusEndpoint = '/eblood-connect/blood-bank-address-request/check-payment-status?identifier=${_systemRef!}';
    }

    return PaymentStatusPage(
      systemRef: _systemRef!,
      baseUrl: baseUrl,
      customCheckStatusEndpoint: customCheckStatusEndpoint,
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

  /// Build payment button
  Widget _buildPaymentButton({
    required String label,
    required String subtitle,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton(
      onPressed: _isProcessingPayment ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? ColorPages.COLOR_PRINCIPAL : Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isPrimary ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade300,
            width: isPrimary ? 0 : 1,
          ),
        ),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.ubuntu(
              fontSize: 11,
              color: isPrimary ? Colors.white70 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Process payment with selected currency
  Future<void> _processPaymentWithCurrency(String? currencyId) async {
    debugPrint('💳 Processing payment with currency ID: $currencyId');

    // 1) Ask for phone number first
    final phoneNumber = await _showPhoneNumberBottomSheet();

    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      debugPrint('❌ Payment cancelled: no phone number provided');
      return;
    }

    if (!mounted) return;

    // For view address mode, skip blood request config dialog
    if (widget.isViewAddressMode) {
      setState(() {
        _phoneNumber = phoneNumber;
        _selectedCurrencyId = currencyId;
        // Move to Step 2 (payment step in view address mode)
        _currentStep = 2;
      });

      // Submit address request payment
      _submitAddressRequestPayment(phoneNumber, currencyId);
      return;
    }

    // 2) Ask for blood request configuration (patient/storage, reason, etc.) - only for order mode
    final config = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => BloodRequestConfigDialog(
        patientCrudInfo: ref.read(rbacProvider.notifier).getCrudInfoByPath(
          'flutter_apps_eblood_bank_hosp_home_patients',
        ),
      ),
    );

    if (config == null) {
      debugPrint('❌ Payment cancelled: no configuration provided');
      return;
    }

    if (!mounted) return;

    setState(() {
      _requestFor = config['request_for'];
      _patientId = config['patient_id'];
      _requestType = config['request_type'];
      _urgencyLevel = config['urgency_level'];
      _requestReason = config['request_reason'];
      _phoneNumber = phoneNumber;
      _selectedCurrencyId = currencyId;
      // 3) Move to Step 4
      _currentStep = 3;
    });

    // 4) Submit payment
    _submitPayment(phoneNumber, currencyId);
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

  /// Submit payment with phone number and currency
  Future<void> _submitPayment(String phoneNumber, String? currencyId) async {
    debugPrint("🚀 Starting payment process with phone: $phoneNumber");
    debugPrint("💰 Currency ID to send: $currencyId");
    debugPrint("💰 Cart ID: $_cartId");

    if (!mounted) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      debugPrint("💳 Calling payment API...");

      final response = await postWithDio(
        '/eblood-connect/cart/submit-payment',
        body: {
          'cart_id': _cartId,
          'phone_number': phoneNumber,
          if (currencyId != null) 'transactional_currency_id': currencyId,
          if (_requestFor != null) 'request_for': _requestFor,
          if (_requestReason != null) 'request_reason': _requestReason,
          if (_patientId != null) 'patient_id': _patientId,
          if (_requestType != null) 'request_type': _requestType,
          if (_urgencyLevel != null) 'urgency_level': _urgencyLevel,
        },
      );

      debugPrint("🎯 Payment result: ${response.success}");
      debugPrint("📄 Message: ${response.message}");

      if (!mounted) return;

      setState(() {
        _isProcessingPayment = false;
      });

      if (response.success && response.data != null) {
        final systemRef = response.data['systemRef'] ?? response.data['blood_request_identifier'];

        if (systemRef != null) {
          debugPrint("🎉 Payment initiated successfully with systemRef: $systemRef");

          if (!mounted) return;

          // Store systemRef for Step 4 to use
          setState(() {
            _systemRef = systemRef;
          });
        } else {
          throw Exception('No system reference returned');
        }
      } else {
        throw Exception(response.message ?? 'Payment failed');
      }
    } catch (e) {
      debugPrint('❌ Error processing payment: $e');

      if (!mounted) return;

      setState(() {
        _isProcessingPayment = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Submit address request payment (for view address mode)
  Future<void> _submitAddressRequestPayment(String phoneNumber, String? currencyId) async {
    debugPrint("🚀 Starting address request payment with phone: $phoneNumber");
    debugPrint("💰 Currency ID to send: $currencyId");

    if (!mounted) return;

    // Validate required data
    if (_selectedBloodBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Aucune banque de sang sélectionnée'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_filteredBloodBags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Aucune poche de sang sélectionnée'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      debugPrint("💳 Calling address request payment API...");

      // Get blood bag ID from the first filtered blood bag
      final bloodBagId = _filteredBloodBags.first.bloodBagInfo.id;
      final bloodBankId = _selectedBloodBank!.id;

      debugPrint("🏦 Blood bank ID: $bloodBankId");
      debugPrint("🩸 Blood bag ID: $bloodBagId");

      // Create array explicitly
      final List<String> bloodBagsIdArray = [bloodBagId];
      debugPrint("📦 Blood bags ID array: $bloodBagsIdArray (type: ${bloodBagsIdArray.runtimeType})");

      // Get hospital ID (from searchFlowProvider for visitors, or from profile for hospital staff)
      final hospitalId = await _getHospitalId();
      debugPrint("🏥 Hospital ID: $hospitalId");

      final requestBody = {
        'blood_bank_id': bloodBankId,
        'blood_bags_id': bloodBagsIdArray,
        'phone_number': phoneNumber,
        if (hospitalId != null) 'hospital_id': hospitalId,
        if (currencyId != null) 'transactional_currency_id': currencyId,
      };
      debugPrint("📤 Request body: $requestBody");

      final response = await postWithDio(
        '/eblood-connect/blood-bank-address-request/submit-payment',
        body: requestBody,
      );

      debugPrint("🎯 Payment result: ${response.success}");
      debugPrint("📄 Message: ${response.message}");

      if (!mounted) return;

      setState(() {
        _isProcessingPayment = false;
      });

      if (response.success && response.data != null) {
        final systemRef = response.data['systemRef'] ?? response.data['blood_bank_address_request_identifier'];

        if (systemRef != null) {
          debugPrint("🎉 Address request payment initiated successfully with systemRef: $systemRef");

          if (!mounted) return;

          // Store systemRef for Step 4 to use
          setState(() {
            _systemRef = systemRef;
          });
        } else {
          throw Exception('No system reference returned');
        }
      } else {
        throw Exception(response.message ?? 'Payment failed');
      }
    } catch (e) {
      debugPrint('❌ Error processing address request payment: $e');

      if (!mounted) return;

      setState(() {
        _isProcessingPayment = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

