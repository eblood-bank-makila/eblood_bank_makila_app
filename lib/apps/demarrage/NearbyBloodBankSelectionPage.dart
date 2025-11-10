import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ionicons/ionicons.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme/ColorPages.dart';
import '../services/AuthService.dart';
import '../widgets/CustomButton.dart';
import './RegistrationSuccessPage.dart';

class NearbyBloodBankSelectionPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String phoneNumber;
  final String email;

  const NearbyBloodBankSelectionPage({
    super.key,
    required this.userData,
    required this.phoneNumber,
    required this.email,
  });

  @override
  State<NearbyBloodBankSelectionPage> createState() =>
      _NearbyBloodBankSelectionPageState();
}

class _NearbyBloodBankSelectionPageState
    extends State<NearbyBloodBankSelectionPage> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _bloodBanks = [];
  Map<String, dynamic>? _selectedBloodBank;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNearbyBloodBanks();
  }

  Future<void> _fetchNearbyBloodBanks() async {
    try {
      // Get device location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      print('📍 Device location: ${position.latitude}, ${position.longitude}');

      // Fetch nearby blood banks
      final result = await _authService.getNearbyBloodBanks(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 50.0,
        limit: 10,
      );

      if (result['success'] == true) {
        setState(() {
          _bloodBanks = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to fetch blood banks';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching blood banks: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (_selectedBloodBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a blood bank'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Add the selected blood bank ID to the user data
      final updatedUserData = Map<String, dynamic>.from(widget.userData);
      updatedUserData['sys_health_structure_id'] =
          _selectedBloodBank!['id'] ?? _selectedBloodBank!['sys_id'];

      print('📦 Updated registration data: $updatedUserData');

      // Submit registration
      final result = await _authService.register(updatedUserData);

      if (result['success'] == true) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RegistrationSuccessPage(
                phoneNumber: widget.phoneNumber,
                email: widget.email,
                token: result['data']?['token'] ?? '',
              ),
            ),
          );
        }
      } else {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Blood Bank',
          style: GoogleFonts.ubuntu(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.alert_circle_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ubuntu(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Retry',
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _fetchNearbyBloodBanks();
                        },
                      ),
                    ],
                  ),
                )
              : _bloodBanks.isEmpty
                  ? Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Empty state icon with animation
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: ColorPages.COLOR_PRINCIPAL
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Ionicons.location_outline,
                                      size: 50,
                                      color: ColorPages.COLOR_PRINCIPAL,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Title
                                  Text(
                                    'No Blood Banks Found',
                                    style: GoogleFonts.ubuntu(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Description
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
                                    child: Text(
                                      'There are no blood banks available in your area within 50km radius. Please try again later or expand your search area.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.ubuntu(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Retry button
                                  CustomButton(
                                    text: 'Retry Search',
                                    onPressed: () {
                                      setState(() => _isLoading = true);
                                      _fetchNearbyBloodBanks();
                                    },
                                    backgroundColor:
                                        ColorPages.COLOR_PRINCIPAL,
                                    width: 200,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: CustomButton(
                            text: 'Continue',
                            onPressed: _isSubmitting ? null : _submitRegistration,
                            isLoading: _isSubmitting,
                            backgroundColor: ColorPages.COLOR_PRINCIPAL,
                            height: 60,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _bloodBanks.length,
                            itemBuilder: (context, index) {
                              final bank = _bloodBanks[index];
                              final isSelected = _selectedBloodBank?['id'] ==
                                      bank['id'] ||
                                  _selectedBloodBank?['sys_id'] == bank['sys_id'];

                              return FadeInUp(
                                delay: Duration(milliseconds: index * 100),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedBloodBank = bank),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected
                                            ? ColorPages.COLOR_PRINCIPAL
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      bank['name'] ?? 'Unknown',
                                                      style: GoogleFonts.ubuntu(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      bank['address'] ?? '',
                                                      style: GoogleFonts.ubuntu(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Icon(
                                                  Ionicons.checkmark_circle,
                                                  color: ColorPages
                                                      .COLOR_PRINCIPAL,
                                                  size: 24,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: CustomButton(
                            text: 'Continue',
                            onPressed: _isSubmitting ? null : _submitRegistration,
                            isLoading: _isSubmitting,
                            backgroundColor: ColorPages.COLOR_PRINCIPAL,
                            height: 60,
                          ),
                        ),
                      ],
                    ),
    );
  }
}

