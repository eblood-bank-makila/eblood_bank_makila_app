import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../../apps/widgets/ModernSpinnerWidget.dart';
import '../../business/model/BloodStock.dart';
import '../../business/model/BloodEnums.dart';
import '../../business/interactors/BloodBankController.dart';

// Helper class to represent a donor in the selector UI
class _Donor {
  final String id;
  final String name;
  final String number;
  final String phoneNumber;
  final String? photoUrl;

  const _Donor({
    required this.id,
    required this.name,
    required this.number,
    required this.phoneNumber,
    this.photoUrl,
  });
}

// Donor selector modal sheet
class _DonorSelectorSheet extends StatefulWidget {
  final String? initialDonorId;
  
  const _DonorSelectorSheet({this.initialDonorId});
  
  @override
  _DonorSelectorSheetState createState() => _DonorSelectorSheetState();
}

class _DonorSelectorSheetState extends State<_DonorSelectorSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSearchByPhone = false;
  bool _showFilters = false;
  
  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _hasMoreItems = true;
  final _scrollController = ScrollController();
  
  // List of donors (would normally come from API)
  final List<_Donor> _allDonors = [
    _Donor(id: 'DON-2025-001', name: 'Jean Konan', number: 'DN-001', phoneNumber: '0707070707', photoUrl: null),
    _Donor(id: 'DON-2025-002', name: 'Awa N\'Guessan', number: 'DN-002', phoneNumber: '0708080808', photoUrl: 'https://randomuser.me/api/portraits/women/44.jpg'),
    _Donor(id: 'DON-2025-003', name: 'Moussa Bamba', number: 'DN-003', phoneNumber: '0709090909', photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg'),
    _Donor(id: 'DON-2025-004', name: 'Fatou Coulibaly', number: 'DN-004', phoneNumber: '0701010101', photoUrl: 'https://randomuser.me/api/portraits/women/68.jpg'),
    _Donor(id: 'DON-2025-005', name: 'Ibrahim Touré', number: 'DN-005', phoneNumber: '0702020202', photoUrl: null),
    _Donor(id: 'DON-2025-006', name: 'Marie Kouadio', number: 'DN-006', phoneNumber: '0703030303', photoUrl: 'https://randomuser.me/api/portraits/women/54.jpg'),
    _Donor(id: 'DON-2025-007', name: 'Paul Diallo', number: 'DN-007', phoneNumber: '0704040404', photoUrl: 'https://randomuser.me/api/portraits/men/76.jpg'),
    _Donor(id: 'DON-2025-008', name: 'Aminata Sylla', number: 'DN-008', phoneNumber: '0705050505', photoUrl: null),
    _Donor(id: 'DON-2025-009', name: 'David Koné', number: 'DN-009', phoneNumber: '0706060606', photoUrl: 'https://randomuser.me/api/portraits/men/41.jpg'),
    _Donor(id: 'DON-2025-010', name: 'Mariam Ouattara', number: 'DN-010', phoneNumber: '0710101010', photoUrl: 'https://randomuser.me/api/portraits/women/33.jpg'),
    _Donor(id: 'DON-2025-011', name: 'Gabriel Yao', number: 'DN-011', phoneNumber: '0711111111', photoUrl: null),
    _Donor(id: 'DON-2025-012', name: 'Sonia Koffi', number: 'DN-012', phoneNumber: '0712121212', photoUrl: 'https://randomuser.me/api/portraits/women/22.jpg'),
    _Donor(id: 'DON-2025-013', name: 'François Bédié', number: 'DN-013', phoneNumber: '0713131313', photoUrl: null),
    _Donor(id: 'DON-2025-014', name: 'Raïssa Traoré', number: 'DN-014', phoneNumber: '0714141414', photoUrl: 'https://randomuser.me/api/portraits/women/81.jpg'),
    _Donor(id: 'DON-2025-015', name: 'Charles Yapi', number: 'DN-015', phoneNumber: '0715151515', photoUrl: 'https://randomuser.me/api/portraits/men/62.jpg'),
  ];
  
  // Filtered and paginated list
  List<_Donor> _displayedDonors = [];

  @override
  void initState() {
    super.initState();
    _loadInitialDonors();
    
    // Add scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoading && _hasMoreItems) {
        _loadMoreDonors();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _loadInitialDonors() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _currentPage = 1;
        _applyFilters();
        _isLoading = false;
      });
    });
  }
  
  void _loadMoreDonors() {
    if (_isLoading || !_hasMoreItems) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call for next page
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _currentPage++;
        _applyFilters();
        _isLoading = false;
      });
    });
  }
  
  void _applyFilters() {
    // Filter donors based on search query
    final List<_Donor> filteredList = _searchQuery.isEmpty 
        ? List.from(_allDonors)
        : _allDonors.where((donor) {
            if (_isSearchByPhone) {
              return donor.phoneNumber.contains(_searchQuery);
            } else {
              return donor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                     donor.number.toLowerCase().contains(_searchQuery.toLowerCase());
            }
          }).toList();
    
    // Apply pagination
    final int startIndex = 0;
    final int endIndex = _currentPage * _itemsPerPage;
    
    _displayedDonors = filteredList.sublist(
      startIndex, 
      endIndex < filteredList.length ? endIndex : filteredList.length
    );
    
    _hasMoreItems = endIndex < filteredList.length;
  }
  
  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _loadInitialDonors();
    });
  }
  
  @override
  Widget build(BuildContext context) {
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
              // Handle and title
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40, 
                        height: 4, 
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300, 
                          borderRadius: BorderRadius.circular(2)
                        )
                      )
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sélectionner un Donneur',
                      style: GoogleFonts.ubuntu(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
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
                      decoration: InputDecoration(
                        hintText: _isSearchByPhone 
                            ? 'Rechercher par numéro de téléphone...' 
                            : 'Rechercher par nom ou numéro...',
                        prefixIcon: const Icon(Iconsax.search_normal),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showFilters ? Iconsax.filter_remove : Iconsax.filter_add,
                            color: _showFilters ? ColorPages.COLOR_PRINCIPAL : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: _onSearch,
                    ),
                    
                    // Filter options
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _showFilters ? 60 : 0,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('Par téléphone'),
                                selected: _isSearchByPhone,
                                onSelected: (selected) {
                                  setState(() {
                                    _isSearchByPhone = selected;
                                    _onSearch(_searchController.text);
                                  });
                                },
                                selectedColor: ColorPages.COLOR_PRINCIPAL.withOpacity(0.2),
                                checkmarkColor: ColorPages.COLOR_PRINCIPAL,
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Donneur avec photo'),
                                selected: false,  // Not implemented in demo
                                onSelected: (selected) {
                                  // Would filter donors with photos
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Donor list
              Expanded(
                child: _isLoading && _displayedDonors.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _displayedDonors.length + 2, // +1 for loading indicator, +1 for "No donor" option
                        itemBuilder: (context, index) {
                          // First item is "No donor" option
                          if (index == 0) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade200,
                                child: Icon(Icons.close, color: Colors.grey.shade700),
                              ),
                              title: const Text('Aucun donneur'),
                              subtitle: const Text('Don anonyme ou sans donneur associé'),
                              onTap: () => Navigator.pop(context, null),
                            );
                          }
                          
                          // Last item is loading indicator
                          if (index == _displayedDonors.length + 1) {
                            return _hasMoreItems
                                ? Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    alignment: Alignment.center,
                                    child: _isLoading
                                        ? const CircularProgressIndicator(strokeWidth: 2)
                                        : const SizedBox(),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Fin de la liste',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  );
                          }
                          
                          // Normal donor items
                          final donor = _displayedDonors[index - 1]; // -1 because index 0 is "No donor" option
                          final isSelected = donor.id == widget.initialDonorId;
                          
                          return ListTile(
                            leading: donor.photoUrl != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(donor.photoUrl!),
                                    onBackgroundImageError: (_, __) => const Icon(Icons.error),
                                  )
                                : const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(
                              donor.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${donor.number}'),
                                Text('Tél: ${donor.phoneNumber}'),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: ColorPages.COLOR_PRINCIPAL)
                                : null,
                            onTap: () => Navigator.pop(context, donor),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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
  final _batchNumberController = TextEditingController();
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
  void dispose() {
    _batchNumberController.dispose();
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
        'Ajouter Stock de Sang',
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
            'Enregistrer',
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
            'Type de Sang',
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
            'Informations de Base',
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
            label: 'Volume de Sang (ml)',
            hint: 'Ex: 450',
            icon: Iconsax.weight,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le volume est requis';
              }
              if (double.tryParse(value) == null) {
                return 'Le volume doit être un nombre';
              }
              if (double.parse(value) <= 0) {
                return 'Le volume doit être supérieur à 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Batch Number
          _buildTextField(
            controller: _batchNumberController,
            label: 'Numéro de Lot',
            hint: 'Ex: BT-2024-001',
            icon: Iconsax.barcode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le numéro de lot est requis';
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
            'Dates',
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          
          // Collection Date
          _buildDateField(
            label: 'Date de Collecte',
            date: _collectionDate,
            icon: Iconsax.calendar,
            onTap: () => _selectDate(context, true),
          ),
          const SizedBox(height: 16),
          
          // Expiration Date
          _buildDateField(
            label: 'Date d\'Expiration',
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
            'Informations Supplémentaires',
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
              labelText: 'Description (optionnel)',
              hintText: 'Informations supplémentaires sur ce stock...',
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
            'Type de Produit Sanguin',
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
              labelText: 'Type de Produit',
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
                child: Text(BloodProductType.wholeBlood.displayName),
              ),
              DropdownMenuItem(
                value: BloodProductType.plasma,
                child: Text(BloodProductType.plasma.displayName),
              ),
              DropdownMenuItem(
                value: BloodProductType.platelets,
                child: Text(BloodProductType.platelets.displayName),
              ),
              DropdownMenuItem(
                value: BloodProductType.redBloodCells,
                child: Text(BloodProductType.redBloodCells.displayName),
              ),
              
              // Add more categories with headers
              const DropdownMenuItem(
                enabled: false,
                child: Divider(height: 1),
              ),
              const DropdownMenuItem(
                enabled: false,
                child: Text('Produits dérivés du plasma',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DropdownMenuItem(
                value: BloodProductType.cryoprecipitate,
                child: Text(BloodProductType.cryoprecipitate.displayName),
              ),
              DropdownMenuItem(
                value: BloodProductType.frozenPlasma,
                child: Text(BloodProductType.frozenPlasma.displayName),
              ),
              DropdownMenuItem(
                value: BloodProductType.freshFrozenPlasma,
                child: Text(BloodProductType.freshFrozenPlasma.displayName),
              ),
              
              // More specialized products
              const DropdownMenuItem(
                enabled: false,
                child: Divider(height: 1),
              ),
              const DropdownMenuItem(
                enabled: false,
                child: Text('Solutions et additifs',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DropdownMenuItem(
                value: BloodProductType.saline,
                child: Text(BloodProductType.saline.displayName),
              ),
              DropdownMenuItem(
                value: BloodProductType.acdSolution,
                child: Text(BloodProductType.acdSolution.displayName),
              ),
              DropdownMenuItem(
                value: BloodProductType.cpdSolution,
                child: Text(BloodProductType.cpdSolution.displayName),
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
            'État et Condition',
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
              labelText: 'Statut',
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
                      child: Text(status.displayName),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          
          // Condition Dropdown
          DropdownButtonFormField<BloodBagConditionStatus>(
            decoration: InputDecoration(
              labelText: 'Condition de la poche',
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
                      child: Text(condition.displayName),
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
                    'Donneur (optionnel)',
                    style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDonorName != null
                        ? '${_selectedDonorName!} • ${_selectedDonorNumber ?? ''}'
                        : 'Sélectionner un donneur',
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
    // We'll use this variable to store the selected donor
    final _Donor? selected = await showModalBottomSheet<_Donor>(
      context: context,
      isScrollControlled: true, // Allow the sheet to take up to 90% of screen height
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _DonorSelectorSheet(initialDonorId: _selectedDonorId),
    );

    if (selected != null) {
      setState(() {
        _selectedDonorId = selected.id;
        _selectedDonorName = selected.name;
        _selectedDonorNumber = selected.number;
      });
    } else {
      // User selected "Aucun donneur" - reset previous selection
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
                    '${date.day}/${date.month}/${date.year}',
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
              'Enregistrer le Stock',
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
      print('🩸 Batch Number: ${_batchNumberController.text}');
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
        batchNumber: _batchNumberController.text,
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
                ? 'Stock de sang enregistré avec succès' 
                : 'Erreur: $errorMessage'),
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
            content: Text('Erreur: $e'),
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