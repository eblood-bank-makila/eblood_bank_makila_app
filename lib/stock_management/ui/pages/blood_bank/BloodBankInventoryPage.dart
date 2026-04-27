import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../apps/config/theme/ColorPages.dart';

class BloodBankInventoryPage extends ConsumerStatefulWidget {
  const BloodBankInventoryPage({super.key});

  @override
  ConsumerState<BloodBankInventoryPage> createState() => _BloodBankInventoryPageState();
}

class _BloodBankInventoryPageState extends ConsumerState<BloodBankInventoryPage> {
  String selectedFilter = 'Tous';
  final List<String> filters = ['Tous', 'Stock Faible', 'Stock Critique', 'Stock Normal'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Filter Section
            _buildFilterSection(),
            
            // Inventory List
            Expanded(
              child: _buildInventoryList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventory_list_add_stock_fab',
        onPressed: () {
          // Add new blood stock
        },
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: Text(
          'Ajouter Stock',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventaire',
                    style: GoogleFonts.ubuntu(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestion des stocks de sang',
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.box,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return FadeInLeft(
      delay: const Duration(milliseconds: 400),
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = selectedFilter == filter;
            
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(
                  filter,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: ColorPages.COLOR_PRINCIPAL,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade300,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _getBloodStockData().length,
        itemBuilder: (context, index) {
          final stock = _getBloodStockData()[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildStockCard(stock),
          );
        },
      ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> stock) {
    final stockLevel = _getStockLevel(stock['quantity'] as int);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Blood Type Circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    stock['bloodType'],
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Stock Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Groupe ${stock['bloodType']}',
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stockLevel['color'].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stockLevel['label'],
                            style: GoogleFonts.ubuntu(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: stockLevel['color'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Iconsax.box_1,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stock['quantity']} unités disponibles',
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Niveau de stock',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${stock['quantity']}/100',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (stock['quantity'] as int) / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(stockLevel['color']),
                minHeight: 6,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Edit stock
                  },
                  icon: const Icon(Iconsax.edit, size: 16),
                  label: Text(
                    'Modifier',
                    style: GoogleFonts.ubuntu(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPages.COLOR_PRINCIPAL,
                    side: BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Add stock
                  },
                  icon: const Icon(Iconsax.add, size: 16),
                  label: Text(
                    'Ajouter',
                    style: GoogleFonts.ubuntu(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStockLevel(int quantity) {
    if (quantity <= 10) {
      return {'label': 'Critique', 'color': Colors.red};
    } else if (quantity <= 25) {
      return {'label': 'Faible', 'color': Colors.orange};
    } else {
      return {'label': 'Normal', 'color': Colors.green};
    }
  }

  List<Map<String, dynamic>> _getBloodStockData() {
    return [
      {'bloodType': 'O+', 'quantity': 45},
      {'bloodType': 'A+', 'quantity': 32},
      {'bloodType': 'B+', 'quantity': 28},
      {'bloodType': 'AB+', 'quantity': 15},
      {'bloodType': 'O-', 'quantity': 8},
      {'bloodType': 'A-', 'quantity': 12},
      {'bloodType': 'B-', 'quantity': 6},
      {'bloodType': 'AB-', 'quantity': 4},
    ];
  }
}
