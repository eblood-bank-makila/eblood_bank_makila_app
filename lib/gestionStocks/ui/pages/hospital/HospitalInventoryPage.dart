import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../apps/services/HospitalInventoryService.dart';
import '../../../../utilisateurs/ui/widgets/PatientSelectorDialog.dart';

class HospitalInventoryPage extends StatefulWidget {
  const HospitalInventoryPage({super.key});

  @override
  State<HospitalInventoryPage> createState() => _HospitalInventoryPageState();
}

class _HospitalInventoryPageState extends State<HospitalInventoryPage> {
  final _service = HospitalInventoryService();
  bool _loading = true;
  String _statusFilter = 'available';
  List<dynamic> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _service.listItems(status: _statusFilter, page: 0, limit: 50);
    if (!mounted) return;
    if (res.success) {
      final data = res.data;
      List<dynamic> list = [];
      if (data is Map && data['data'] is List) {
        list = List<dynamic>.from(data['data'] as List);
      } else if (data is List) {
        list = List<dynamic>.from(data);
      }
      setState(() {
        _items = list;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Error';
        _loading = false;
      });
    }
  }

  Future<void> _markExpired(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm'.tr),
        content: Text('mark_as_expired'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('confirm'.tr)),
        ],
      ),
    );
    if (confirm != true) return;

    final res = await _service.markAsExpired(itemId);
    if (!mounted) return;
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('operation_successful'.tr), backgroundColor: Colors.green),
      );
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'operation_failed'.tr), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _markUsed(String itemId) async {
    final selectedId = await showDialog<String>(
      context: context,
      builder: (ctx) => const PatientSelectorDialog(),
    );
    if (selectedId == null || selectedId.isEmpty) return;

    final res = await _service.markAsTransfused(itemId, patientId: selectedId);
    if (!mounted) return;
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('operation_successful'.tr), backgroundColor: Colors.green),
      );
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'operation_failed'.tr), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('inventory'.tr),
        backgroundColor: Colors.white,
        foregroundColor: ColorPages.COLOR_PRINCIPAL,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: ColorPages.COLOR_PRINCIPAL,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _items.isEmpty
                    ? Center(child: Text('no_stock_to_display'.tr))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = Map<String, dynamic>.from(_items[index] as Map);
                          final id = (item['id'] ?? item['_id'] ?? '').toString();
                          final bloodType = (item['blood_type'] ?? item['bloodType'] ?? '').toString();
                          final component = (item['blood_component'] ?? item['component'] ?? '').toString();
                          final expiry = (item['expiry_date'] ?? item['expires_at'] ?? '').toString();
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.bloodtype, color: ColorPages.COLOR_PRINCIPAL),
                                      const SizedBox(width: 8),
                                      Text(
                                        bloodType.isEmpty ? 'N/A' : bloodType,
                                        style: const TextStyle(
                                          color: ColorPages.COLOR_PRINCIPAL,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (expiry.isNotEmpty)
                                        Text(
                                          expiry,
                                          style: TextStyle(color: Colors.orange.shade700),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (component.isNotEmpty)
                                    Text(component, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _markExpired(id),
                                          icon: const Icon(Icons.schedule, size: 18, color: Colors.orange),
                                          label: Text('mark_as_expired'.tr),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: ColorPages.COLOR_PRINCIPAL),
                                          onPressed: () => _markUsed(id),
                                          icon: const Icon(Icons.check, size: 18, color: Colors.white),
                                          label: Text('mark_as_used'.tr, style: const TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: Text('available'.tr),
              selected: _statusFilter == 'available',
              onSelected: (_) {
                setState(() => _statusFilter = 'available');
                _load();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text('expired'.tr),
              selected: _statusFilter == 'expired',
              onSelected: (_) {
                setState(() => _statusFilter = 'expired');
                _load();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text('used'.tr),
              selected: _statusFilter == 'transfused',
              onSelected: (_) {
                setState(() => _statusFilter = 'transfused');
                _load();
              },
            ),
          ],
        ),
      ),
    );
  }
}

