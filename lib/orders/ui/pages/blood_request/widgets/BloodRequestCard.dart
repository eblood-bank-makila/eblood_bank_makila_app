import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../../apps/config/theme/ColorPages.dart';
import '../../../../business/model/blood_request/BloodRequestModel.dart';
import '../../../../business/interactor/usecase/blood_request/BloodRequestUseCase.dart';
import '../../../../business/interactor/usecase/blood_request/BloodRequestTrackingUseCase.dart';
import '../../../../business/interactor/usecase/delivery_position/DeliveryPositionUseCase.dart';
import '../BloodRequestTrackingPage.dart';
import '../../delivery_position/DeliveryPositionPage.dart';
import 'DeliveryConfirmationDialog.dart';
import 'BloodBagUsageDialog.dart';
import 'CoolboxPasswordDialog.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import '../../../../../apps/config/AppConfig.dart';
import '../../../framework/delivery/DeliveryValidationNetworkServiceImpl.dart';
import '../../../../../users/ui/framework/UtilisateurLocalServiceImpl.dart';

class BloodRequestCard extends StatelessWidget {
  final BloodRequestModel request;
  final VoidCallback? onTap;
  final VoidCallback? onActionCompleted;

  const BloodRequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.onActionCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            // If request can be tracked, navigate to tracking page
            if (BloodRequestTrackingUseCase.canTrackDelivery(request)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BloodRequestTrackingPage(request: request),
                ),
              );
            } else if (onTap != null) {
              // Otherwise use the provided onTap callback
              onTap!();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Status icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: BloodRequestUseCase.getStatusColor(request.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        BloodRequestUseCase.getStatusIcon(request.status),
                        color: BloodRequestUseCase.getStatusColor(request.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Request info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demande #${request.requestId}',
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ColorPages.COLOR_PRINCIPAL,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.hospitalName,
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: BloodRequestUseCase.getStatusColor(request.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        request.status.displayName,
                        style: GoogleFonts.ubuntu(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Blood type and quantity row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // Blood type
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Iconsax.heart,
                                color: ColorPages.COLOR_PRINCIPAL,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Type de sang',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  request.bloodType.isNotEmpty ? request.bloodType : 'N/A',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ColorPages.COLOR_PRINCIPAL,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),

                      const SizedBox(width: 16),

                      // Quantity
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Iconsax.box,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quantité',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '${request.quantity} unité${request.quantity > 1 ? 's' : ''}',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Date and amount row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          BloodRequestUseCase.formatDateTime(request.requestDate),
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    // GPS Tracking indicator and Amount
                    Row(
                      children: [
                        // GPS Tracking indicator
                        if (BloodRequestTrackingUseCase.canTrackDelivery(request))
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.location,
                                  size: 12,
                                  color: Colors.blue.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'GPS',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Delivery distance chip (only when delivery is in progress)
                        if (DeliveryPositionUseCase.canFetchPosition(request))
                          _DeliveryDistanceChip(request: request),


                        // Amount
                        if (request.totalAmount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '\$${request.totalAmount!.toStringAsFixed(2)}',
                              style: GoogleFonts.ubuntu(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // View Position Action for pending delivery
                if (DeliveryPositionUseCase.canFetchPosition(request)) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeliveryPositionPage(request: request),
                          ),
                        );
                      },
                      icon: Icon(
                        Iconsax.location,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Voir la position',
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],


                // Action buttons based on status
                const SizedBox(height: 12),
                if (request.status == BloodRequestStatus.inProgressDelivery) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => DeliveryConfirmationDialog(
                            request: request,
                            onSuccess: () {
                              if (onActionCompleted != null) onActionCompleted!();
                            },
                          ),
                        );
                      },
                      icon: const Icon(Iconsax.verify5, color: Colors.white, size: 18),
                      label: Text(
                        'confirm_delivery'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ]
                else if (request.status == BloodRequestStatus.delivered) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => BloodBagUsageDialog(
                            request: request,
                            onSuccess: () {
                              if (onActionCompleted != null) onActionCompleted!();
                            },
                          ),
                        );
                      },
                      icon: const Icon(Iconsax.bag_tick, color: Colors.white, size: 18),
                      label: Text(
                        'mark_bags_as_used'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (request.deliveryCoolboxId != null && request.deliveryCoolboxId!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Sprint 17 — the access gate requires a fresh
                          // QR-token scan from the coolbox sticker. Push
                          // the existing scanner page; it returns the
                          // raw barcode value (or null on cancel).
                          final scanned = await context.push<String>(
                            '/blood-search/qr-scanner',
                          );
                          if (!context.mounted) return;
                          if (scanned == null || scanned.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Scan annulé.'),
                              ),
                            );
                            return;
                          }
                          await showDialog(
                            context: context,
                            builder: (_) => CoolboxPasswordDialog(
                              request: request,
                              qrToken: scanned.trim(),
                            ),
                          );
                        },
                        icon: const Icon(Iconsax.lock, size: 18),
                        label: Text(
                          'request_coolbox_password'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.orange.shade600),
                          foregroundColor: Colors.orange.shade800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),


                      ),
                    ),
                ],

              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _DeliveryDistanceChip extends StatefulWidget {
  final BloodRequestModel request;
  const _DeliveryDistanceChip({required this.request});

  @override
  State<_DeliveryDistanceChip> createState() => _DeliveryDistanceChipState();
}

class _DeliveryDistanceChipState extends State<_DeliveryDistanceChip> {
  bool _loading = true;
  String? _error;
  String? _distanceText;
  int _distanceColor = 0xFF2196F3; // default blue

  @override
  void initState() {
    super.initState();
    _fetchDistance();
  }

  Future<void> _fetchDistance() async {
    if (!DeliveryPositionUseCase.canFetchPosition(widget.request)) {
      setState(() {
        _loading = false;
        _error = 'Position non disponible';
      });
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, "sembast.db");
      DatabaseFactory dbFactory = databaseFactoryIo;
      Database db = await dbFactory.openDatabase(dbPath);

      final baseUrl = AppConfig.instance.fullApiUrl;
      final network = QrCodeActionNetworkServiceImpl(baseUrl);
      final local = UtilisateurLocalServiceImpl(db);
      final useCase = DeliveryPositionUseCase(network, local);

      final res = await useCase.fetchPositionFromRequest(widget.request);
      if (mounted) {
        if (res != null && res.success && res.info != null) {
          final dKm = res.info!.distance;
          setState(() {
            _loading = false;
            _distanceText = DeliveryPositionUseCase.formatDistance(dKm);
            _distanceColor = DeliveryPositionUseCase.getDistanceColor(dKm);
            _error = null;
          });
        } else {
          setState(() {
            _loading = false;
            _error = res?.message ?? 'Position indisponible';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Erreur';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Distance...',
              style: GoogleFonts.ubuntu(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.location_slash, size: 12, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              'N/A',
              style: GoogleFonts.ubuntu(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color(_distanceColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Color(_distanceColor).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.routing, size: 12, color: Color(_distanceColor)),
          const SizedBox(width: 4),
          Text(
            _distanceText ?? '—',
            style: GoogleFonts.ubuntu(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(_distanceColor),
            ),
          ),
        ],
      ),
    );
  }
}
