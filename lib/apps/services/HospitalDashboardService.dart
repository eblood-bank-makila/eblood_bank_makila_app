import 'package:get_storage/get_storage.dart';

import '../config/api/dio_client.dart';
import '../models/api_response.dart';
import '../config/api/ApiConfig.dart';

class HospitalDashboardData {
  final int totalRequests;
  final int activeRequests;
  final int totalBloodBags;
  final int totalUsers;
  final int totalPatients;

  const HospitalDashboardData({
    required this.totalRequests,
    required this.activeRequests,
    required this.totalBloodBags,
    required this.totalUsers,
    required this.totalPatients,
  });
}

class HospitalDashboardService {
  static final HospitalDashboardService _instance = HospitalDashboardService._internal();
  factory HospitalDashboardService() => _instance;
  HospitalDashboardService._internal();

  Future<String?> _getDefaultHospitalId() async {
    try {
      final storage = GetStorage();
      final dynamic storedProfiles = storage.read('user_profiles') ?? storage.read('user_profils');

      String? sysOrgId;
      if (storedProfiles is List) {
        for (final p in storedProfiles) {
          if (p is Map) {
            final candidate = (p['sys_organization_id'] ?? p['organization_id'] ?? p['org_id'])?.toString();
            if (candidate != null && candidate.isNotEmpty) {
              sysOrgId = candidate;
              break;
            }
          }
        }
      } else if (storedProfiles is Map) {
        sysOrgId = (storedProfiles['sys_organization_id'] ?? storedProfiles['organization_id'])?.toString();
      }

      if (sysOrgId == null || sysOrgId.isEmpty) {
        final userData = storage.read('user_data');
        if (userData is Map) {
          sysOrgId = (userData['sys_organization_id'] ?? userData['organization_id'])?.toString();
        }
      }

      if (sysOrgId == null || sysOrgId.isEmpty) return null;

      final res = await getWithDio(
        ApiConfig.hospitalsList,
        queryParams: {
          'filter__sys_organization_id': sysOrgId,
          'limit': 1,
          'page': 0,
        },
      );

      if (res.success) {
        final data = res.data;
        if (data is Map && data['data'] is List && (data['data'] as List).isNotEmpty) {
          final first = Map<String, dynamic>.from(data['data'][0] as Map);
          return first['id']?.toString() ?? first['_id']?.toString();
        }
        if (data is List && data.isNotEmpty) {
          final first = Map<String, dynamic>.from(data.first as Map);
          return first['id']?.toString() ?? first['_id']?.toString();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int> _getUsersCountFromApi() async {
    try {
      final res = await getWithDio(ApiConfig.usersList, queryParams: {
        'limit': 1,
        'page': 0,
      });
      if (res.success) {
        if (res.total != null) return res.total!;
        if (res.data is Map) {
          final m = Map<String, dynamic>.from(res.data as Map);
          final t = m['total'];
          if (t is int) return t;
          final parsed = int.tryParse(t?.toString() ?? '0') ?? 0;
          return parsed;
        }
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<HospitalDashboardData> fetchDashboard() async {
    int totalRequests = 0;
    int activeRequests = 0;
    int totalBloodBags = 0;
    int totalUsers = 0 ;// await _getUsersCountFromApi();
    int totalPatients = 0;

    // Use hospital-specific statistics endpoint
    // Note: hospital_id is derived from authenticated user's sys_organization_id on backend
    final hospitalStats = await getWithDio(ApiConfig.hospitalStatistics);
    if (hospitalStats.success && hospitalStats.data is Map) {
      final data = Map<String, dynamic>.from(hospitalStats.data as Map);

      // Extract request statistics
      if (data['request_statistics'] is Map) {
        final reqStats = Map<String, dynamic>.from(data['request_statistics'] as Map);
        totalRequests = (reqStats['total_requests'] ?? 0) is int
            ? (reqStats['total_requests'] ?? 0)
            : int.tryParse((reqStats['total_requests'] ?? '0').toString()) ?? 0;
        activeRequests = (reqStats['pending_requests'] ?? reqStats['active_requests'] ?? 0) is int
            ? (reqStats['pending_requests'] ?? reqStats['active_requests'] ?? 0)
            : int.tryParse((reqStats['pending_requests'] ?? reqStats['active_requests'] ?? '0').toString()) ?? 0;
      }

      // Extract inventory statistics
      if (data['inventory_statistics'] is Map) {
        final invStats = Map<String, dynamic>.from(data['inventory_statistics'] as Map);
        totalBloodBags = (invStats['total_bags'] ?? invStats['total_items'] ?? 0) is int
            ? (invStats['total_bags'] ?? invStats['total_items'] ?? 0)
            : int.tryParse((invStats['total_bags'] ?? invStats['total_items'] ?? '0').toString()) ?? 0;
      }

      // Extract patient statistics
      if (data['patient_statistics'] is Map) {
        final patStats = Map<String, dynamic>.from(data['patient_statistics'] as Map);
        totalPatients = (patStats['total_patients'] ?? 0) is int
            ? (patStats['total_patients'] ?? 0)
            : int.tryParse((patStats['total_patients'] ?? '0').toString()) ?? 0;
      }
      // Extract staff statistics
      if (data['operational_statistics'] is Map) {
        final opsStats = Map<String, dynamic>.from(data['operational_statistics'] as Map);
        totalUsers = (opsStats['staff_count'] ?? 0) is int
            ? (opsStats['staff_count'] ?? 0)
            : int.tryParse((opsStats['staff_count'] ?? '0').toString()) ?? 0;
      }
    }

    return HospitalDashboardData(
      totalRequests: totalRequests,
      activeRequests: activeRequests,
      totalBloodBags: totalBloodBags,
      totalUsers: totalUsers,
      totalPatients: totalPatients,
    );
  }
}

