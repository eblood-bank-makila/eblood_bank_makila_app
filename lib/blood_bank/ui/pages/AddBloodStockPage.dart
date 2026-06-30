import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../../apps/widgets/ModernSpinnerWidget.dart';
import '../../../core/rbac/services/rbac_guard.dart';
import '../../business/model/BloodStock.dart';
import '../../business/model/BloodEnums.dart';
import '../../business/interactors/BloodBankController.dart';
import '../../../core/rbac/providers/rbac_provider.dart';
import '../../controllers/donors_provider.dart';
import '../../controllers/selected_batch_number_provider.dart';
import '../../models/donor.dart';
import '../widgets/BatchNumberSelectorField.dart';
import 'DonorRegistrationPage.dart';

/// Sentinel popped by [_DonorSelectorSheet] when the user explicitly chooses
/// the "no donor / anonymous" option — distinct from `null`, which means the
/// sheet was dismissed and the current selection should be left untouched.
const String _kNoDonor = '__no_donor__';

// Donor selector modal sheet — backed by the live donors API (donorsProvider)
// so the picker shows real, searchable donors instead of placeholder data.
class _DonorSelectorSheet extends ConsumerStatefulWidget {
  final String? initialDonorId;

  const _DonorSelectorSheet({this.initialDonorId});

  @override
  ConsumerState<_DonorSelectorSheet> createState() =>
      _DonorSelectorSheetState();
}

