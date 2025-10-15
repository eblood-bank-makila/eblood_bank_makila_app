import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import '../../../apps/config/theme/ColorPages.dart';

class DeliveryListPage extends ConsumerStatefulWidget {
  const DeliveryListPage({super.key});

  @override
  ConsumerState<DeliveryListPage> createState() => _DeliveryListPageState();
}

class _DeliveryListPageState extends ConsumerState<DeliveryListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab Bar
            _buildTabBar(),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingDeliveries(),
                  _buildDeliveredList(),
                ],
              ),
            ),
          ],
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
                    'Livraisons',
                    style: GoogleFonts.ubuntu(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gérer vos livraisons',
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
                Iconsax.truck_fast,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return FadeInLeft(
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: ColorPages.COLOR_PRINCIPAL,
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'En Attente'),
            Tab(text: 'Livrées'),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingDeliveries() {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _getPendingDeliveries().length,
        itemBuilder: (context, index) {
          final delivery = _getPendingDeliveries()[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildDeliveryCard(delivery, isPending: true),
          );
        },
      ),
    );
  }

  Widget _buildDeliveredList() {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _getDeliveredItems().length,
        itemBuilder: (context, index) {
          final delivery = _getDeliveredItems()[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildDeliveryCard(delivery, isPending: false),
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery, {required bool isPending}) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    delivery['bloodType'],
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery['destination'],
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${delivery['quantity']} • ${delivery['distance']}',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: delivery['statusColor'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  delivery['status'],
                  style: GoogleFonts.ubuntu(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: delivery['statusColor'],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Details Row
          Row(
            children: [
              Icon(
                Iconsax.location,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  delivery['address'],
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Iconsax.clock,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                isPending ? 'Estimé: ${delivery['estimatedTime']}' : 'Livré: ${delivery['deliveredTime']}',
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // View details
                    },
                    icon: const Icon(Iconsax.eye, size: 16),
                    label: Text(
                      'Détails',
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
                      // Start delivery
                    },
                    icon: const Icon(Iconsax.play, size: 16),
                    label: Text(
                      'Commencer',
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
          ] else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Iconsax.tick_circle,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'Livraison confirmée',
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // View receipt
                  },
                  child: Text(
                    'Voir reçu',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: ColorPages.COLOR_PRINCIPAL,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getPendingDeliveries() {
    return [
      {
        'destination': 'Hôpital Central',
        'bloodType': 'O+',
        'quantity': '2 unités',
        'distance': '2.5 km',
        'address': '123 Avenue de la Paix, Kinshasa',
        'estimatedTime': '15 min',
        'status': 'Assigné',
        'statusColor': Colors.blue,
      },
      {
        'destination': 'Clinique Saint-Joseph',
        'bloodType': 'A-',
        'quantity': '1 unité',
        'distance': '4.2 km',
        'address': '456 Rue de la Santé, Kinshasa',
        'estimatedTime': '25 min',
        'status': 'En route',
        'statusColor': Colors.orange,
      },
      {
        'destination': 'Hôpital Universitaire',
        'bloodType': 'B+',
        'quantity': '3 unités',
        'distance': '1.8 km',
        'address': '789 Boulevard Médical, Kinshasa',
        'estimatedTime': '12 min',
        'status': 'Collecté',
        'statusColor': Colors.purple,
      },
    ];
  }

  List<Map<String, dynamic>> _getDeliveredItems() {
    return [
      {
        'destination': 'Hôpital Général',
        'bloodType': 'AB+',
        'quantity': '1 unité',
        'distance': '3.1 km',
        'address': '321 Avenue Médicale, Kinshasa',
        'deliveredTime': 'Aujourd\'hui 14:30',
        'status': 'Livré',
        'statusColor': Colors.green,
      },
      {
        'destination': 'Clinique Moderne',
        'bloodType': 'O-',
        'quantity': '2 unités',
        'distance': '5.7 km',
        'address': '654 Rue de l\'Espoir, Kinshasa',
        'deliveredTime': 'Aujourd\'hui 11:45',
        'status': 'Livré',
        'statusColor': Colors.green,
      },
      {
        'destination': 'Centre Médical',
        'bloodType': 'A+',
        'quantity': '1 unité',
        'distance': '2.3 km',
        'address': '987 Place de la Santé, Kinshasa',
        'deliveredTime': 'Hier 16:20',
        'status': 'Livré',
        'statusColor': Colors.green,
      },
    ];
  }
}
