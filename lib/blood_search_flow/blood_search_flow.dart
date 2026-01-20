/// Blood Search Flow Module
/// 
/// A comprehensive blood search feature module that allows users to:
/// - Search for blood products by city and blood type
/// - Identify hospitals via QR code, gallery import, or manual code
/// - Register as a visitor with phone OTP verification
/// - Pay to view hospital address or order delivery
/// - Track live delivery status
/// 
/// ## Architecture
/// 
/// This module follows clean architecture principles:
/// 
/// ```
/// blood_search_flow/
/// ├── domain/           # Business logic layer
/// │   ├── entities/     # Data models and state
/// │   └── services/     # Service interfaces
/// │
/// ├── data/             # Data layer
/// │   └── services/     # API implementations
/// │
/// ├── providers/        # Riverpod state management
/// │
/// └── ui/               # Presentation layer
///     ├── pages/        # Full-page screens
///     └── widgets/      # Reusable components
/// ```
/// 
/// ## Usage
/// 
/// 1. Add routes to your GoRouter configuration:
/// ```dart
/// import 'package:your_app/blood_search_flow/blood_search_routes.dart';
/// 
/// final router = GoRouter(
///   routes: [
///     ...bloodSearchFlowRoutes,
///     // other routes...
///   ],
/// );
/// ```
/// 
/// 2. Navigate to the blood search flow:
/// ```dart
/// context.go('/blood-search');
/// ```
/// 
/// 3. Handle deep links in your app:
/// ```dart
/// final path = BloodSearchDeepLinkHandler.handleDeepLink(uri);
/// if (path != null) {
///   context.go(path);
/// }
/// ```
/// 
/// ## Flow Steps
/// 
/// 1. **Welcome Page** - Entry point with "Start Search" and "Scan QR" options
/// 2. **City Selection** - Select city for blood search
/// 3. **Blood Type Input** - Select blood type and Rh factor
/// 4. **Search Results** - View available blood products
/// 5. **Hospital Identification** - Identify hospital via QR/code
/// 6. **Visitor Registration** - Phone OTP verification (if not authenticated)
/// 7. **Payment** - Pay for address view or delivery
/// 8. **Address View** or **Live Tracking** - Final step based on choice

library blood_search_flow;

// Routes
export 'blood_search_routes.dart';

// Domain
export 'domain/entities/search_flow_state.dart';
export 'domain/services/service_interfaces.dart';

// Providers
export 'providers/search_flow_provider.dart';

// Data services
export 'data/services/blood_search_service_impl.dart';
export 'data/services/hospital_identification_service_impl.dart';
export 'data/services/visitor_registration_service_impl.dart';
export 'data/services/payment_service_impl.dart';
export 'data/services/auth_service_impl.dart';

// UI Pages
export 'ui/pages/blood_search_welcome_page.dart';
export 'ui/pages/city_selection_page.dart';
export 'ui/pages/blood_type_input_page.dart';
export 'ui/pages/search_results_page.dart';
export 'ui/pages/hospital_identify_page.dart';
export 'ui/pages/visitor_phone_otp_page.dart';
export 'ui/pages/payment_page.dart';
export 'ui/pages/address_view_page.dart';
export 'ui/pages/live_tracking_page.dart';
export 'ui/pages/qr_scanner_page.dart';

// UI Widgets
export 'ui/widgets/search_flow_app_bar.dart';
export 'ui/widgets/search_flow_progress_indicator.dart';
export 'ui/widgets/option_choice_bottom_sheet.dart';
