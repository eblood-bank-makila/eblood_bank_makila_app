import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../../core/rbac/services/rbac_guard.dart';
import '../config/theme/ColorPages.dart';
import '../config/api/dio_client.dart';

class CustomerTopDonorsPage extends ConsumerStatefulWidget {
  const CustomerTopDonorsPage({super.key});

  @override
  ConsumerState<CustomerTopDonorsPage> createState() => _CustomerTopDonorsPageState();
}

class _CustomerTopDonorsPageState extends ConsumerState<CustomerTopDonorsPage> {
  @override
  void initState() {
    super.initState();
    // RBAC entry guard.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_cust_home_top_donors',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('top_donors'.tr, style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
          bottom: TabBar(
            labelStyle: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'worldwide'.tr),
              Tab(text: 'local'.tr),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TopDonorList(scope: 'worldwide'),
            _TopDonorList(scope: 'local'),
          ],
        ),
      ),
    );
  }
}

class _TopDonorList extends StatefulWidget {
  final String scope;
  const _TopDonorList({required this.scope});

  @override
  State<_TopDonorList> createState() => _TopDonorListState();
}

class _TopDonorListState extends State<_TopDonorList> {
  bool _loading = true;
  List<Map<String, dynamic>> _donors = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTopDonors();
  }

  Future<void> _fetchTopDonors() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await getWithDio(
        '/eblood-connect/blood-donors/top-donors',
        queryParams: {
          'scope': widget.scope,
          'limit': '20',
          'time_period': 'all',
        },
      );

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map && data['top_donors'] is List) {
          setState(() {
            _donors = (data['top_donors'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
            _loading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(response.message ?? 'Failed to load top donors');
      }
    } catch (e) {
      debugPrint('Error fetching top donors: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'failed_to_load_donors'.tr,
              style: GoogleFonts.ubuntu(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fetchTopDonors,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
            ),
          ],
        ),
      );
    }

    if (_donors.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchTopDonors,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.crown, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'no_donors_found'.tr,
                    style: GoogleFonts.ubuntu(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'pull_to_refresh'.tr,
                    style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTopDonors,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _donors.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final donor = _donors[index];
          final rank = index + 1;
          
          // Extract blood type
          final bloodType = donor['blood_type'] is Map
              ? (donor['blood_type']['name'] ?? 'Unknown')
              : 'Unknown';
          
          // Extract name
          final firstName = donor['first_name'] ?? '';
          final lastName = donor['last_name'] ?? '';
          final name = '$firstName $lastName'.trim();
          
          // Extract donations count
          final donations = donor['total_donations'] ?? 0;
          
          // Extract badge
          final badge = donor['badge'] is Map
              ? (donor['badge']['name'] ?? 'No Badge')
              : 'No Badge';
          
          return _DonorTile(
            rank: rank,
            name: name.isNotEmpty ? name : 'donor'.tr,
            blood: bloodType.toString(),
            donations: donations as int,
            badge: badge.toString(),
            profilePhotoUrl: donor['profile_photo_url'],
            donorCode: donor['donor_code'] ?? '',
            lastDonationDate: donor['last_donation_date'],
          );
        },
      ),
    );
  }
}

class _DonorTile extends StatelessWidget {
  final int rank;
  final String name;
  final String blood;
  final int donations;
  final String badge;
  final String? profilePhotoUrl;
  final String donorCode;
  final String? lastDonationDate;

  const _DonorTile({
    required this.rank,
    required this.name,
    required this.blood,
    required this.donations,
    required this.badge,
    this.profilePhotoUrl,
    required this.donorCode,
    this.lastDonationDate,
  });

  Color _medalColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // gold
      case 2:
        return const Color(0xFFC0C0C0); // silver
      case 3:
        return const Color(0xFFCD7F32); // bronze
      default:
        return ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _medalColor(rank),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: rank <= 3
                    ? Icon(Iconsax.crown, color: rank == 1 ? Colors.black : Colors.white, size: 22)
                    : Text('$rank', style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ubuntu(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _chip(blood, theme),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Iconsax.medal, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          badge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _chip('${donations}x', theme, icon: Icons.volunteer_activism),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, ThemeData theme, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: ColorPages.COLOR_PRINCIPAL),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.ubuntu(fontSize: 12, color: ColorPages.COLOR_PRINCIPAL, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _medalColor(rank),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: profilePhotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              profilePhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Center(child: Icon(Iconsax.user, color: Colors.white)),
                            ),
                          )
                        : const Center(child: Icon(Iconsax.user, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(donorCode, style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  _chip(blood, Theme.of(context)),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(Iconsax.medal, 'Badge', badge),
              const SizedBox(height: 12),
              _detailRow(Icons.volunteer_activism, 'Total Donations', '$donations'),
              if (lastDonationDate != null) ...[
                const SizedBox(height: 12),
                _detailRow(Icons.calendar_today, 'Last Donation', _formatDate(lastDonationDate!)),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('close'.tr),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: ColorPages.COLOR_PRINCIPAL, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.ubuntu(fontSize: 14, color: Colors.grey.shade600)),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

