/// Blood Search Flow Routes
/// Route configuration for the blood search feature

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ui/pages/blood_search_welcome_page.dart';
import 'ui/pages/city_selection_page.dart';
import 'ui/pages/blood_type_input_page.dart';
import 'ui/pages/search_results_page.dart';
import 'ui/pages/hospital_identify_page.dart';
import 'ui/pages/visitor_phone_otp_page.dart';
import 'ui/pages/payment_page.dart';
import 'ui/pages/address_view_page.dart';
import 'ui/pages/live_tracking_page.dart';
import 'ui/pages/qr_scanner_page.dart';

/// Blood search flow routes to be added to the main router
List<RouteBase> bloodSearchFlowRoutes = [
  // Welcome/Landing page
  GoRoute(
    path: '/blood-search',
    name: 'blood-search',
    builder: (context, state) => const BloodSearchWelcomePage(),
  ),
  
  // City selection
  GoRoute(
    path: '/blood-search/city-selection',
    name: 'blood-search-city',
    builder: (context, state) => const CitySelectionPage(),
  ),
  
  // Blood type input
  GoRoute(
    path: '/blood-search/blood-type',
    name: 'blood-search-type',
    builder: (context, state) => const BloodTypeInputPage(),
  ),
  
  // Search results
  GoRoute(
    path: '/blood-search/results',
    name: 'blood-search-results',
    builder: (context, state) => const SearchResultsPage(),
  ),
  
  // Hospital identification
  GoRoute(
    path: '/blood-search/hospital-identify',
    name: 'blood-search-hospital',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return HospitalIdentifyPage(
        option: extra?['option'] as String?,
      );
    },
  ),
  
  // QR Scanner
  GoRoute(
    path: '/blood-search/qr-scanner',
    name: 'blood-search-qr',
    builder: (context, state) => const QrScannerPage(),
  ),
  
  // Visitor phone verification (OTP)
  GoRoute(
    path: '/blood-search/visitor-phone-otp',
    name: 'blood-search-visitor-otp',
    builder: (context, state) => const VisitorPhoneOtpPage(),
  ),
  
  // Payment page
  GoRoute(
    path: '/blood-search/payment',
    name: 'blood-search-payment',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return PaymentPage(
        option: extra?['option'] as String?,
      );
    },
  ),
  
  // Address view (after payment)
  GoRoute(
    path: '/blood-search/address-view',
    name: 'blood-search-address',
    builder: (context, state) => const AddressViewPage(),
  ),
  
  // Live tracking (for delivery)
  GoRoute(
    path: '/blood-search/live-tracking',
    name: 'blood-search-tracking',
    builder: (context, state) => const LiveTrackingPage(),
  ),
];

/// Route guard for checking visitor authentication
class BloodSearchRouteGuard {
  /// Check if user can access protected routes (payment, address, tracking)
  static bool canAccessProtectedRoute(String location) {
    final protectedRoutes = [
      '/blood-search/payment',
      '/blood-search/address-view',
      '/blood-search/live-tracking',
    ];
    
    return protectedRoutes.any((route) => location.startsWith(route));
  }
  
  /// Get redirect path for unauthenticated users
  static String? getRedirectPath(String currentLocation, bool isAuthenticated) {
    if (canAccessProtectedRoute(currentLocation) && !isAuthenticated) {
      return '/blood-search/visitor-phone';
    }
    return null;
  }
}

/// Deep link handler for blood search flow
class BloodSearchDeepLinkHandler {
  /// Handle hospital deep links (e.g., eblood://hospital/ABC12345)
  static String? handleDeepLink(Uri uri) {
    if (uri.scheme == 'eblood' || uri.host == 'eblood.app') {
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isNotEmpty) {
        switch (pathSegments.first) {
          case 'hospital':
            if (pathSegments.length > 1) {
              final hospitalCode = pathSegments[1];
              // Return path with hospital code as query param
              return '/blood-search/hospital-identify?code=$hospitalCode';
            }
            return '/blood-search/hospital-identify';
            
          case 'search':
            return '/blood-search';
            
          case 'track':
            if (pathSegments.length > 1) {
              final orderId = pathSegments[1];
              return '/blood-search/live-tracking?order=$orderId';
            }
            return null;
        }
      }
    }
    return null;
  }
  
  /// Parse hospital code from URI
  static String? extractHospitalCode(Uri uri) {
    // Try path segments first
    final pathSegments = uri.pathSegments;
    if (pathSegments.length >= 2 && pathSegments.first == 'hospital') {
      return pathSegments[1];
    }
    
    // Try query parameters
    return uri.queryParameters['code'];
  }
}

/// Custom page transitions for smooth flow experience
class BloodSearchPageTransitions {
  static CustomTransitionPage<T> slideFromRight<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  }
  
  static CustomTransitionPage<T> slideFromBottom<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  }
  
  static CustomTransitionPage<T> fadeIn<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
