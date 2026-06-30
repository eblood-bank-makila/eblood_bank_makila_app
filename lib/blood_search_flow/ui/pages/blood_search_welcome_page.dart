/// Blood Search Welcome Page
/// Landing page for the blood search journey

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iconsax/iconsax.dart';

import '../../providers/search_flow_provider.dart';
import '../../providers/recent_activity_provider.dart';
import '../../data/services/visitor_registration_service_impl.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../../core/services/session_user_store.dart';
import '../widgets/recent_activity_bottom_sheet.dart';

class BloodSearchWelcomePage extends ConsumerStatefulWidget {
  const BloodSearchWelcomePage({super.key});

  @override
  ConsumerState<BloodSearchWelcomePage> createState() => _BloodSearchWelcomePageState();
}

class _BloodSearchWelcomePageState extends ConsumerState<BloodSearchWelcomePage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isStartSearchLoading = false;
  bool _isScanQrLoading = false;
  final VisitorRegistrationServiceImpl _visitorService = VisitorRegistrationServiceImpl();

  // Logged-in user info
  bool _isLoggedIn = false;
  String _userDisplayName = '';
  String _userSubtitle = '';
  String _accountType = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();

    // Load logged-in user info from storage
    _loadUserInfo();

    // Reset search flow when arriving at welcome page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchFlowProvider.notifier).resetFlow();
      // Fetch recent activity to determine if FAB should show
      ref.read(recentActivityProvider.notifier).fetchRecentActivity();
    });
  }

  /// Load user info from local storage to determine logged-in state.
  ///
  /// Token detection: GetStorage fast path → FlutterSecureStorage durable
  /// fallback. Display info: GetStorage `user_data` (fast) → secure
  /// [SessionUserStore] (durable, survives an app kill / GetStorage wipe).
  /// Whenever we derive from GetStorage we also (re)write the durable copy.
  Future<void> _loadUserInfo() async {
    try {
      final storage = GetStorage();
      // Check for a valid auth token (GetStorage fast path, then FlutterSecureStorage)
      String? token = storage.read('auth_token');
      if (token == null || token.toString().isEmpty) {
        token = storage.read('visitor_token');
      }
      if (token == null || token.toString().isEmpty) {
        const secure = FlutterSecureStorage();
        token = await secure.read(key: 'auth_token');
      }

      // No token at all → not logged in, leave the guest (login/register) bar.
      if (token == null || token.isEmpty) {
        return;
      }

      String accountType = (storage.read('account_type') ?? '').toString().toLowerCase();
      final userData = storage.read('user_data');

      String displayName = '';

      // 1) Fast path: derive from the GetStorage user_data cache.
      if (userData is Map) {
        displayName = SessionUserStore.deriveDisplayName(userData, accountType);
      }

      // 2) Visitor with no user_data → use the saved visitor phone.
      if (displayName.isEmpty) {
        final visitorPhone = (storage.read('visitor_phone') ?? '').toString();
        if (visitorPhone.isNotEmpty) {
          displayName = visitorPhone;
        }
      }

      // 3) Durable fallback: GetStorage was wiped / incomplete but the secure
      //    token survived — recover the name from secure storage.
      if (displayName.isEmpty) {
        final cached = await SessionUserStore.read();
        if (cached != null && cached.displayName.isNotEmpty) {
          displayName = cached.displayName;
          if (accountType.isEmpty) {
            accountType = cached.accountType.toLowerCase();
          }
        }
      }

      // 4) Last resort: generic visitor label.
      if (displayName.isEmpty) {
        displayName = 'visitor'.tr.isEmpty ? 'Visitor' : 'visitor'.tr;
      }

      final subtitle =
          _accountTypeLabel(accountType.isEmpty ? 'visitor' : accountType);

      // Persist a durable secure-storage copy so the next cold start / hot
      // restart can show the user even if the GetStorage cache is gone.
      if (userData is Map) {
        await SessionUserStore.saveFromUserData(
          userData: userData,
          accountType: accountType,
        );
      }

      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _userDisplayName = displayName;
          _userSubtitle = subtitle;
          _accountType = accountType;
        });
      }
    } catch (e) {
      debugPrint('⚠️ BloodSearchWelcome: _loadUserInfo error: $e');
    }
  }

  String _accountTypeLabel(String type) {
    switch (type) {
      case 'hospital':
        return 'hospital'.tr.isEmpty ? 'Hospital' : 'hospital'.tr;
      case 'blood_bank':
        return 'blood_bank'.tr.isEmpty ? 'Blood Bank' : 'blood_bank'.tr;
      case 'customer':
        return 'customer'.tr.isEmpty ? 'Customer' : 'customer'.tr;
      case 'visitor':
        return 'visitor'.tr.isEmpty ? 'Visitor' : 'visitor'.tr;
      case 'blood_donor':
        return 'blood_donor'.tr.isEmpty ? 'Blood Donor' : 'blood_donor'.tr;
      case 'delivery':
      case 'delivery_person':
        return 'delivery'.tr.isEmpty ? 'Delivery' : 'delivery'.tr;
      default:
        return type.isNotEmpty ? type : 'User';
    }
  }

  /// Check autoOpenTab and show bottom sheet automatically
  void _checkAutoOpenTab() {
    final state = ref.read(recentActivityProvider);
    if (state.autoOpenTab != null) {
      final tab = state.autoOpenTab!;
      ref.read(recentActivityProvider.notifier).clearAutoOpenTab();
      showRecentActivityBottomSheet(context, initialTab: tab);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Ensure visitor is registered (either locally saved or via backend)
  Future<bool> _ensureVisitorRegistered() async {
    // Check if visitor is already saved locally
    final hasLocal = await _visitorService.hasLocalVisitor();
    if (hasLocal) {
      print('✅ Visitor already saved locally');
      return true;
    }

    // Check with backend if device has a visitor account
    print('🔍 Checking visitor status with backend...');
    final checkResult = await _visitorService.checkVisitorLogin();
    
    if (checkResult != null && checkResult['success'] == true) {
      print('✅ Visitor authenticated via backend');
      return true;
    }

    // needs_entity means we need to create a new visitor account
    // For now, just let them proceed - visitor will be created when needed
    if (checkResult?['needs_entity'] == true) {
      print('📝 Device not linked yet - visitor will be created on first action');
      return true; // Allow to proceed, visitor account will be created later in the flow
    }

    // Default: allow access (for cases where backend is unreachable)
    print('⚠️ Could not verify visitor status, proceeding anyway');
    return true;
  }

  void _startManualSearch() async {
    if (_isStartSearchLoading) return;
    
    setState(() => _isStartSearchLoading = true);
    
    try {
      // Ensure visitor is registered before proceeding
      await _ensureVisitorRegistered();

      // Hospital accounts: skip city selection, go directly to blood type
      if (_accountType == 'hospital') {
        await ref.read(searchFlowProvider.notifier).startHospitalSearch();
        if (mounted) {
          context.push('/blood-search/blood-type');
        }
        return;
      }
      
      ref.read(searchFlowProvider.notifier).startManualSearch();
      if (mounted) {
        context.push('/blood-search/city-selection');
      }
    } catch (e) {
      print('❌ Error in _startManualSearch: $e');
      // Proceed anyway on error
      ref.read(searchFlowProvider.notifier).startManualSearch();
      if (mounted) {
        context.push('/blood-search/city-selection');
      }
    } finally {
      if (mounted) {
        setState(() => _isStartSearchLoading = false);
      }
    }
  }

  void _scanHospitalQr() async {
    if (_isScanQrLoading) return;
    
    setState(() => _isScanQrLoading = true);
    
    try {
      // Ensure visitor is registered before proceeding
      await _ensureVisitorRegistered();
      
      final result = await context.push<String>('/blood-search/qr-scanner');
      if (result != null && result.isNotEmpty) {
        await ref.read(searchFlowProvider.notifier).startWithQrScan(result);
        if (mounted) {
          // Hospital accounts skip city selection after QR scan
          final nextRoute = _accountType == 'hospital'
              ? '/blood-search/blood-type'
              : '/blood-search/city-selection';
          context.push(nextRoute);
        }
      }
    } catch (e) {
      print('❌ Error in _scanHospitalQr: $e');
      // Proceed to scanner anyway on error
      final result = await context.push<String>('/blood-search/qr-scanner');
      if (result != null && result.isNotEmpty) {
        await ref.read(searchFlowProvider.notifier).startWithQrScan(result);
        if (mounted) {
          final nextRoute = _accountType == 'hospital'
              ? '/blood-search/blood-type'
              : '/blood-search/city-selection';
          context.push(nextRoute);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isScanQrLoading = false);
      }
    }
  }

  void _navigateToLogin() {
    context.push('/login-options');
  }

  void _navigateToRegister() {
    context.push('/register');
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(canAccessProtectedRoutesProvider);
    final activityState = ref.watch(recentActivityProvider);

    // Listen for autoOpenTab changes to auto-show bottom sheet
    ref.listen<RecentActivityState>(recentActivityProvider, (previous, next) {
      if (next.autoOpenTab != null && !next.isLoading) {
        _checkAutoOpenTab();
      }
    });

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      floatingActionButton: activityState.hasActivity
          ? FloatingActionButton.extended(
              onPressed: () => showRecentActivityBottomSheet(context),
              backgroundColor: Colors.white,
              foregroundColor: ColorPages.COLOR_PRINCIPAL,
              elevation: 6,
              icon: const Icon(Iconsax.activity, size: 22),
              label: Text(
                'my_activity'.tr.isEmpty ? 'My Activity' : 'my_activity'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorPages.COLOR_PRINCIPAL,
              ColorPages.COLOR_PRINCIPAL.withOpacity(0.8),
              Colors.red.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with profile icon if authenticated
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo/Brand
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Iconsax.heart,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'E-Blood',
                          style: GoogleFonts.ubuntu(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Profile icon (if authenticated) and About icon
                    Row(
                      children: [
                        // About icon
                        GestureDetector(
                          onTap: () => context.push('/about'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Iconsax.info_circle,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        // Profile icon (if authenticated)
                        isAuthenticated.when(
                          data: (canAccess) => canAccess
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: GestureDetector(
                                    onTap: () => context.push('/app/ProfilePage'),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Iconsax.user,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hero illustration
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Iconsax.search_normal,
                                  color: Colors.white,
                                  size: 70,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Title
                          Text(
                            'find_blood_title'.tr.isEmpty 
                                ? 'Find Blood Near You' 
                                : 'find_blood_title'.tr,
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Subtitle
                          Text(
                            'find_blood_subtitle'.tr.isEmpty
                                ? 'Search for available blood products in your area'
                                : 'find_blood_subtitle'.tr,
                            style: GoogleFonts.ubuntu(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 48),

                          // Start Search Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isStartSearchLoading ? null : _startManualSearch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: ColorPages.COLOR_PRINCIPAL,
                                disabledBackgroundColor: Colors.white.withOpacity(0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: _isStartSearchLoading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: ColorPages.COLOR_PRINCIPAL,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'loading'.tr.isEmpty ? 'Loading...' : 'loading'.tr,
                                          style: GoogleFonts.ubuntu(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: ColorPages.COLOR_PRINCIPAL,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Iconsax.search_normal_1, size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          'start_search'.tr.isEmpty ? 'Start Search' : 'start_search'.tr,
                                          style: GoogleFonts.ubuntu(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          // Scan QR Button — hidden for hospital accounts (they ARE the hospital)
                          if (_accountType != 'hospital') ...[
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: _isScanQrLoading ? null : _scanHospitalQr,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.white.withOpacity(0.5),
                                  side: BorderSide(
                                    color: _isScanQrLoading ? Colors.white.withOpacity(0.5) : Colors.white, 
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isScanQrLoading
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'loading'.tr.isEmpty ? 'Loading...' : 'loading'.tr,
                                            style: GoogleFonts.ubuntu(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Iconsax.scan_barcode, size: 22),
                                          const SizedBox(width: 8),
                                          Text(
                                            'scan_hospital_qr'.tr.isEmpty 
                                                ? 'Scan Hospital QR Code' 
                                                : 'scan_hospital_qr'.tr,
                                            style: GoogleFonts.ubuntu(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                          ),
                          ],

                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom bar - User info + Home button (logged in) OR Login/Register (guest)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: _isLoggedIn
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            // User avatar
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _accountType == 'hospital' || _accountType == 'blood_bank'
                                    ? Iconsax.hospital
                                    : Iconsax.user,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // User info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _userDisplayName,
                                    style: GoogleFonts.ubuntu(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_userSubtitle.isNotEmpty)
                                    Text(
                                      _userSubtitle,
                                      style: GoogleFonts.ubuntu(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Go to Home button
                            ElevatedButton.icon(
                              onPressed: () => context.go('/app/MainApp'),
                              icon: const Icon(Iconsax.home_2, size: 18),
                              label: Text(
                                'home'.tr.isEmpty ? 'Home' : 'home'.tr,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: ColorPages.COLOR_PRINCIPAL,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _navigateToLogin,
                              child: Text(
                                'login'.tr.isEmpty ? 'Login' : 'login'.tr,
                                style: GoogleFonts.ubuntu(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: _navigateToRegister,
                              child: Text(
                                'register'.tr.isEmpty ? 'Register' : 'register'.tr,
                                style: GoogleFonts.ubuntu(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
