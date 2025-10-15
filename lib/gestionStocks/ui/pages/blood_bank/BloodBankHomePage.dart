import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../apps/config/theme/ColorPages.dart';

class BloodBankHomePage extends ConsumerStatefulWidget {
  const BloodBankHomePage({super.key});

  @override
  ConsumerState<BloodBankHomePage> createState() => _BloodBankHomePageState();
}

class _BloodBankHomePageState extends ConsumerState<BloodBankHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Stats Cards
              _buildStatsSection(),
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActionsSection(),
              const SizedBox(height: 24),
              
              // Recent Requests
              _buildRecentRequestsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Banque de Sang',
                  style: GoogleFonts.ubuntu(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tableau de bord',
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
              Iconsax.hospital,
              color: ColorPages.COLOR_PRINCIPAL,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          delay: const Duration(milliseconds: 400),
          child: Text(
            'Statistiques',
            style: GoogleFonts.ubuntu(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: _buildStatCard(
                  title: 'Demandes Totales',
                  value: '156',
                  icon: Iconsax.document_text,
                  color: Colors.blue,
                  trend: '+12%',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: _buildStatCard(
                  title: 'En Attente',
                  value: '23',
                  icon: Iconsax.clock,
                  color: Colors.orange,
                  trend: '+5%',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: _buildStatCard(
                  title: 'Livrées',
                  value: '89',
                  icon: Iconsax.tick_circle,
                  color: Colors.green,
                  trend: '+8%',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: _buildStatCard(
                  title: 'Stock Critique',
                  value: '4',
                  icon: Iconsax.warning_2,
                  color: Colors.red,
                  trend: '-2%',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                trend,
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: trend.startsWith('+') ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.ubuntu(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          delay: const Duration(milliseconds: 900),
          child: Text(
            'Actions Rapides',
            style: GoogleFonts.ubuntu(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 1000),
                child: _buildActionCard(
                  title: 'Gérer Stock',
                  subtitle: 'Inventaire',
                  icon: Iconsax.box,
                  color: ColorPages.COLOR_PRINCIPAL,
                  onTap: () {
                    // Navigate to inventory
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 1100),
                child: _buildActionCard(
                  title: 'Demandes',
                  subtitle: 'Voir tout',
                  icon: Iconsax.document_text,
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to requests
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          delay: const Duration(milliseconds: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Demandes Récentes',
                style: GoogleFonts.ubuntu(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all requests
                },
                child: Text(
                  'Voir tout',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: ColorPages.COLOR_PRINCIPAL,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FadeInUp(
          delay: const Duration(milliseconds: 1300),
          child: Container(
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
                _buildRequestItem(
                  hospitalName: 'Hôpital Central',
                  bloodType: 'O+',
                  quantity: '2 unités',
                  status: 'En attente',
                  statusColor: Colors.orange,
                ),
                const Divider(height: 1),
                _buildRequestItem(
                  hospitalName: 'Clinique Saint-Joseph',
                  bloodType: 'A-',
                  quantity: '1 unité',
                  status: 'Approuvée',
                  statusColor: Colors.green,
                ),
                const Divider(height: 1),
                _buildRequestItem(
                  hospitalName: 'Hôpital Universitaire',
                  bloodType: 'B+',
                  quantity: '3 unités',
                  status: 'En cours',
                  statusColor: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestItem({
    required String hospitalName,
    required String bloodType,
    required String quantity,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
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
                bloodType,
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
                  hospitalName,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quantity,
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
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: GoogleFonts.ubuntu(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
