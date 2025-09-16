import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import '../../../apps/config/theme/ColorPages.dart';

enum RequestStatus {
  pending,
  approved,
  rejected,
  completed,
}

enum RequestFilter {
  all,
  pending,
  approved,
  urgent,
}

class BloodBankRequestsPage extends ConsumerStatefulWidget {
  const BloodBankRequestsPage({super.key});

  @override
  ConsumerState<BloodBankRequestsPage> createState() => _BloodBankRequestsPageState();
}

class _BloodBankRequestsPageState extends ConsumerState<BloodBankRequestsPage> {
  RequestFilter _selectedFilter = RequestFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
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
            
            // Search and Filter
            _buildSearchAndFilter(),
            
            // Requests List
            Expanded(
              child: _buildRequestsList(),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demandes de Sang',
                    style: GoogleFonts.ubuntu(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getFilteredRequests().length} demandes',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
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
                Iconsax.document_text,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher par hôpital ou type de sang...',
                  hintStyle: GoogleFonts.ubuntu(
                    color: Colors.grey.shade600,
                  ),
                  prefixIcon: Icon(
                    Iconsax.search_normal,
                    color: Colors.grey.shade600,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: RequestFilter.values.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getFilterLabel(filter)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                      labelStyle: GoogleFonts.ubuntu(
                        color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    final filteredRequests = _getFilteredRequests();
    
    if (filteredRequests.isEmpty) {
      return FadeInUp(
        delay: const Duration(milliseconds: 400),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.document_text,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune demande trouvée',
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez de modifier vos filtres',
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          final request = filteredRequests[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildRequestCard(request),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] as RequestStatus;
    final statusInfo = _getStatusInfo(status);
    final isUrgent = request['isUrgent'] as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUrgent ? Border.all(color: Colors.red.shade300, width: 2) : null,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          request['hospitalName'],
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        if (isUrgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'URGENT',
                              style: GoogleFonts.ubuntu(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request['requestId'],
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusInfo['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusInfo['label'],
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusInfo['color'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Blood Type and Quantity
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    request['bloodType'],
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
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
                      '${request['quantity']} unités demandées',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Demandé le ${request['requestDate']}',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          if (status == RequestStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(request),
                    icon: const Icon(Iconsax.close_circle, size: 16),
                    label: Text(
                      'Rejeter',
                      style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRequest(request),
                    icon: const Icon(Iconsax.tick_circle, size: 16),
                    label: Text(
                      'Approuver',
                      style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  String _getFilterLabel(RequestFilter filter) {
    switch (filter) {
      case RequestFilter.all:
        return 'Toutes';
      case RequestFilter.pending:
        return 'En attente';
      case RequestFilter.approved:
        return 'Approuvées';
      case RequestFilter.urgent:
        return 'Urgentes';
    }
  }

  Map<String, dynamic> _getStatusInfo(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return {'label': 'En attente', 'color': Colors.orange};
      case RequestStatus.approved:
        return {'label': 'Approuvée', 'color': Colors.green};
      case RequestStatus.rejected:
        return {'label': 'Rejetée', 'color': Colors.red};
      case RequestStatus.completed:
        return {'label': 'Terminée', 'color': Colors.blue};
    }
  }

  List<Map<String, dynamic>> _getFilteredRequests() {
    List<Map<String, dynamic>> requests = _getAllRequests();
    
    // Apply filter
    switch (_selectedFilter) {
      case RequestFilter.pending:
        requests = requests.where((r) => r['status'] == RequestStatus.pending).toList();
        break;
      case RequestFilter.approved:
        requests = requests.where((r) => r['status'] == RequestStatus.approved).toList();
        break;
      case RequestFilter.urgent:
        requests = requests.where((r) => r['isUrgent'] == true).toList();
        break;
      case RequestFilter.all:
        break;
    }
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      requests = requests.where((r) {
        final hospitalName = r['hospitalName'].toString().toLowerCase();
        final bloodType = r['bloodType'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return hospitalName.contains(query) || bloodType.contains(query);
      }).toList();
    }
    
    return requests;
  }

  List<Map<String, dynamic>> _getAllRequests() {
    return [
      {
        'requestId': 'REQ-001',
        'hospitalName': 'Hôpital Central',
        'bloodType': 'O+',
        'quantity': 3,
        'requestDate': '15 Jan 2024',
        'status': RequestStatus.pending,
        'isUrgent': true,
      },
      {
        'requestId': 'REQ-002',
        'hospitalName': 'Clinique Saint-Joseph',
        'bloodType': 'A-',
        'quantity': 2,
        'requestDate': '14 Jan 2024',
        'status': RequestStatus.approved,
        'isUrgent': false,
      },
      {
        'requestId': 'REQ-003',
        'hospitalName': 'Hôpital Universitaire',
        'bloodType': 'B+',
        'quantity': 1,
        'requestDate': '13 Jan 2024',
        'status': RequestStatus.completed,
        'isUrgent': false,
      },
      {
        'requestId': 'REQ-004',
        'hospitalName': 'Centre Médical Moderne',
        'bloodType': 'AB-',
        'quantity': 4,
        'requestDate': '12 Jan 2024',
        'status': RequestStatus.pending,
        'isUrgent': true,
      },
      {
        'requestId': 'REQ-005',
        'hospitalName': 'Hôpital Pédiatrique',
        'bloodType': 'O-',
        'quantity': 2,
        'requestDate': '11 Jan 2024',
        'status': RequestStatus.rejected,
        'isUrgent': false,
      },
    ];
  }

  void _approveRequest(Map<String, dynamic> request) {
    // TODO: Implement approve request logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande ${request['requestId']} approuvée'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectRequest(Map<String, dynamic> request) {
    // TODO: Implement reject request logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande ${request['requestId']} rejetée'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
