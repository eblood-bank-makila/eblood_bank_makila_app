/// Blood Search Welcome Page
/// Landing page for the blood search journey

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../providers/search_flow_provider.dart';
import '../../data/services/visitor_registration_service_impl.dart';
import '../../../apps/config/theme/ColorPages.dart';

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

    // Reset search flow when arriving at welcome page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchFlowProvider.notifier).resetFlow();
    });
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
          context.push('/blood-search/city-selection');
        }
      }
    } catch (e) {
      print('❌ Error in _scanHospitalQr: $e');
      // Proceed to scanner anyway on error
      final result = await context.push<String>('/blood-search/qr-scanner');
      if (result != null && result.isNotEmpty) {
        await ref.read(searchFlowProvider.notifier).startWithQrScan(result);
        if (mounted) {
          context.push('/blood-search/city-selection');
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

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
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

                          const SizedBox(height: 16),

                          // Scan QR Button
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

                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom buttons - Login / Register
              Padding(
                padding: const EdgeInsets.all(24),
                child: isAuthenticated.when(
                  data: (canAccess) => canAccess
                      ? const SizedBox.shrink()
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
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
