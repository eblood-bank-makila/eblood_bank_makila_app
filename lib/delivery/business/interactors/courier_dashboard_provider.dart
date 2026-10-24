import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../apps/config/api/dio_client.dart';
import '../model/courier_dashboard.dart';

/// The courier home's counters and recent deliveries. Invalidate to reload.
final courierDashboardProvider = FutureProvider.autoDispose<CourierDashboard>((ref) async {
  final res = await getWithDio('/eblood-connect/delivery-assignment/my-dashboard');
  if (!res.success) throw Exception(res.message ?? 'courier dashboard');
  final data = res.data;
  return data is Map ? CourierDashboard.fromJson(Map<String, dynamic>.from(data)) : const CourierDashboard();
});
