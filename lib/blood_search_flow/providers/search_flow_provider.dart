/// Blood Search Flow - State Notifier (Riverpod)
/// Main state management for the blood search journey

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/location_tracking_service.dart';
import '../domain/entities/search_flow_state.dart';
import '../domain/services/service_interfaces.dart';
import '../data/services/blood_search_service_impl.dart';
import '../data/services/hospital_identification_service_impl.dart';
import '../data/services/visitor_registration_service_impl.dart';
import '../data/services/payment_service_impl.dart';
import '../data/services/auth_service_impl.dart';
import '../../services/HealthStructureService.dart';

/// Provider for the search flow state
final searchFlowProvider =
    StateNotifierProvider<SearchFlowNotifier, SearchFlowState>((ref) {
      final healthStructureService = ref.read(healthStructureServiceProvider);

      return SearchFlowNotifier(
        bloodSearchService: BloodSearchServiceImpl(),
        hospitalService: HospitalIdentificationServiceImpl(
          healthStructureService,
        ),
        visitorService: VisitorRegistrationServiceImpl(),
        paymentService: PaymentServiceImpl(),
        authService: AuthServiceImpl(),
      );
    });

/// Provider for checking if user can access protected routes
final canAccessProtectedRoutesProvider = FutureProvider<bool>((ref) async {
  final authService = AuthServiceImpl();
  final isAuthenticated = await authService.isAuthenticated();
  if (!isAuthenticated) return false;

  // Visitors can only access welcome page
  final isVisitor = await authService.isVisitor();
  return !isVisitor;
});

/// Provider for current user profile type
final userProfileTypeProvider = FutureProvider<String?>((ref) async {
  final authService = AuthServiceImpl();
  return authService.getUserProfileType();
});

class SearchFlowNotifier extends StateNotifier<SearchFlowState> {
  final IBloodSearchService bloodSearchService;
  final IHospitalIdentificationService hospitalService;
  final IVisitorRegistrationService visitorService;
  final IPaymentService paymentService;
  final IAuthService authService;

  String? _visitorSessionId;
  String? _appSignature;

  /// Set app signature for SMS Retriever API (auto-read OTP)
  void setAppSignature(String? signature) {
    _appSignature = signature;
    print('📱 App signature set for SMS auto-read: $signature');
  }

  SearchFlowNotifier({
    required this.bloodSearchService,
    required this.hospitalService,
    required this.visitorService,
    required this.paymentService,
    required this.authService,
  }) : super(const SearchFlowState()) {
    // Load persisted city after a short delay to ensure GetStorage is ready
    Future.delayed(const Duration(milliseconds: 50), () {
      _loadPersistedCity();
    });
  }

  /// Load previously selected city from storage
  Future<void> _loadPersistedCity() async {
    try {
      print('🔍 Loading persisted city from storage...');
      final storage = GetStorage();
      
      // Check if storage is initialized
      print('📱 GetStorage initialized: ${storage.hasData('selected_city_id')}');
      
      final cityId = storage.read('selected_city_id');
      final cityName = storage.read('selected_city_name');
      
      print('📦 Storage values - cityId: $cityId, cityName: $cityName');

      if (cityId != null && cityName != null) {
        state = state.copyWith(
          selectedCity: SelectedCity(id: cityId, name: cityName),
        );
        print('✅ Loaded persisted city: $cityName ($cityId)');
      } else {
        print('ℹ️ No persisted city found in storage');
      }
    } catch (e) {
      print('⚠️ Could not load persisted city: $e');
    }
  }

