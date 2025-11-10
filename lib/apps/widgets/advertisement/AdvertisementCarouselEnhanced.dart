import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'AdvertisementModel.dart';
import 'AdvertisementCarousel.dart';

/// Enhanced Advertisement Carousel with Parallax and Zoom Effects
class AdvertisementCarouselEnhanced extends StatefulWidget {
  final bool useMockData;
  final double height;
  final bool autoPlay;
  final Duration autoPlayDuration;
  final bool showIndicators;
  final bool enableParallax;
  final bool enableZoom;

  const AdvertisementCarouselEnhanced({
    super.key,
    this.useMockData = false,
    this.height = 200,
    this.autoPlay = true,
    this.autoPlayDuration = const Duration(seconds: 5),
    this.showIndicators = true,
    this.enableParallax = true,
    this.enableZoom = true,
  });

  @override
  State<AdvertisementCarouselEnhanced> createState() => _AdvertisementCarouselEnhancedState();
}

class _AdvertisementCarouselEnhancedState extends State<AdvertisementCarouselEnhanced>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  double _pageOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _pageController.addListener(_onPageScroll);
    
    // Zoom animation controller
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOut),
    );
    
    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  void _onPageScroll() {
    if (_pageController.hasClients) {
      setState(() {
        _pageOffset = _pageController.page ?? 0.0;
      });
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(widget.autoPlayDuration, (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % 5; // Assuming 5 ads
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    
    // Trigger zoom animation
    if (widget.enableZoom) {
      _zoomController.forward().then((_) {
        _zoomController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the standard carousel but with enhanced effects
    return Stack(
      children: [
        // Background parallax layer
        if (widget.enableParallax)
          _buildParallaxBackground(),
        
        // Main carousel
        AdvertisementCarousel(
          useMockData: widget.useMockData,
          height: widget.height,
          autoPlay: widget.autoPlay,
          autoPlayDuration: widget.autoPlayDuration,
          showIndicators: widget.showIndicators,
        ),
      ],
    );
  }

  Widget _buildParallaxBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          double parallaxOffset = 0.0;
          if (_pageController.hasClients) {
            parallaxOffset = (_pageController.page ?? 0.0) * 50;
          }
          
          return Transform.translate(
            offset: Offset(-parallaxOffset, 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withValues(alpha: 0.1),
                    Colors.purple.withValues(alpha: 0.1),
                    Colors.pink.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Parallax Image Widget for use in carousel cards
class ParallaxImage extends StatelessWidget {
  final String imageUrl;
  final double pageOffset;
  final int index;

  const ParallaxImage({
    super.key,
    required this.imageUrl,
    required this.pageOffset,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate parallax offset
    final double parallax = (pageOffset - index) * 50;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Transform.translate(
        offset: Offset(parallax, 0),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade400,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Zoom Animation Wrapper
class ZoomAnimationWrapper extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const ZoomAnimationWrapper({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<ZoomAnimationWrapper> createState() => _ZoomAnimationWrapperState();
}

class _ZoomAnimationWrapperState extends State<ZoomAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 3D Flip Animation for Advertisement Cards
class FlipAnimationCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;

  const FlipAnimationCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<FlipAnimationCard> createState() => _FlipAnimationCardState();
}

class _FlipAnimationCardState extends State<FlipAnimationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void flip() {
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14159; // π radians
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(angle);
          
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle < 1.5708 // π/2
                ? widget.front
                : Transform(
                    transform: Matrix4.identity()..rotateY(3.14159),
                    alignment: Alignment.center,
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

