/// Blood Search Flow - State Notifier (Riverpod)
/// Main state management for the blood search journey

import 'dart:async';
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
import '../data/services/visitor_fcm_registration_service.dart';
import '../data/services/payment_service_impl.dart';
import '../data/services/auth_service_impl.dart';
import '../../payments/business/service/PaymentApi.dart' show PaymentInitiateResult;
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

  /// Start flow with QR scan first.
  /// For hospital accounts the city step is auto-skipped.
  Future<void> startWithQrScan(String qrContent) async {
    state = state.copyWith(isLoading: true, qrScannedFirst: true);

    try {
      final hospital = await hospitalService.identifyFromQrContent(qrContent);
      if (hospital != null) {
        // Determine next step: hospital accounts skip city selection
        final storage = GetStorage();
        final accountType = (storage.read('account_type') ?? '').toString().toLowerCase();
        final nextStep = accountType == 'hospital'
            ? SearchFlowStep.bloodTypeInput
            : SearchFlowStep.citySelection;

        // For hospitals, auto-populate city so the flow doesn't require it
        if (accountType == 'hospital') {
          await _autoPopulateHospitalCity();
        }

        state = state.copyWith(
          identifiedHospital: hospital,
          isLoading: false,
          currentStep: nextStep,
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
        // Hospital accounts skip city selection
        final storage = GetStorage();
        final accountType = (storage.read('account_type') ?? '').toString().toLowerCase();
        final nextStep = accountType == 'hospital'
            ? SearchFlowStep.bloodTypeInput
            : SearchFlowStep.citySelection;

        if (accountType == 'hospital') {
          await _autoPopulateHospitalCity();
        }

        state = state.copyWith(
          identifiedHospital: hospital,
          isLoading: false,
          currentStep: nextStep,
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

  /// Auto-populate city for hospital accounts from stored entity data.
  /// Used by QR/deep-link flows to skip city selection.
  Future<void> _autoPopulateHospitalCity() async {
    final storage = GetStorage();
    String cityId = '';
    String cityName = '';

    // Try cached health structure entity
    try {
      final cachedHS = storage.read('cached_health_structure');
      if (cachedHS is Map) {
        final namedEntity = cachedHS['named_entity'];
        if (namedEntity is Map) {
          cityId = (namedEntity['id'] ?? namedEntity['_id'] ?? '').toString();
          cityName = (namedEntity['name'] ?? namedEntity['entity_name'] ?? '').toString();
        }
        if (cityId.isEmpty) {
          final entity = cachedHS['entity'];
          if (entity is Map) {
            cityId = (entity['id'] ?? entity['_id'] ?? '').toString();
            cityName = (entity['name'] ?? entity['entity_name'] ?? '').toString();
          }
        }
        if (cityId.isEmpty) {
          cityId = (cachedHS['id'] ?? '').toString();
          cityName = (cachedHS['name'] ?? '').toString();
        }
      }
    } catch (_) {}

    if (cityId.isEmpty) {
      cityId = (storage.read('user_entity_id') ?? '').toString();
      cityName = (storage.read('user_entity_name') ?? '').toString();
    }
    if (cityId.isEmpty) {
      cityId = (storage.read('user_identifier') ?? 'hospital').toString();
      cityName = 'My Hospital';
    }

    final city = SelectedCity(
      id: cityId,
      name: cityName.isNotEmpty ? cityName : 'My Hospital Location',
    );
    await storage.write('selected_city_id', city.id);
    await storage.write('selected_city_name', city.name);
    state = state.copyWith(selectedCity: city);
    print('🏥 Hospital: auto-populated city "${city.name}" ($cityId)');
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

  /// Start search for hospital accounts — skip city selection.
  /// Auto-populates SelectedCity from the hospital's health structure
  /// entity data, then jumps directly to blood type input.
  /// Always succeeds for hospital accounts (uses fallback if no entity data).
  Future<void> startHospitalSearch() async {
    final storage = GetStorage();

    // 1. Try to get entity info from cached health structure
    String entityId = '';
    String entityName = '';

    try {
      final cachedHS = storage.read('cached_health_structure');
      if (cachedHS is Map) {
        // named_entity holds the town-level location
        final namedEntity = cachedHS['named_entity'];
        if (namedEntity is Map) {
          entityId = (namedEntity['id'] ?? namedEntity['_id'] ?? '').toString();
          entityName = (namedEntity['name'] ?? namedEntity['entity_name'] ?? '').toString();
        }
        // Fallback to the entity field
        if (entityId.isEmpty) {
          final entity = cachedHS['entity'];
          if (entity is Map) {
            entityId = (entity['id'] ?? entity['_id'] ?? '').toString();
            entityName = (entity['name'] ?? entity['entity_name'] ?? '').toString();
          }
        }
        // Use health structure name/id if entity lookup failed
        if (entityId.isEmpty) {
          entityId = (cachedHS['id'] ?? '').toString();
          entityName = (cachedHS['name'] ?? '').toString();
        }
      }
    } catch (e) {
      print('⚠️ Error reading cached health structure for entity: $e');
    }

    // 2. Fallback: use user_entity stored during login
    if (entityId.isEmpty) {
      entityId = (storage.read('user_entity_id') ?? '').toString();
      entityName = (storage.read('user_entity_name') ?? '').toString();
    }

    // 3. Final fallback: use hospital identifier as ID
    if (entityId.isEmpty) {
      entityId = (storage.read('user_identifier') ?? 'hospital').toString();
      entityName = 'My Hospital';
    }

    final city = SelectedCity(
      id: entityId,
      name: entityName.isNotEmpty ? entityName : 'My Hospital Location',
    );

    // Persist the auto-selected city
    await storage.write('selected_city_id', city.id);
    await storage.write('selected_city_name', city.name);

    // Auto-identify the hospital (they ARE the hospital)
    double? hsLatitude;
    double? hsLongitude;
    String hsIdentifier = '';
    String hsName = entityName;
    String hsId = entityId;
    try {
      final cachedHS = storage.read('cached_health_structure');
      if (cachedHS is Map) {
        hsLatitude = double.tryParse((cachedHS['latitude'] ?? '').toString());
        hsLongitude = double.tryParse((cachedHS['longitude'] ?? '').toString());
        hsIdentifier = (cachedHS['identifier'] ?? '').toString();
        if (hsName.isEmpty) hsName = (cachedHS['name'] ?? '').toString();
        if (hsId.isEmpty) hsId = (cachedHS['id'] ?? cachedHS['_id'] ?? '').toString();
      }
    } catch (_) {}

    final autoHospital = IdentifiedHospital(
      id: hsId,
      code: hsIdentifier.isNotEmpty ? hsIdentifier : (storage.read('user_identifier') ?? '').toString(),
      name: hsName.isNotEmpty ? hsName : 'My Hospital',
      latitude: hsLatitude,
      longitude: hsLongitude,
      method: HospitalIdentificationMethod.loggedInAccount,
    );

    state = state.copyWith(
      selectedCity: city,
      identifiedHospital: autoHospital,
      currentStep: SearchFlowStep.bloodTypeInput,
      qrScannedFirst: false,
    );
    print('🏥 Hospital: auto-selected city "${city.name}" & auto-identified hospital "${autoHospital.name}" (lat:$hsLatitude, lng:$hsLongitude) — skipping to blood type');
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
      currentStep: SearchFlowStep.hospitalIdentification,
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

      // Collect coordinates for backend distance calculation
      double? userLat;
      double? userLng;
      double? hospitalLat;
      double? hospitalLng;

      // Hospital coordinates from identified hospital
      if (state.identifiedHospital != null) {
        hospitalLat = state.identifiedHospital!.latitude;
        hospitalLng = state.identifiedHospital!.longitude;
      }

      // User coordinates from device location
      try {
        final locationService = LocationTrackingService();
        await locationService.requestPermission();
        final position = await locationService.updateLocation();
        if (position != null) {
          userLat = position.latitude;
          userLng = position.longitude;
        }
      } catch (_) {}

      final results = await bloodSearchService.searchBlood(
        cityId: state.selectedCity!.id,
        bloodType: bloodType,
        authToken: token,
        userLatitude: userLat,
        userLongitude: userLng,
        hospitalLatitude: hospitalLat,
        hospitalLongitude: hospitalLng,
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

  /// Select payment option and proceed to next step.
  /// - For hospital accounts: auto-identify (they ARE the hospital) and skip visitor reg.
  /// - For other logged-in users: skip visitor registration (already authenticated).
  /// - For guests: go through hospital identification → visitor registration → OTP.
  void selectPaymentOption(PaymentOption option) {
    final storage = GetStorage();
    final accountType = (storage.read('account_type') ?? '').toString().toLowerCase();
    final isLoggedIn = (storage.read('auth_token') ?? '').toString().isNotEmpty;

    // --- Hospital account: auto-identify as themselves and skip to payment ---
    if (accountType == 'hospital') {
      if (!state.hasHospitalIdentified) {
        final entityId = (storage.read('user_entity_id') ?? '').toString();
        final entityName = (storage.read('user_entity_name') ?? '').toString();
        final identifier = (storage.read('user_identifier') ?? '').toString();

        if (entityId.isNotEmpty) {
          state = state.copyWith(
            identifiedHospital: IdentifiedHospital(
              id: entityId,
              code: identifier,
              name: entityName.isNotEmpty ? entityName : 'My Hospital',
              method: HospitalIdentificationMethod.loggedInAccount,
            ),
          );
          print('🏥 Auto-identified hospital from logged-in account: $entityName ($entityId)');
        }
      }
      // Hospital is already authenticated — go straight to payment
      state = state.copyWith(
        selectedPaymentOption: option,
        otpVerified: true,
        currentStep: SearchFlowStep.payment,
      );
      return;
    }

    // --- Other logged-in users (customer, blood_bank, donor, etc.) ---
    if (isLoggedIn && accountType.isNotEmpty && accountType != 'visitor') {
      state = state.copyWith(
        selectedPaymentOption: option,
        otpVerified: true,
        currentStep: state.hasHospitalIdentified
            ? SearchFlowStep.payment
            : SearchFlowStep.hospitalIdentification,
      );
      return;
    }

    // --- Guest / Visitor: original flow ---
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
      print('========================================');
      print('🔍 [SearchFlowProvider] identifyHospitalByCode called with: $code');
      print('========================================');
      
      final hospital = await hospitalService.identifyByCode(code);
      
      print('🏥 [SearchFlowProvider] Hospital result: $hospital');
      print('🏥 [SearchFlowProvider] Hospital ID: ${hospital?.id}');
      
      if (hospital != null) {
        print('✅ [SearchFlowProvider] SAVING hospital to state with ID: ${hospital.id}');

        // Logged-in users skip visitor registration → go to payment
        final nextStep = await _nextStepAfterHospitalIdentification();

        state = state.copyWith(
          identifiedHospital: hospital,
          isLoading: false,
          otpVerified: nextStep == SearchFlowStep.payment ? true : null,
          currentStep: nextStep,
        );
        print('✅ [SearchFlowProvider] State updated. identifiedHospital.id = ${state.identifiedHospital?.id}');
      } else {
        print('❌ [SearchFlowProvider] Hospital is null, not saving');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Hospital not found. Please check the code.',
        );
      }
    } catch (e) {
      print('❌ [SearchFlowProvider] Error: $e');
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
      print('========================================');
      print('🔍 [SearchFlowProvider] identifyHospitalFromQr called');
      print('========================================');
      
      final hospital = await hospitalService.identifyFromQrContent(qrContent);
      
      print('🏥 [SearchFlowProvider] QR Hospital result: $hospital');
      print('🏥 [SearchFlowProvider] QR Hospital ID: ${hospital?.id}');
      
      if (hospital != null) {
        print('✅ [SearchFlowProvider] SAVING QR hospital to state with ID: ${hospital.id}');

        // Logged-in users skip visitor registration → go to payment
        final nextStep = await _nextStepAfterHospitalIdentification();

        state = state.copyWith(
          identifiedHospital: hospital,
          isLoading: false,
          otpVerified: nextStep == SearchFlowStep.payment ? true : null,
          currentStep: nextStep,
        );
        print('✅ [SearchFlowProvider] State updated. identifiedHospital.id = ${state.identifiedHospital?.id}');
      } else {
        print('❌ [SearchFlowProvider] QR Hospital is null');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid hospital QR code',
        );
      }
    } catch (e) {
      print('❌ [SearchFlowProvider] QR Error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to process QR code: $e',
      );
    }
  }

  // ============================================
  // Visitor Registration & OTP
  // ============================================

  /// Determine the next step after hospital identification.
  /// In the new flow (City → Hospital Identify → Blood Type → Results → Payment),
  /// hospital identification comes before blood type, so next step is always bloodTypeInput.
  Future<SearchFlowStep> _nextStepAfterHospitalIdentification() async {
    print('🔀 Hospital identified — next step: blood type input');
    return SearchFlowStep.bloodTypeInput;
  }

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

        // Load auth token from storage so it's available for payment
        final token = await authService.getAuthToken();
        print('🔑 Auth token loaded after OTP: ${token != null ? 'yes' : 'no'}');

        // Register the device's FCM token to cfg_fcm_config under this
        // visitor's user_id. Without this, the visitor has zero rows in
        // cfg_fcm_config and the backend's per-user FCM dispatch
        // (`OrderNotificationService._push_to_users_safe`) skips them
        // — they'd never get `order_created` / `delivery_assigned` /
        // `delivered` push notifications. Best-effort: the registration
        // call's own error handling means a failure here doesn't block
        // payment. The dio AuthInterceptor injects the visitor's
        // Bearer token automatically so the backend resolves
        // `targeted_id` to this specific visitor user.
        unawaited(VisitorFcmRegistrationService().registerCurrentDevice());

        state = state.copyWith(
          otpVerified: true,
          visitorToken: token,
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

  /// PHASE 1 — create the payment intent + gateway session and return the
  /// full lokotro checkout config for the UI to launch the SDK with.
  ///
  /// Does NOT mark the payment successful — money is only collected once
  /// the SDK reports success, at which point the UI calls
  /// [markPaymentCollected]. Returns null (with errorMessage/paymentResult
  /// set) if validation fails or the backend couldn't start the payment.
  Future<PaymentInitiateResult?> beginPayment(
    PaymentOption option,
    Map<String, dynamic> paymentDetails,
  ) async {
    state = state.copyWith(selectedPaymentOption: option, clearError: true);

    // Try to load token from storage if not in state
    if (state.visitorToken == null) {
      final token = await authService.getAuthToken();
      if (token != null) {
        state = state.copyWith(visitorToken: token);
        print('🔑 Loaded auth token from storage for payment');
      } else {
        state = state.copyWith(
          errorMessage: 'Authentication required',
          paymentResult: PaymentResult(
            success: false,
            message: 'Authentication required. Please verify your phone first.',
            option: option,
          ),
        );
        return null;
      }
    }

    if (state.identifiedHospital == null || state.identifiedHospital!.id.isEmpty) {
      print('❌ [beginPayment] Hospital not identified or ID is empty');
      state = state.copyWith(
        errorMessage: 'Hospital not identified',
        paymentResult: PaymentResult(
          success: false,
          message: 'Hospital not identified. Please go back and scan a QR code.',
          option: option,
        ),
      );
      return null;
    }

    final hospitalId = state.identifiedHospital!.id;
    state = state.copyWith(isLoading: true);

    try {
      final PaymentInitiateResult initiate =
          option == PaymentOption.viewAddress
              ? await paymentService.initiateAddressViewPayment(
                  hospitalId: hospitalId,
                  authToken: state.visitorToken!,
                  paymentDetails: paymentDetails,
                )
              : await paymentService.initiateDeliveryPayment(
                  hospitalId: hospitalId,
                  bloodBagIds: state.searchResults.map((r) => r.id).toList(),
                  authToken: state.visitorToken!,
                  paymentDetails: paymentDetails,
                );

      state = state.copyWith(isLoading: false);

      if (!initiate.isSuccess || initiate.customerReference == null) {
        state = state.copyWith(
          errorMessage: initiate.errorMessage ?? 'Payment initiation failed',
          paymentResult: PaymentResult(
            success: false,
            message: initiate.errorMessage ?? 'Payment initiation failed',
            option: option,
          ),
        );
        return null;
      }
      return initiate;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Payment failed: $e',
        paymentResult: PaymentResult(
          success: false,
          message: 'Payment failed: $e',
          option: option,
        ),
      );
      return null;
    }
  }

  /// PHASE 2 — record a successful SDK collection: mark the payment
  /// successful and advance to the address-view / delivery-tracking step.
  /// Called by the UI from the SDK's onResponse success callback.
  void markPaymentCollected(
    PaymentOption option,
    String customerReference, {
    String? transactionId,
  }) {
    state = state.copyWith(
      clearError: true,
      paymentResult: PaymentResult(
        success: true,
        requestIdentifier: customerReference,
        transactionId: transactionId,
        paymentStatus: 'success',
        message: 'Payment collected',
        option: option,
      ),
      currentStep: option == PaymentOption.viewAddress
          ? SearchFlowStep.addressView
          : SearchFlowStep.deliveryTracking,
    );
  }

  // ============================================
  // Post-Payment
  // ============================================

  /// Load unlocked address after successful payment
  /// Polls the backend for payment confirmation before showing address.
  Future<void> loadUnlockedAddress() async {
    if (state.paymentResult?.requestIdentifier == null &&
        state.paymentResult?.transactionId == null) return;
    if (state.identifiedHospital == null) return;
    if (state.visitorToken == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final identifier = state.paymentResult!.requestIdentifier ??
          state.paymentResult!.transactionId!;
      
      // Poll payment status up to 10 times (every 5 seconds = ~50s total)
      PaymentResult? statusResult;
      for (int i = 0; i < 10; i++) {
        statusResult = await paymentService.checkPaymentStatus(
          requestIdentifier: identifier,
          authToken: state.visitorToken!,
          progressPercent: i / 10.0,
        );

        if (statusResult.paymentStatus == 'success' ||
            statusResult.paymentStatus == 'successful') {
          // Payment confirmed — use the hospital address
          final address = state.identifiedHospital?.address ??
              'Address available after confirmation';
          state = state.copyWith(
            unlockedAddress: address,
            isLoading: false,
            paymentResult: statusResult,
          );
          return;
        }

        if (statusResult.paymentStatus == 'failed') {
          state = state.copyWith(
            isLoading: false,
            errorMessage: statusResult.message ?? 'Payment failed',
          );
          return;
        }

        // Still processing — wait before next poll
        await Future.delayed(const Duration(seconds: 5));
      }

      // Timed out waiting for payment confirmation
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Payment verification timed out. Please check your payment status.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to verify payment: $e',
      );
    }
  }

  /// Load delivery tracking info
  /// Polls backend for payment confirmation then sets up tracking.
  Future<void> loadDeliveryTracking() async {
    if (state.paymentResult?.requestIdentifier == null &&
        state.paymentResult?.transactionId == null) return;
    if (state.visitorToken == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final identifier = state.paymentResult!.requestIdentifier ??
          state.paymentResult!.transactionId!;

      // Poll payment status up to 10 times (every 5 seconds)
      PaymentResult? statusResult;
      for (int i = 0; i < 10; i++) {
        statusResult = await paymentService.checkPaymentStatus(
          requestIdentifier: identifier,
          authToken: state.visitorToken!,
          progressPercent: i / 10.0,
        );

        if (statusResult.paymentStatus == 'success' ||
            statusResult.paymentStatus == 'successful') {
          // Payment confirmed — create tracking info from the confirmed result
          final trackingInfo = DeliveryTrackingInfo(
            trackingId: statusResult.transactionId ?? identifier,
            status: 'processing',
            estimatedArrival: '30-45 minutes',
            orderTime: DateTime.now(),
          );
          state = state.copyWith(
            deliveryTracking: trackingInfo,
            isLoading: false,
            paymentResult: statusResult,
          );
          return;
        }

        if (statusResult.paymentStatus == 'failed') {
          state = state.copyWith(
            isLoading: false,
            errorMessage: statusResult.message ?? 'Payment failed',
          );
          return;
        }

        await Future.delayed(const Duration(seconds: 5));
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Payment verification timed out. Please check your payment status.',
      );
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

  /// Start delivery tracking
  Future<void> startDeliveryTracking([String? orderId]) async {
    await loadDeliveryTracking();
  }

  /// Refresh delivery tracking
  Future<void> refreshDeliveryTracking() async {
    await loadDeliveryTracking();
  }
}
