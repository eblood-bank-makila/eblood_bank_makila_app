import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/theme/ColorPages.dart';

/// Simplified controller for Network screen (adapted from makila_connect)
class NetworkController extends GetxController {
  // Search and filter
  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final categories = ['All', 'Hospital', 'Blood Bank', 'Clinic', 'Emergency'].obs;
  final selectedCategory = 'All'.obs;

  // Network data
  final networks = <NetworkModel>[].obs;
  final filteredNetworks = <NetworkModel>[].obs;

  // Loading states
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNetworks();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadNetworks() async {
    try {
      isLoading.value = true;
      // Demo data; replace with API data later
      networks.value = [
        NetworkModel(
          id: '1',
          name: 'City General Hospital',
          type: 'Hospital',
          address: '1234 Broadway, New York, NY',
          distance: 2.5,
          isOpen: true,
          rating: 4.8,
          phoneNumber: '+1 (555) 123-4567',
        ),
        NetworkModel(
          id: '2',
          name: 'Red Cross Blood Center',
          type: 'Blood Bank',
          address: '456 5th Avenue, New York, NY',
          distance: 1.8,
          isOpen: true,
          rating: 4.9,
          phoneNumber: '+1 (555) 987-6543',
        ),
      ];
      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _applyFilters();
    update();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _applyFilters();
    update();
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = networks.toList();
    if (selectedCategory.value != 'All') {
      filtered = filtered.where((n) => n.type == selectedCategory.value).toList();
    }
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((n) =>
          n.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          n.address.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
    }
    filtered.sort((a, b) => a.distance.compareTo(b.distance));
    filteredNetworks.value = filtered;
  }

  Future<void> callNetwork(NetworkModel network) async {
    Get.snackbar('Info', 'Call ${network.phoneNumber ?? ''}');
  }
}

class NetworkModel {
  final String id;
  final String name;
  final String type; // Hospital, Blood Bank, Clinic, Emergency
  final String address;
  final double distance; // km
  final bool isOpen;
  final double rating;
  final String? phoneNumber;

  NetworkModel({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.distance,
    required this.isOpen,
    required this.rating,
    this.phoneNumber,
  });
}

IconData getCategoryIcon(String type) {
  switch (type) {
    case 'Hospital':
      return Icons.local_hospital;
    case 'Blood Bank':
      return Icons.bloodtype;
    case 'Clinic':
      return Icons.local_pharmacy;
    case 'Emergency':
      return Icons.emergency_share;
    default:
      return Icons.location_city;
  }
}

Color getCategoryColor(String type) {
  switch (type) {
    case 'Hospital':
      return ColorPages.COLOR_PRINCIPAL;
    case 'Blood Bank':
      return Colors.red;
    case 'Clinic':
      return Colors.teal;
    case 'Emergency':
      return Colors.orange;
    default:
      return Colors.blueGrey;
  }
}
