import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../config/theme/ColorPages.dart';
import '../services/FirstLaunchService.dart';

// Data model for onboarding slides
class OnboardingSlide {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;

  OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
  });
}

class IntroSlidePage extends ConsumerStatefulWidget {
  const IntroSlidePage({super.key});

  @override
  ConsumerState<IntroSlidePage> createState() => _IntroSlidePageState();
}

class _IntroSlidePageState extends ConsumerState<IntroSlidePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding slides data
  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      icon: Icons.water_drop,
      title: "Bienvenue sur E-blood Bank Makila",
      subtitle: "Votre Connexion Vitale au Sang",
      description: "Connectez-vous avec les donneurs de sang et les banques en temps réel. Sauvez des vies en quelques clics.",
      color: Colors.red.shade600,
    ),
    OnboardingSlide(
      icon: Icons.location_on,
      title: "Trouvez du Sang à Proximité",
      subtitle: "Localisation Rapide et Facile",
      description: "Localisez instantanément les banques de sang et donneurs les plus proches grâce à notre système de géolocalisation intelligent.",
      color: Colors.blue.shade600,
    ),
    OnboardingSlide(
      icon: Icons.favorite,
      title: "Sauvons des Vies Ensemble",
      subtitle: "Soyez un Héros Aujourd'hui",
      description: "Rejoignez notre communauté de sauveurs. Donnez votre sang, demandez quand vous en avez besoin, et faites la différence.",
      color: Colors.green.shade600,
    ),
    OnboardingSlide(
      icon: Icons.security,
      title: "Sûr et Sécurisé",
      subtitle: "Votre Vie Privée Compte",
      description: "Toutes vos données sont cryptées et sécurisées. Nous priorisons votre confidentialité tout en vous connectant aux ressources vitales.",
      color: Colors.purple.shade600,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    try {
      final firstLaunchService = ref.read(firstLaunchServiceProvider.notifier);
      print('🚀 IntroSlides: Marquage du premier lancement comme terminé');
      await firstLaunchService.markFirstLaunchComplete();
      print('🚀 IntroSlides: Premier lancement marqué terminé, navigation vers la page d\'accueil');

      if (mounted) {
        context.go('/welcome');
      }
    } catch (e) {
      print('❌ Erreur dans _finishOnboarding: $e');
    }
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
              _slides[_currentPage].color,
              _slides[_currentPage].color.withValues(alpha: 0.8),
              _slides[_currentPage].color.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo/Brand
                    FadeInLeft(
                      child: RichText(
                        text: TextSpan(
                          text: 'E-Blood Bank\n',
                          style: GoogleFonts.ubuntu(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: 'Makila',
                              style: GoogleFonts.ubuntu(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: ColorPages.COLOR_BLANCHE,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Skip button
                    FadeInRight(
                      child: TextButton(
                        onPressed: _skipOnboarding,
                        child: Text(
                          'Passer',
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView with slides
              Expanded(
                flex: 4,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index], index);
                  },
                ),
              ),

              // Page indicators and navigation
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Dots indicator
                    FadeInUp(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Navigation buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous button
                          FadeInLeft(
                            child: _currentPage > 0
                                ? TextButton.icon(
                                    onPressed: _previousPage,
                                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                                    label: Text(
                                      'Précédent',
                                      style: GoogleFonts.ubuntu(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 100),
                          ),

                          // Next/Get Started button
                          FadeInRight(
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _slides[_currentPage].color,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentPage == _slides.length - 1
                                        ? 'Commencer'
                                        : 'Suivant',
                                    style: GoogleFonts.ubuntu(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentPage == _slides.length - 1
                                        ? Icons.check
                                        : Icons.arrow_forward,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide, int index) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          FadeInDown(
            delay: Duration(milliseconds: 200 * index),
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
              child: Icon(
                slide.icon,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title
          FadeInUp(
            delay: Duration(milliseconds: 400 + (200 * index)),
            child: Text(
              slide.title,
              style: GoogleFonts.ubuntu(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          FadeInUp(
            delay: Duration(milliseconds: 600 + (200 * index)),
            child: Text(
              slide.subtitle,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Description
          FadeInUp(
            delay: Duration(milliseconds: 800 + (200 * index)),
            child: Text(
              slide.description,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}