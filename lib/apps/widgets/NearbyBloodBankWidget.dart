import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/config/utils/Utils.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/poche/ListePocheBanquePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enhanced widget for displaying nearby blood banks with inventory information
class NearbyBloodBankWidget extends ConsumerWidget {
  final BanqueModele banque;
  final Map<String, dynamic>? inventorySummary; // Additional inventory data from API
  final String authToken;

  const NearbyBloodBankWidget({
    Key? key,
    required this.banque,
    this.inventorySummary,
    required this.authToken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListePocheBanquePage(
                banqueId: banque.id,
                banque: banque,
                banqueNom: banque.blood_bank_name,
                localisation: banque.townInfo.townName,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with logo and info
                    Row(
                      children: [
                        // Logo
                        _buildLogo(),
                        const SizedBox(width: 16),
                        // Bank info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bank name
                              Text(
                                banque.blood_bank_name.capitalizeFirstLetter(),
                                style: GoogleFonts.ubuntu(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Location
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.location,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      banque.townInfo.townName.capitalizeFirstLetter(),
                                      style: GoogleFonts.ubuntu(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Distance badge
                        if (banque.distance != null) _buildDistanceBadge(),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Inventory summary section
                    if (inventorySummary != null) _buildInventorySummary(),
                  ],
                ),
              ),

              // Action button
              _buildActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          banque.blood_bank_logo,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.hospital,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 32,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDistanceBadge() {
    final distance = double.tryParse(banque.distance ?? '0') ?? 0;
    final color = _getDistanceColor(distance);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.routing_2,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            _formatDistance(distance),
            style: GoogleFonts.ubuntu(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySummary() {
    final totalBags = inventorySummary!['total_bags'] ?? 0;
    final bloodTypes = (inventorySummary!['available_blood_types'] as List?)?.cast<String>() ?? [];
    final productTypes = (inventorySummary!['product_types'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorPages.COLOR_PRINCIPAL.withOpacity(0.05),
            ColorPages.COLOR_PRINCIPAL.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Iconsax.health,
                  color: ColorPages.COLOR_PRINCIPAL,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Available Stock',
                style: GoogleFonts.ubuntu(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalBags bags',
                  style: GoogleFonts.ubuntu(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Blood types
          if (bloodTypes.isNotEmpty) ...[
            Text(
              'Blood Types:',
              style: GoogleFonts.ubuntu(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bloodTypes.map((type) => _buildBloodTypeBadge(type)).toList(),
            ),
          ],

          if (productTypes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Products:',
              style: GoogleFonts.ubuntu(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: productTypes.map((type) => _buildProductTypeBadge(type)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBloodTypeBadge(String bloodType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Text(
        bloodType,
        style: GoogleFonts.ubuntu(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _buildProductTypeBadge(String productType) {
    final formatted = _formatProductType(productType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Text(
        formatted,
        style: GoogleFonts.ubuntu(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListePocheBanquePage(
                  banqueId: banque.id,
                  banque: banque,
                  banqueNom: banque.blood_bank_name,
                  localisation: banque.townInfo.townName,
                ),
              ),
            );
          },
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Blood Bags',
                  style: GoogleFonts.ubuntu(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDistanceColor(double distance) {
    if (distance < 5) return Colors.green;
    if (distance < 15) return Colors.orange;
    return Colors.red;
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    } else if (distance < 10) {
      return '${distance.toStringAsFixed(1)}km';
    } else {
      return '${distance.toStringAsFixed(0)}km';
    }
  }

  String _formatProductType(String type) {
    switch (type.toLowerCase()) {
      case 'whole_blood':
        return 'Whole Blood';
      case 'plasma':
        return 'Plasma';
      case 'platelets':
        return 'Platelets';
      case 'red_blood_cells':
        return 'Red Blood Cells';
      default:
        return type;
    }
  }
}

