import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/location_tree_select.dart';
import '../models/SystemCountry.dart';
import '../services/LocationService.dart';
import '../services/AuthApi.dart';
import '../config/theme/ColorPages.dart';

class VisitorEntitySelectionPage extends StatefulWidget {
  const VisitorEntitySelectionPage({super.key});

  @override
  State<VisitorEntitySelectionPage> createState() => _VisitorEntitySelectionPageState();
}

class _VisitorEntitySelectionPageState extends State<VisitorEntitySelectionPage> {
  final LocationService _locationService = LocationService();
  List<SystemCountry> _locations = [];
  bool _loadingLocations = false;
  String? _error;

  Map<String, String> _selectedLocation = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() {
      _loadingLocations = true;
      _error = null;
    });
    try {
      final response = await _locationService.fetchLocationData();
      setState(() {
        _locations = response.data;
        _loadingLocations = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load locations: $e';
        _loadingLocations = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedLocation.isEmpty || (_selectedLocation['id']?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('location_required'.tr), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await AuthApi.instance.createVisitor(locationId: _selectedLocation['id']!);
      if (result['success'] == true && mounted) {
        context.go('/rbac-loading');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? 'Operation failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operation failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPages.COLOR_PRINCIPAL),
          onPressed: () => context.pop(),
        ),
        iconTheme: IconThemeData(color: ColorPages.COLOR_PRINCIPAL),
        title: Text(
          'continue_as_visitor'.tr,
          style: GoogleFonts.ubuntu(color: ColorPages.COLOR_PRINCIPAL),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_your_location'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            LocationTreeSelect(
              locations: _locations,
              onLocationSelected: (value) {
                setState(() {
                  _selectedLocation = value;
                });
              },
              isLoading: _loadingLocations,
              errorText: _error,
              label: 'location'.tr,
              hint: 'select_location_hint'.tr,
              prefixIcon: Icon(Icons.place_outlined, color: ColorPages.COLOR_PRINCIPAL),
            ),
            const Spacer(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('continue'.tr, style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
