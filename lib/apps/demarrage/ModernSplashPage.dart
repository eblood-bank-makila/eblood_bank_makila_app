import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/theme/ColorPages.dart';
import '../services/FirstLaunchService.dart';
import '../services/FirebaseAuthService.dart';
import '../../utilisateurs/business/interactors/UtilisateurInteractor.dart';
import '../services/AuthApi.dart';
import '../../core/rbac/providers/rbac_provider.dart';

class ModernSplashPage extends ConsumerStatefulWidget {
  const ModernSplashPage({super.key});

  @override
  ConsumerState<ModernSplashPage> createState() => _ModernSplashPageState();
}

class _ModernSplashPageState extends ConsumerState<ModernSplashPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the blood drop
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation for the loading indicator
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _startAnimations();
    _navigateAfterDelay();
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  void _navigateAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        await _determineNextDestination();
      }
    });
  }

  Future<void> _determineNextDestination() async {
    try {
      // Check authentication status more carefully
      final authProvider = ref.read(utilisateurInteractorProvider);
      final firebaseAuthService = ref.read(firebaseAuthServiceProvider);

      // Check first launch status
      final isFirstLaunch = ref.read(firstLaunchServiceProvider);

      // Get tokens with proper error handling
  String? tokenOTP;
  String? jwtToken;
      bool isFirebaseSignedIn = false;

      try {
        tokenOTP = await authProvider.recuperationTokenOtpUseCase.run();
        isFirebaseSignedIn = firebaseAuthService.isSignedIn;
        // Read persisted JWT token (fast cache + secure)
        final storage = GetStorage();
        final cached = storage.read('auth_token');
        if (cached is String && cached.isNotEmpty) {
          jwtToken = cached;
        } else {
          const secure = FlutterSecureStorage();
          jwtToken = await secure.read(key: 'auth_token');
        }
      } catch (e) {
        debugPrint('🚀 ModernSplash: Error checking auth status: $e');
        // Clear any corrupted tokens
        await _clearAllTokens(authProvider);
        tokenOTP = null;
        isFirebaseSignedIn = false;
        jwtToken = null;
      }

  debugPrint('🚀 ModernSplash: tokenOTP=${tokenOTP != null}, jwt=${(jwtToken ?? '').isNotEmpty}, firebase=$isFirebaseSignedIn, firstLaunch=$isFirstLaunch');

      if (mounted) {
        // Only consider user authenticated if we have valid BACKEND tokens
        // Firebase sign-in alone is NOT enough - user must complete registration
        final isAuthenticated = (tokenOTP != null && tokenOTP.isNotEmpty) || ((jwtToken ?? '').isNotEmpty);

        // If Firebase is signed in but no backend token, sign out from Firebase
        // This handles the case where user canceled registration after Google sign-in
        if (isFirebaseSignedIn && !isAuthenticated) {
          debugPrint('🚨 ModernSplash: Firebase signed in but no backend token - signing out from Firebase');
          try {
            await firebaseAuthService.signOut();
          } catch (e) {
            debugPrint('⚠️ ModernSplash: Failed to sign out from Firebase: $e');
          }
        }

        if (isAuthenticated) {
          debugPrint('🚀 ModernSplash: User authenticated');
          // Always hydrate profile for all account types (visitor, blood bank, hospital, etc.)
          bool profileValid = true;
          try {
            if ((jwtToken ?? '').isNotEmpty) {
              final profile = await AuthApi.instance.getUserProfile();
              if (profile == null) {
                debugPrint('🚀 ModernSplash: getUserProfile returned null — token may be stale');
                profileValid = false;
              }
            }
          } catch (e) {
            debugPrint('⚠️ ModernSplash: getUserProfile failed: $e');
            profileValid = false;
          }

          if (!profileValid) {
            // Token is stale/invalid (e.g. 403) — clear tokens and redirect to login
            debugPrint('🚀 ModernSplash: Invalid session, clearing tokens → /welcome');
            await _clearAllTokens(authProvider);
            if (mounted) context.go('/welcome');
          } else {
            // Try loading RBAC from local cache for instant navigation
            final hasCachedApps = await ref.read(rbacProvider.notifier).loadFromCache();
            if (hasCachedApps && mounted) {
              debugPrint('🚀 ModernSplash: Cache hit → /app/MainApp (background refresh)');
              context.go('/app/MainApp');
              // Refresh from API in background
              ref.read(rbacProvider.notifier).refreshInBackground();
            } else if (mounted) {
              // No cache — go through loading screen (API fetch blocking)
              debugPrint('🚀 ModernSplash: No cache → /rbac-loading');
              context.go('/rbac-loading');
            }
          }
        }
        // If it's first launch and not authenticated, show intro slides
        else if (isFirstLaunch) {
          debugPrint('🚀 ModernSplash: First launch, showing intro slides');
          context.go('/intro');
        }
        // If not first launch and not authenticated, go to welcome
        else {
          debugPrint('🚀 ModernSplash: Returning user, going to welcome');
          context.go('/welcome');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _determineNextDestination: $e');
      // Fallback to welcome page
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorPages.COLOR_PRINCIPAL,
              ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
              Colors.red.shade800,
              Colors.red.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with logo and brand
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated blood drop logo
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                // add image instead of icon
                                child: Center(child: Image.asset('assets/images/image2.png',fit: BoxFit.contain, width: 80)),
                                // child: const Icon(
                                //   Icons.water_drop,
                                //   size: 60,
                                //   color: Colors.white,
                                // ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // App name
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          'app_name'.tr,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ubuntu(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Tagline
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        delay: const Duration(milliseconds: 500),
                        child: Text(
                          'app_tagline'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom section with loading indicator
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Modern loading indicator with dots
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      delay: const Duration(milliseconds: 700),
                      child: SizedBox(
                        width: 60,
                        height: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(3, (index) {
                            return AnimatedBuilder(
                              animation: _rotationAnimation,
                              builder: (context, child) {
                                final delay = index * 0.3;
                                final animationValue = (_rotationAnimation.value + delay) % 1.0;
                                final scale = 0.5 + (0.5 * (1 + math.cos(animationValue * 2 * math.pi)) / 2);
                                final opacity = 0.3 + (0.7 * (1 + math.cos(animationValue * 2 * math.pi)) / 2);

                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: opacity),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Loading text
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      delay: const Duration(milliseconds: 900),
                      child: Text(
                        'loading'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Version info at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 1100),
                  child: Text(
                    'v2.0.0',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Clear all authentication tokens to prevent stale token issues
  Future<void> _clearAllTokens(dynamic authProvider) async {
    try {
      // Clear all tokens from local storage
      await authProvider.deconnexionUtilisateurUseCase.run();
      debugPrint('🔐 ModernSplash: All tokens cleared due to authentication error');
    } catch (e) {
      debugPrint('🔐 ModernSplash: Error clearing tokens: $e');
    }
  }
}
