import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/DetailsPocheBanqueWidget.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../gestionStocks/business/model/poche/PocheModel.dart';

class PocheBanqueWidget extends ConsumerWidget {
  final PocheModel poches;
  final BanqueModele banque;

  PocheBanqueWidget({required this.poches, required this.banque});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPocheBanqueWidget(
                poche: poches,
                banqueNom: banque.blood_bank_name,
                banque: banque,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(width: 1, color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Blood Type Badge + Product Type
                Row(
                  children: [
                    // Blood Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getBloodTypeColor(poches).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getBloodTypeColor(poches),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        "${poches.bloodBagInfo.bloodTypeInfo.bloodTypeName}${poches.bloodBagInfo.bloodRhesusInfo.bloodRheususName}",
                        style: TextStyle(
                          color: _getBloodTypeColor(poches),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Product Type Badge
                    if (poches.bloodProductType != null)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getProductTypeColor(poches.bloodProductType!).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatProductType(poches.bloodProductType!),
                            style: TextStyle(
                              color: _getProductTypeColor(poches.bloodProductType!),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    // Status Badge
                    if (poches.status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(poches.status!).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(poches.status!),
                              size: 12,
                              color: _getStatusColor(poches.status!),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatStatus(poches.status!),
                              style: TextStyle(
                                color: _getStatusColor(poches.status!),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Details Row
                Row(
                  children: [
                    // Volume Info
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.water_drop_outlined,
                        label: 'volume'.tr,
                        value: poches.bloodBagInfo.bloodVolumeInfo.bloodVolumeName,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Batch Number
                    if (poches.batchNumber != null)
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.qr_code_2,
                          label: 'batch'.tr,
                          value: poches.batchNumber!,
                          color: Colors.purple,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Expiry Info Row
                if (poches.daysUntilExpiry != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getExpiryColor(poches.daysUntilExpiry!).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getExpiryColor(poches.daysUntilExpiry!).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: _getExpiryColor(poches.daysUntilExpiry!),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getExpiryText(poches.daysUntilExpiry!),
                            style: TextStyle(
                              color: _getExpiryColor(poches.daysUntilExpiry!),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Condition Badge
                        if (poches.bloodBagCondition != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getConditionColor(poches.bloodBagCondition!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatCondition(poches.bloodBagCondition!),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build info chips
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Get blood type color
  Color _getBloodTypeColor(PocheModel poche) {
    final bloodType = poche.bloodBagInfo.bloodTypeInfo.bloodTypeName;
    switch (bloodType) {
      case 'A':
        return Colors.red;
      case 'B':
        return Colors.blue;
      case 'AB':
        return Colors.purple;
      case 'O':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get product type color
  Color _getProductTypeColor(String productType) {
    switch (productType.toLowerCase()) {
      case 'whole_blood':
        return Colors.red.shade700;
      case 'plasma':
        return Colors.amber.shade700;
      case 'platelets':
        return Colors.orange.shade700;
      case 'red_blood_cells':
        return Colors.red.shade900;
      case 'white_blood_cells':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Format product type
  String _formatProductType(String productType) {
    // Try to get translation, fallback to formatted string
    final translationKey = productType.toLowerCase();
    final translated = translationKey.tr;

    // If translation exists (not same as key), return it
    if (translated != translationKey) {
      return translated;
    }

    // Otherwise format the string
    return productType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.blue;
      case 'expired':
        return Colors.red;
      case 'used':
        return Colors.grey;
      case 'tested_safe':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle;
      case 'reserved':
        return Icons.bookmark;
      case 'expired':
        return Icons.warning;
      case 'used':
        return Icons.done_all;
      case 'tested_safe':
        return Icons.verified;
      default:
        return Icons.info;
    }
  }

  // Format status
  String _formatStatus(String status) {
    // Try to get translation, fallback to formatted string
    final translationKey = status.toLowerCase();
    final translated = translationKey.tr;

    // If translation exists (not same as key), return it
    if (translated != translationKey) {
      return translated;
    }

    // Otherwise format the string
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Get expiry color based on days
  Color _getExpiryColor(int days) {
    if (days <= 7) {
      return Colors.red;
    } else if (days <= 14) {
      return Colors.orange;
    } else if (days <= 30) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  // Get expiry text
  String _getExpiryText(int days) {
    if (days <= 0) {
      return 'expired_label'.tr;
    } else if (days == 1) {
      return 'expires_in_day'.tr;
    } else if (days <= 7) {
      return 'expires_critical'.trParams({'days': days.toString()});
    } else if (days <= 14) {
      return 'expires_soon'.trParams({'days': days.toString()});
    } else {
      return 'expires_in_days'.trParams({'days': days.toString()});
    }
  }

  // Get condition color
  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Colors.green.shade700;
      case 'good':
        return Colors.teal.shade600;
      case 'fair':
        return Colors.orange.shade600;
      case 'poor':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  // Format condition
  String _formatCondition(String condition) {
    // Try to get translation, fallback to formatted string
    final translationKey = condition.toLowerCase();
    final translated = translationKey.tr;

    // If translation exists (not same as key), return it
    if (translated != translationKey) {
      return translated;
    }

    // Otherwise format the string
    return condition[0].toUpperCase() + condition.substring(1).toLowerCase();
  }
}