class _DonorSelectorSheetState extends ConsumerState<_DonorSelectorSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearchByPhone = false;

  // Whether this user may register a donor. Pooled with the CNTS flag because
  // CNTS reuses the same donor screens (see RbacScreenRegistry).
  bool get _canRegister =>
      ref.read(rbacProvider.notifier).hasAnyMenuFlag(const [
        'flutter_apps_eblood_bank_bb_donors_register',
        'flutter_apps_eblood_bank_cnts_donors_register',
      ]);

  @override
  void initState() {
    super.initState();
    // Open on a clean, unfiltered list every time the picker is shown so a
    // filter left over from another screen doesn't hide donors here.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(donorsProvider.notifier).clearSearch();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final notifier = ref.read(donorsProvider.notifier);
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        notifier.clearSearch();
      } else {
        notifier.searchDonors(
          searchQuery: trimmed,
          searchType: _isSearchByPhone ? 'phone' : 'name',
        );
      }
    });
  }

  Future<void> _openRegistration() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DonorRegistrationPage()),
    );
    if (created == true && mounted) {
      // Pull the freshly registered donor back into the list so it can be
      // picked right away.
      ref.read(donorsProvider.notifier).refreshDonors();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('donor_list_updated'.tr),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorsState = ref.watch(donorsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle + title + "add donor" action
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'select_donor'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (_canRegister)
                          TextButton.icon(
                            onPressed: _openRegistration,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: Text('add_donor'.tr),
                            style: TextButton.styleFrom(
                              foregroundColor: ColorPages.COLOR_PRINCIPAL,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      keyboardType: _isSearchByPhone
                          ? TextInputType.phone
                          : TextInputType.text,
                      decoration: InputDecoration(
                        hintText: _isSearchByPhone
                            ? 'enter_donor_phone_hint'.tr
                            : 'enter_donor_name_hint'.tr,
                        prefixIcon: const Icon(Iconsax.search_normal),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                  setState(() {});
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {}); // refresh the clear button
                        _onSearchChanged(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        label: Text('search_by_phone'.tr),
                        selected: _isSearchByPhone,
                        onSelected: (selected) {
                          setState(() => _isSearchByPhone = selected);
                          _onSearchChanged(_searchController.text);
                        },
                        selectedColor:
                            ColorPages.COLOR_PRINCIPAL.withOpacity(0.2),
                        checkmarkColor: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                  ],
                ),
              ),

              // Always-available "no donor / anonymous" option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(Icons.close, color: Colors.grey.shade700),
                ),
                title: Text('no_donor'.tr),
                subtitle: Text('anonymous_or_no_donor'.tr),
                trailing: widget.initialDonorId == null
                    ? Icon(Icons.check_circle, color: ColorPages.COLOR_PRINCIPAL)
                    : null,
                onTap: () => Navigator.pop(context, _kNoDonor),
              ),
              const Divider(height: 1),

              // Donor list (live backend data)
              Expanded(
                child: _buildDonorListArea(donorsState, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDonorListArea(
    DonorListState state,
    ScrollController scrollController,
  ) {
    if (state.isLoading && state.donors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isError && state.donors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                state.errorMessage.isNotEmpty
                    ? state.errorMessage
                    : 'something_went_wrong'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(donorsProvider.notifier).refreshDonors(),
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (state.donors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isSearchActive ? Icons.search_off : Icons.people_outline,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              state.isSearchActive
                  ? 'no_donors_found'.tr
                  : 'no_donors_registered'.tr,
              style: GoogleFonts.ubuntu(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                state.isSearchActive
                    ? 'try_different_search_terms'.tr
                    : 'add_first_donor_hint'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent * 0.85) {
          if (!state.isLoading && state.hasMorePages) {
            ref.read(donorsProvider.notifier).loadNextPage();
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        itemCount: state.donors.length + 1, // +1 for the footer
        itemBuilder: (context, index) {
          if (index == state.donors.length) {
            if (state.isLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (!state.hasMorePages) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'end_of_list'.tr,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              );
            }
            return const SizedBox(height: 8);
          }

          return _buildDonorTile(state.donors[index]);
        },
      ),
    );
  }

  Widget _buildDonorTile(Donor donor) {
    final isSelected = donor.id == widget.initialDonorId;
    final hasPhoto = donor.photoUrl != null && donor.photoUrl!.isNotEmpty;
    final hasCode = donor.donorCode != null && donor.donorCode!.isNotEmpty;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.shade100,
        backgroundImage: hasPhoto ? NetworkImage(donor.photoUrl!) : null,
        child: hasPhoto
            ? null
            : Text(
                donor.bloodType.isNotEmpty ? donor.bloodType : '?',
                style: GoogleFonts.ubuntu(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
      ),
      title: Text(
        donor.fullName,
        style: GoogleFonts.ubuntu(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCode) Text('${'donor_code'.tr}: ${donor.donorCode}'),
          if (donor.phoneNumber.isNotEmpty)
            Text('${'phone'.tr}: ${donor.phoneNumber}'),
        ],
      ),
      isThreeLine: hasCode && donor.phoneNumber.isNotEmpty,
      trailing: isSelected
          ? Icon(Icons.check_circle, color: ColorPages.COLOR_PRINCIPAL)
          : null,
      onTap: () => Navigator.pop(context, donor),
    );
  }
}

class AddBloodStockPage extends ConsumerStatefulWidget {
  const AddBloodStockPage({super.key});

  @override
  ConsumerState<AddBloodStockPage> createState() => _AddBloodStockPageState();
}

class _AddBloodStockPageState extends ConsumerState<AddBloodStockPage> {
  final _formKey = GlobalKey<FormState>();
  // Batch number ("numéro de lot") is now picked via the reusable selector,
  // not a free-text field. Holds the currently chosen value for this form.
  String? _selectedBatchNumber;
  final _bloodBagNumberController = TextEditingController();
  final _volumeController = TextEditingController(text: "450"); // Default volume in ml
  final _descriptionController = TextEditingController();

  // Donor selection
  String? _selectedDonorId;
  String? _selectedDonorName;
  String? _selectedDonorNumber;

  // Selected values
  String _selectedBloodType = 'O+';
  BloodProductType _selectedProductType = BloodProductType.wholeBlood;
  BloodBagStatus _selectedStatus = BloodBagStatus.available;
  BloodBagConditionStatus _selectedBagCondition = BloodBagConditionStatus.good;
  DateTime _collectionDate = DateTime.now();
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 42));
  bool _isLoading = false;

  final List<String> _bloodTypes = [
    'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill the batch number from the sticky session selection, so a lot
    // number chosen earlier in this session is kept across bag creations.
    _selectedBatchNumber = ref.read(selectedBatchNumberProvider);
    // RBAC entry guard: auto-pop + snackbar if user lacks permission.
    // Pool with the CNTS equivalent so CNTS users — who reuse this same
    // page — can add stock too.
    guardPageEntryAny(
      ref,
      context,
      const [
        'flutter_apps_eblood_bank_bb_inventory_stock_add',
        'flutter_apps_eblood_bank_cnts_inventory_stock_add',
      ],
    );
  }

  @override
  void dispose() {
    _bloodBagNumberController.dispose();
    _volumeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: ModernSpinnerWidget())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Iconsax.arrow_left,
          color: Colors.grey.shade800,
        ),
      ),
      title: Text(
        'add_blood_stock'.tr,
        style: GoogleFonts.ubuntu(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saveBloodStock,
          child: Text(
            'save'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blood Type Selection
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _buildBloodTypeSection(),
            ),
            const SizedBox(height: 24),

            // Basic Information
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: _buildBasicInfoSection(),
            ),
            const SizedBox(height: 24),

            // Product Type Section
            FadeInUp(
              delay: const Duration(milliseconds: 350),
              child: _buildProductTypeSection(),
            ),
            const SizedBox(height: 24),

            // Status and Condition Section
            FadeInUp(
              delay: const Duration(milliseconds: 375),
              child: _buildStatusAndConditionSection(),
            ),
            const SizedBox(height: 24),

            // Dates Section
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildDatesSection(),
            ),
            const SizedBox(height: 24),

            // Additional Information
            FadeInUp(
              delay: const Duration(milliseconds: 450),
              child: _buildAdditionalInfoSection(),
            ),
            const SizedBox(height: 32),

            // Save Button
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _buildSaveButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodTypeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'blood_type'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _bloodTypes.map((type) {
              final isSelected = _selectedBloodType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBloodType = type;
                  });
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorPages.COLOR_PRINCIPAL
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? ColorPages.COLOR_PRINCIPAL
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'basic_information'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Volume
          _buildTextField(
            controller: _volumeController,
            label: 'blood_volume_ml'.tr,
            hint: 'example_volume'.tr,
            icon: Iconsax.weight,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'volume_required'.tr;
              }
              if (double.tryParse(value) == null) {
                return 'volume_must_be_number'.tr;
              }
              if (double.parse(value) <= 0) {
                return 'volume_must_be_positive'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Batch Number — reusable searchable selector (org-scoped catalog
          // with an "Autres" option to create a new lot number on the fly).
          BatchNumberSelectorField(
            value: _selectedBatchNumber,
            isRequired: true,
            onChanged: (value) =>
                setState(() => _selectedBatchNumber = value),
          ),
          const SizedBox(height: 16),

          // Blood Bag Number (numéro de la poche de sang)
          _buildTextField(
            controller: _bloodBagNumberController,
            label: 'blood_bag_number'.tr,
            hint: 'example_blood_bag_number'.tr,
            icon: Iconsax.scan_barcode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'blood_bag_number_required'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Donor selector
          _buildDonorSelector(),
        ],
      ),
    );
  }

  Widget _buildDatesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'dates'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Collection Date
          _buildDateField(
            label: 'collection_date'.tr,
            date: _collectionDate,
            icon: Iconsax.calendar,
            onTap: () => _selectDate(context, true),
          ),
          const SizedBox(height: 16),

          // Expiration Date
          _buildDateField(
            label: 'expiration_date'.tr,
            date: _expirationDate,
            icon: Iconsax.calendar_tick,
            onTap: () => _selectDate(context, false),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'additional_information'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'description_optional'.tr,
              hintText: 'additional_info_placeholder'.tr,
              prefixIcon: Icon(Iconsax.note, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorPages.COLOR_PRINCIPAL),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTypeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'blood_product_type'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Product Type Dropdown
          DropdownButtonFormField<BloodProductType>(
            decoration: InputDecoration(
              labelText: 'product_type'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Iconsax.health, color: Colors.grey.shade600),
            ),
            value: _selectedProductType,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedProductType = newValue;
                });
              }
            },
            items: [
              // Core Blood Components
              DropdownMenuItem(
                value: BloodProductType.wholeBlood,
                child: Text(BloodProductType.wholeBlood.value.tr),
              ),
              DropdownMenuItem(
                value: BloodProductType.plasma,
                child: Text(BloodProductType.plasma.value.tr),
              ),
              DropdownMenuItem(
                value: BloodProductType.platelets,
                child: Text(BloodProductType.platelets.value.tr),
              ),
              DropdownMenuItem(
                value: BloodProductType.redBloodCells,
                child: Text(BloodProductType.redBloodCells.value.tr),
              ),

              // Add more categories with headers
              DropdownMenuItem(
                enabled: false,
                child: Divider(height: 1),
              ),
              DropdownMenuItem(
                enabled: false,
                child: Text('plasma_derived_products'.tr,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DropdownMenuItem(
                value: BloodProductType.cryoprecipitate,
                child: Text(BloodProductType.cryoprecipitate.value.tr),
              ),
              DropdownMenuItem(
                value: BloodProductType.frozenPlasma,
                child: Text(BloodProductType.frozenPlasma.value.tr),
              ),
              DropdownMenuItem(
                value: BloodProductType.freshFrozenPlasma,
                child: Text(BloodProductType.freshFrozenPlasma.value.tr),
              ),

              // More specialized products
              DropdownMenuItem(
                enabled: false,
                child: Divider(height: 1),
              ),
              DropdownMenuItem(
                enabled: false,
                child: Text('solutions_and_additives'.tr,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DropdownMenuItem(
                value: BloodProductType.saline,
                child: Text(BloodProductType.saline.value.tr),
              ),
              DropdownMenuItem(
                value: BloodProductType.acdSolution,
                child: Text(BloodProductType.acdSolution.value.tr),
              ),
              DropdownMenuItem(
                value: BloodProductType.cpdSolution,
                child: Text(BloodProductType.cpdSolution.value.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndConditionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'status_and_condition'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Status Dropdown
          DropdownButtonFormField<BloodBagStatus>(
            decoration: InputDecoration(
              labelText: 'status'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Iconsax.status_up, color: Colors.grey.shade600),
            ),
            value: _selectedStatus,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedStatus = newValue;
                });
              }
            },
            items: BloodBagStatus.values
                .where((status) => status != BloodBagStatus.none)
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.value.tr),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Condition Dropdown
          DropdownButtonFormField<BloodBagConditionStatus>(
            decoration: InputDecoration(
              labelText: 'bag_condition'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Iconsax.activity, color: Colors.grey.shade600),
            ),
            value: _selectedBagCondition,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedBagCondition = newValue;
                });
              }
            },
            items: BloodBagConditionStatus.values
                .where((condition) => condition != BloodBagConditionStatus.none)
                .map((condition) => DropdownMenuItem(
                      value: condition,
                      child: Text(condition.value.tr),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorSelector() {
    return GestureDetector(
      onTap: _openDonorSelector,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Iconsax.user, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'donor_optional'.tr,
                    style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDonorName != null
                        ? '${_selectedDonorName!} • ${_selectedDonorNumber ?? ''}'
                        : 'select_donor'.tr,
                    style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _openDonorSelector() async {
    // The sheet pops a [Donor] when one is picked, the [_kNoDonor] sentinel for
    // the explicit "no donor / anonymous" choice, or null when it is dismissed.
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true, // Allow the sheet to take up to 95% of screen height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DonorSelectorSheet(initialDonorId: _selectedDonorId),
    );

    // Dismissed without choosing — keep the current selection untouched.
    if (result == null) return;

    if (result is Donor) {
      setState(() {
        _selectedDonorId = result.id;
        _selectedDonorName = result.fullName;
        _selectedDonorNumber =
            (result.donorCode != null && result.donorCode!.isNotEmpty)
                ? result.donorCode
                : result.phoneNumber;
      });
    } else {
      // Explicit "Aucun donneur" — clear any previous selection.
      setState(() {
        _selectedDonorId = null;
        _selectedDonorName = null;
        _selectedDonorNumber = null;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorPages.COLOR_PRINCIPAL),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMd(Get.locale?.languageCode).format(date),
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveBloodStock,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPages.COLOR_PRINCIPAL,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.tick_circle, size: 20),
            const SizedBox(width: 8),
            Text(
              'save_stock'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isCollectionDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCollectionDate ? _collectionDate : _expirationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isCollectionDate) {
          _collectionDate = picked;
          // Auto-update expiration date based on product type
          int expirationDays = 42; // Default for whole blood

          switch (_selectedProductType) {
            case BloodProductType.platelets:
              expirationDays = 5; // Platelets have shorter shelf life
              break;
            case BloodProductType.plasma:
            case BloodProductType.freshFrozenPlasma:
            case BloodProductType.frozenPlasma:
              expirationDays = 365; // Frozen plasma can last a year
              break;
            case BloodProductType.redBloodCells:
              expirationDays = 42; // RBCs last about 42 days
              break;
            default:
              expirationDays = 42; // Default
          }

          _expirationDate = picked.add(Duration(days: expirationDays));
        } else {
          _expirationDate = picked;
        }
      });
    }
  }

  Future<void> _saveBloodStock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(bloodStockControllerProvider.notifier);

      print('🩸 Creating blood stock with:');
      print('🩸 Blood Type: $_selectedBloodType');
      print('🩸 Volume: ${_volumeController.text}');
      print('🩸 Product Type: ${_selectedProductType.value}');
      print('🩸 Status: ${_selectedStatus.value}');
      print('🩸 Condition: ${_selectedBagCondition.value}');
      print('🩸 Collection Date: $_collectionDate');
      print('🩸 Expiration Date: $_expirationDate');
      print('🩸 Batch Number: ${_selectedBatchNumber ?? ''}');
      print('🩸 Blood Bag Number: ${_bloodBagNumberController.text}');
      print('🩸 Donor ID: ${_selectedDonorId ?? "No donor selected"}');

      final bloodStock = BloodStock(
        id: '', // Generated by backend
        bloodType: _selectedBloodType,
        volume: double.parse(_volumeController.text),
        productType: _selectedProductType,
        status: _selectedStatus,
        bagCondition: _selectedBagCondition,
        expirationDate: _expirationDate,
        collectionDate: _collectionDate,
        donorId: _selectedDonorId ?? '',
        batchNumber: _selectedBatchNumber ?? '',
        bloodBagNumber: _bloodBagNumberController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('🚀 UI: Calling controller to add blood stock...');

      // We don't need to manually clear the error, the controller handles this
      final ok = await controller.addBloodStock(bloodStock);
      print('📋 UI: Controller returned result: $ok');

      if (mounted) {
        // Get the controller state to access any error message
        final controllerState = ref.read(bloodStockControllerProvider);
        final hasError = controllerState.error != null && controllerState.error!.isNotEmpty;
        final String errorMessage = hasError
            ? controllerState.error!
            : 'Erreur lors de l\'enregistrement';

        print('📋 UI: Final operation result: $ok');
        print('📋 UI: Controller state has error: $hasError');
        if (hasError) {
          print('❌ UI: Error message from controller: ${controllerState.error}');
        }

        // Double check: if we have an error message but 'ok' is true, something's wrong
        final bool actuallySucceeded = ok && !hasError;
        if (ok && hasError) {
          print('⚠️ UI: WARNING - Controller returned success but has error message!');
          print('⚠️ UI: Treating this as an error condition');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(actuallySucceeded
                ? 'blood_stock_saved_successfully'.tr
                : 'error_with_message'.trParams({'error': errorMessage})),
            backgroundColor: actuallySucceeded ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (actuallySucceeded) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_with_message'.trParams({'error': e.toString()})),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}