  /// Reset the entire flow
  void resetFlow() {
    _visitorSessionId = null;
    state = const SearchFlowState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Navigate to a specific step
  void goToStep(SearchFlowStep step) {
    state = state.copyWith(currentStep: step);
  }

  // ============================================
  // QR-First Flow
  // ============================================

  /// Start flow with QR scan first
  Future<void> startWithQrScan(String qrContent) async {
    state = state.copyWith(isLoading: true, qrScannedFirst: true);

    try {
      final hospital = await hospitalService.identifyFromQrContent(qrContent);
      if (hospital != null) {
        state = state.copyWith(
          identifiedHospital: hospital,
          isLoading: false,
          currentStep: SearchFlowStep.citySelection,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid hospital QR code',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to scan QR code: $e',
      );
    }
  }

  /// Handle deep link for hospital identification
  Future<void> handleDeepLink(String deepLinkUri) async {
    state = state.copyWith(isLoading: true, qrScannedFirst: true);

    try {
      final hospital = await hospitalService.identifyFromDeepLink(deepLinkUri);
      if (hospital != null) {
        state = state.copyWith(
          identifiedHospital: hospital,
          isLoading: false,
          // Resume at city selection if we have hospital
          currentStep: SearchFlowStep.citySelection,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid hospital link',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to process link: $e',
      );
    }
  }

  // ============================================
  // Manual Flow - Step by Step
  // ============================================

  /// Start manual search flow
  void startManualSearch() {
    state = state.copyWith(
      currentStep: SearchFlowStep.citySelection,
      qrScannedFirst: false,
    );
  }

  /// Set selected city
  Future<void> setSelectedCity(SelectedCity city) async {
    print('💾 Attempting to save city: ${city.name} (${city.id})');
    
    // Persist the selected city
    final storage = GetStorage();
    await storage.write('selected_city_id', city.id);
    await storage.write('selected_city_name', city.name);
    
    // Verify the write
    final savedId = storage.read('selected_city_id');
    final savedName = storage.read('selected_city_name');
    print('✅ Persisted and verified: $savedName ($savedId)');

    state = state.copyWith(
      selectedCity: city,
      currentStep: SearchFlowStep.bloodTypeInput,
    );
  }

  /// Set blood type and perform search
  Future<void> setBloodTypeAndSearch(String bloodType) async {
    if (state.selectedCity == null) {
      state = state.copyWith(errorMessage: 'Please select a city first');
      return;
    }

    state = state.copyWith(
      selectedBloodType: bloodType,
      isLoading: true,
      currentStep: SearchFlowStep.searchResults,
    );

    try {
      final token = await authService.getAuthToken();
      final results = await bloodSearchService.searchBlood(
        cityId: state.selectedCity!.id,
        bloodType: bloodType,
        authToken: token,
      );

      // Calculate distances if location is available
      List<BloodSearchResult> processedResults = results;
      try {
        // Use LocationTrackingService to ensure we have permission and get location
        final locationService = LocationTrackingService();
        await locationService.requestPermission(); // Ensure we have permission
        final position = await locationService.updateLocation();

        if (position != null) {
          processedResults = results.map((result) {
            if (result.latitude != null && result.longitude != null) {
              final distanceMeters = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                result.latitude!,
                result.longitude!,
              );
              // distanceKm expects km
              return result.copyWith(distanceKm: distanceMeters / 1000);
            }
            return result;
          }).toList();

          // Sort by distance (closest first)
          processedResults.sort((a, b) {
            final distA = a.distanceKm ?? double.infinity;
            final distB = b.distanceKm ?? double.infinity;
            return distA.compareTo(distB);
          });
        }
      } catch (locError) {
        print('Error calculating distances: $locError');
        // Continue with original results if location fails
      }

      state = state.copyWith(searchResults: processedResults, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Search failed: $e',
      );
    }
  }

  /// Retry search
  Future<void> retrySearch() async {
    if (state.selectedCity != null && state.selectedBloodType != null) {
      await setBloodTypeAndSearch(state.selectedBloodType!);
    }
  }

  // ============================================
  // Payment Option Selection
  // ============================================

  /// Select payment option and proceed to hospital identification
  void selectPaymentOption(PaymentOption option) {
    state = state.copyWith(
      selectedPaymentOption: option,
      currentStep: state.hasHospitalIdentified
          ? SearchFlowStep.visitorRegistration
          : SearchFlowStep.hospitalIdentification,
    );
  }

  // ============================================
  // Hospital Identification
  // ============================================

  /// Identify hospital by manual 8-digit code
  Future<void> identifyHospitalByCode(String code) async {
    if (code.length != 8) {
      state = state.copyWith(errorMessage: 'Please enter a valid 8-digit code');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final hospital = await hospitalService.identifyByCode(code);
      if (hospital != null) {
        state = state.copyWith(
          identifiedHospital: hospital,
          isLoading: false,
          currentStep: SearchFlowStep.visitorRegistration,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Hospital not found. Please check the code.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to identify hospital: $e',
      );
    }
  }

  /// Identify hospital from scanned QR
  Future<void> identifyHospitalFromQr(String qrContent) async {
    state = state.copyWith(isLoading: true);

    try {
      final hospital = await hospitalService.identifyFromQrContent(qrContent);
      if (hospital != null) {
        state = state.copyWith(
          identifiedHospital: hospital,
          isLoading: false,
          currentStep: SearchFlowStep.visitorRegistration,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid hospital QR code',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to process QR code: $e',
      );
    }
  }

  // ============================================
  // Visitor Registration & OTP
  // ============================================

  /// Check if user is already authenticated
  Future<bool> checkAuthentication() async {
    final isAuthenticated = await authService.isAuthenticated();
    if (isAuthenticated) {
      final token = await authService.getAuthToken();
      state = state.copyWith(
        visitorToken: token,
        otpVerified: true,
        currentStep: SearchFlowStep.payment,
      );
      return true;
    }
    return false;
  }

  /// Register visitor and send OTP
  Future<void> registerVisitorAndSendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, visitorPhoneNumber: phoneNumber);

    try {
      // First ensure visitor account exists (if they don't have one)
      // This is optional - visitor might already be registered via device
      if (state.identifiedHospital != null && state.selectedCity != null) {
        try {
          await visitorService.registerVisitor(
            phoneNumber: phoneNumber,
            hospitalId: state.identifiedHospital!.id,
            locationId: state.selectedCity?.id,
          );
        } catch (e) {
          // Ignore registration errors - visitor might already exist
          print('Visitor registration (may already exist): $e');
        }
      }

      // Store phone number as the session identifier for OTP flow
      _visitorSessionId = phoneNumber;

      // Send OTP to phone number (with app signature for auto-read)
      final otpSent = await visitorService.sendOtp(
        phoneNumber,
        appSignature: _appSignature,
      );

      state = state.copyWith(
        otpSent: otpSent,
        isLoading: false,
        currentStep: SearchFlowStep.otpVerification,
      );

      if (!otpSent) {
        state = state.copyWith(
          errorMessage: 'Failed to send OTP. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send OTP: $e',
      );
    }
  }

  /// Verify OTP
  Future<void> verifyOtp(String otpCode) async {
    if (_visitorSessionId == null) {
      state = state.copyWith(errorMessage: 'Session expired. Please restart.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      print(
        '🔐 Provider: verifying OTP "$otpCode" for session "$_visitorSessionId"',
      );

      // _visitorSessionId is the phone number for visitor OTP flow
      final result = await visitorService.verifyOtp(
        sessionId: _visitorSessionId!,
        otpCode: otpCode,
      );

      if (result != null) {
        // Phone verified successfully
        // Save the verified phone locally
        await visitorService.saveVisitorPhone(_visitorSessionId!);
        print('✅ OTP verified successfully');

        state = state.copyWith(
          otpVerified: true,
          isLoading: false,
          currentStep: SearchFlowStep.payment,
        );
      } else {
        print('⚠️ OTP verification returned null');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid OTP code',
        );
      }
    } catch (e) {
      print('❌ OTP verification error: $e');
      // Extract meaningful error message from exception
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
    }
  }

  /// Resend OTP
  Future<void> resendOtp() async {
    if (_visitorSessionId == null) {
      state = state.copyWith(errorMessage: 'Session expired. Please restart.');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final sent = await visitorService.resendOtp(_visitorSessionId!);
      state = state.copyWith(isLoading: false, otpSent: sent);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to resend OTP: $e',
      );
    }
  }

  // ============================================
  // Payment
  // ============================================

  /// Process payment
  Future<void> processPayment(Map<String, dynamic> paymentDetails) async {
    if (state.visitorToken == null) {
      state = state.copyWith(errorMessage: 'Authentication required');
      return;
    }

    if (state.identifiedHospital == null) {
      state = state.copyWith(errorMessage: 'Hospital not identified');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      PaymentResult result;

      if (state.selectedPaymentOption == PaymentOption.viewAddress) {
        result = await paymentService.payForAddressView(
          hospitalId: state.identifiedHospital!.id,
          authToken: state.visitorToken!,
          paymentDetails: paymentDetails,
        );
      } else {
        result = await paymentService.payForDelivery(
          hospitalId: state.identifiedHospital!.id,
          bloodBagIds: state.searchResults.map((r) => r.id).toList(),
          authToken: state.visitorToken!,
          paymentDetails: paymentDetails,
        );
      }

      state = state.copyWith(
        paymentResult: result,
        isLoading: false,
        currentStep: result.success
            ? (state.selectedPaymentOption == PaymentOption.viewAddress
                  ? SearchFlowStep.addressView
                  : SearchFlowStep.deliveryTracking)
            : state.currentStep,
        errorMessage: result.success ? null : result.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Payment failed: $e',
      );
    }
  }

  /// Retry payment
  Future<void> retryPayment(Map<String, dynamic> paymentDetails) async {
    await processPayment(paymentDetails);
  }

  // ============================================
  // Post-Payment
  // ============================================

  /// Load unlocked address after successful payment
  Future<void> loadUnlockedAddress() async {
    if (state.paymentResult?.transactionId == null) return;
    if (state.identifiedHospital == null) return;
    if (state.visitorToken == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // The address would be fetched from a service
      // For now, use the hospital address
      final address =
          state.identifiedHospital?.address ??
          'Address available after payment confirmation';

      state = state.copyWith(unlockedAddress: address, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load address: $e',
      );
    }
  }

  /// Load delivery tracking info
  Future<void> loadDeliveryTracking() async {
    if (state.paymentResult?.transactionId == null) return;
    if (state.visitorToken == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // This would fetch from a tracking service
      final trackingInfo = DeliveryTrackingInfo(
        trackingId: state.paymentResult!.transactionId!,
        status: 'processing',
        estimatedArrival: '30-45 minutes',
        orderTime: DateTime.now(),
      );

      state = state.copyWith(deliveryTracking: trackingInfo, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load tracking: $e',
      );
    }
  }

  // ============================================
  // Convenience Methods (Aliases for UI)
  // ============================================

  /// Select city (alias for setSelectedCity)
  Future<void> selectCity(SelectedCity city) => setSelectedCity(city);

  /// Search blood products (alias for setBloodTypeAndSearch)
  Future<void> searchBloodProducts(String bloodType) =>
      setBloodTypeAndSearch(bloodType);

  /// Select a search result
  void selectResult(BloodSearchResult result) {
    state = state.copyWith(
      selectedResult: result,
      currentStep: SearchFlowStep.hospitalIdentification,
    );
  }

  /// Register visitor (alias for registerVisitorAndSendOtp)
  Future<void> registerVisitor(String phoneNumber) =>
      registerVisitorAndSendOtp(phoneNumber);

  /// Process delivery payment
  Future<void> processDeliveryPayment(
    Map<String, dynamic> paymentDetails,
  ) async {
    state = state.copyWith(selectedPaymentOption: PaymentOption.delivery);
    await processPayment(paymentDetails);
  }

  /// Unlock address (pay for address view)
  Future<void> unlockAddress(Map<String, dynamic> paymentDetails) async {
    state = state.copyWith(selectedPaymentOption: PaymentOption.viewAddress);
    await processPayment(paymentDetails);
  }

  /// Start delivery tracking
  Future<void> startDeliveryTracking([String? orderId]) async {
    await loadDeliveryTracking();
  }

  /// Refresh delivery tracking
  Future<void> refreshDeliveryTracking() async {
    await loadDeliveryTracking();
  }
}
