import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme/ColorPages.dart';
import 'AdvertisementModel.dart';
import 'AdvertisementService.dart';
import 'AdvertisementVideoPlayer.dart';

/// Modern Advertisement Carousel Widget
/// Can be used in Hospital Home Page and Blood Bank Home Page
class AdvertisementCarousel extends StatefulWidget {
  final String? targetAudience; // 'hospital', 'blood_bank', 'all'
  final double height;
  final bool autoPlay;
  final Duration autoPlayDuration;
  final bool showIndicators;
  final bool useMockData; // For testing without API

  const AdvertisementCarousel({
    super.key,
    this.targetAudience,
    this.height = 180,
    this.autoPlay = true,
    this.autoPlayDuration = const Duration(seconds: 5),
    this.showIndicators = true,
    this.useMockData = true, // Default to mock data until API is ready
  });

  @override
  State<AdvertisementCarousel> createState() => _AdvertisementCarouselState();
}

class _AdvertisementCarouselState extends State<AdvertisementCarousel> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  bool _loading = true;
  List<AdvertisementModel> _advertisements = [];

  final Set<String> _impressionsSent = <String>{};
  Timer? _impressionTimer;

  @override
  void initState() {
    super.initState();
    _loadAdvertisements();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _impressionTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvertisements() async {
    setState(() => _loading = true);

    try {
      List<AdvertisementModel> ads;

      if (widget.useMockData) {
        // Use mock data for testing
        await Future.delayed(const Duration(milliseconds: 300));
        ads = AdvertisementService.getMockAdvertisements();
      } else {
        // Fetch from API
        final service = AdvertisementService();
        if ((widget.targetAudience ?? 'all') == 'all') {
          // Customer-facing home uses customer endpoint
          ads = await service.fetchCustomerAdvertisements().timeout(
            const Duration(seconds: 10),
            onTimeout: () => <AdvertisementModel>[],
          );
        } else {
          // Other homes (hospital, blood_bank) use general endpoint with audience filter
          ads = await service.fetchAdvertisements(targetAudience: widget.targetAudience).timeout(
            const Duration(seconds: 10),
            onTimeout: () => <AdvertisementModel>[],
          );
        }
        // Fallback to mock ONLY if backend returns empty data
        if (ads.isEmpty) {
          ads = AdvertisementService.getMockAdvertisements();
        }
      }
      // Filter by target audience if specified
      if (widget.targetAudience != null) {
        ads = ads.where((ad) => ad.targetAudience == 'all' || ad.targetAudience == widget.targetAudience).toList();
      }

      if (mounted) {
        setState(() {
          _advertisements = ads;
          _loading = false;
        });


        if (ads.isNotEmpty) {
          _trackImpressionFor(_currentPage);
        }

        if (widget.autoPlay && ads.isNotEmpty) {
          _startAutoPlay();
        }
      }
    } catch (e) {
      debugPrint('Error loading advertisements: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _trackImpressionFor(int index) {
    // Cancel any pending impression
    _impressionTimer?.cancel();

    if (index < 0 || index >= _advertisements.length) return;
    final ad = _advertisements[index];
    if (ad.id.isEmpty) return;
    if (_impressionsSent.contains(ad.id)) return;

    // Debounce: only count if visible for at least 1 second
    _impressionTimer = Timer(const Duration(seconds: 1), () {
      // Double-check still same page and not already sent
      if (!mounted) return;
      final currentAd = _advertisements[_currentPage];
      if (currentAd.id != ad.id) return;
      if (_impressionsSent.contains(ad.id)) return;
      _impressionsSent.add(ad.id);
      // ignore: unawaited_futures
      AdvertisementService().trackView(ad.id);
    });
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayDuration, (timer) {
      if (_advertisements.isEmpty) return;

      final nextPage = (_currentPage + 1) % _advertisements.length;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _trackImpressionFor(index);
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  String? _extractYouTubeId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      }
    } catch (_) {}
    return null;
  }

  String? _youtubeThumbUrl(String url) {
    final id = _extractYouTubeId(url);
    if (id == null || id.isEmpty) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }



  Future<void> _handleAdTap(AdvertisementModel ad) async {
    debugPrint('🎯 Advertisement tapped: ${ad.title}');
    debugPrint('   Action Type: ${ad.actionType}');
    debugPrint('   Action URL: ${ad.actionUrl}');

    // Track click analytics (TODO: Implement API call)
    // await AdvertisementService.trackClick(ad.id);

    if (ad.actionType == null || ad.actionType == 'none') {
      // Special case: open YouTube videos externally when no explicit action
      final v = ad.videoUrl;
      if (v != null && v.isNotEmpty && _isYouTubeUrl(v)) {
        // ignore: unawaited_futures
        AdvertisementService().trackClick(ad.id);
        try {
          final uri = Uri.parse(v);
          bool launched = false;

          // Try external application mode first
          try {
            launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint('❌ Failed with externalApplication mode: $e');
          }

          // If that fails, try platform default
          if (!launched) {
            try {
              launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
            } catch (e) {
              debugPrint('❌ Failed with platformDefault mode: $e');
            }
          }

          if (!launched && mounted) {
            _showInfoDialog(
              context,
              'Error',
              'Could not open YouTube URL: $v\n\nPlease make sure you have a browser or YouTube app installed.',
            );
          }
        } catch (e) {
          debugPrint('❌ Error launching YouTube URL: $e');
          if (mounted) {
            _showInfoDialog(
              context,
              'Error',
              'Invalid URL format: $v',
            );
          }
        }
      }
      return;
    }

    if (ad.actionUrl == null || ad.actionUrl!.isEmpty) {
      // If no actionUrl provided, still open YouTube video externally if present
      final v = ad.videoUrl;
      if (v != null && v.isNotEmpty && _isYouTubeUrl(v)) {
        // ignore: unawaited_futures
        AdvertisementService().trackClick(ad.id);
        try {
          final uri = Uri.parse(v);
          bool launched = false;

          // Try external application mode first
          try {
            launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint('❌ Failed with externalApplication mode: $e');
          }

          // If that fails, try platform default
          if (!launched) {
            try {
              launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
            } catch (e) {
              debugPrint('❌ Failed with platformDefault mode: $e');
            }
          }

          if (!launched && mounted) {
            _showInfoDialog(
              context,
              'Error',
              'Could not open YouTube URL: $v\n\nPlease make sure you have a browser or YouTube app installed.',
            );
          }
        } catch (e) {
          debugPrint('❌ Error launching YouTube URL: $e');
          if (mounted) {
            _showInfoDialog(
              context,
              'Error',
              'Invalid URL format: $v',
            );
          }
        }
      }
      return;
    }

    try {
      switch (ad.actionType) {
        case 'internal':
          // Navigate to internal page
          // ignore: unawaited_futures
          AdvertisementService().trackClick(ad.id);

          // TODO: Implement internal navigation based on actionUrl
          debugPrint('   → Internal navigation to: ${ad.actionUrl}');
          // Example: Navigator.pushNamed(context, ad.actionUrl!);
          if (mounted) {
            _showInfoDialog(
              context,
              'Navigation',
              'Internal navigation to: ${ad.actionUrl}\n\nThis will be implemented based on your app routes.',
            );
          }
          break;

        case 'external':
          // Open external URL
          // ignore: unawaited_futures
          AdvertisementService().trackClick(ad.id);

          try {
            final url = Uri.parse(ad.actionUrl!);

            // Try to launch with external application mode first
            bool launched = false;
            try {
              launched = await launchUrl(
                url,
                mode: LaunchMode.externalApplication,
              );
            } catch (e) {
              debugPrint('❌ Failed to launch with externalApplication mode: $e');
            }

            // If that fails, try platformDefault mode
            if (!launched) {
              try {
                launched = await launchUrl(
                  url,
                  mode: LaunchMode.platformDefault,
                );
              } catch (e) {
                debugPrint('❌ Failed to launch with platformDefault mode: $e');
              }
            }

            // If still not launched, show error
            if (!launched) {
              if (mounted) {
                _showInfoDialog(
                  context,
                  'Error',
                  'Could not open URL: ${ad.actionUrl}\n\nPlease make sure you have a browser installed.',
                );
              }
            }
          } catch (e) {
            debugPrint('❌ Error parsing or launching URL: $e');
            if (mounted) {
              _showInfoDialog(
                context,
                'Error',
                'Invalid URL format: ${ad.actionUrl}',
              );
            }
          }
          break;

        case 'modal':
          // Show modal with details
          // ignore: unawaited_futures
          AdvertisementService().trackClick(ad.id);

          if (mounted) {
            _showAdDetailsModal(context, ad);
          }
          break;

        default:
          debugPrint('   → Unknown action type: ${ad.actionType}');
      }
    } catch (e) {
      debugPrint('❌ Error handling ad tap: $e');
      if (mounted) {
        _showInfoDialog(
          context,
          'Error',
          'An error occurred: $e',
        );
      }
    }
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAdDetailsModal(BuildContext context, AdvertisementModel ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ad.imageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    ColorPages.COLOR_PRINCIPAL,
                                    ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Title
                    Text(
                      ad.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description
                    if (ad.description != null && ad.description!.isNotEmpty)
                      Text(
                        ad.description!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPages.COLOR_PRINCIPAL,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Fermer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildShimmerLoading();
    }

    if (_advertisements.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no ads
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          // Carousel
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _advertisements.length,
              itemBuilder: (context, index) {
                return _buildAdvertisementCard(_advertisements[index]);
              },
            ),
          ),

          // Indicators
          if (widget.showIndicators && _advertisements.length > 1)
            _buildIndicators(),
        ],
      ),
    );
  }

  Widget _buildAdvertisementCard(AdvertisementModel ad) {
    return GestureDetector(
      onTap: () => _handleAdTap(ad),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: Video, Image, or YouTube thumbnail, or Gradient
              if (ad.videoUrl != null && ad.videoUrl!.isNotEmpty && !_isYouTubeUrl(ad.videoUrl!))
                // Video Player (non-YouTube)
                AdvertisementVideoPlayer(
                  videoUrl: ad.videoUrl!,
                  advertisementId: ad.id,
                  autoPlay: true,
                  looping: true,
                  showControls: false, // Hide controls in carousel
                )
              else if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty)
                // Image
                _buildImage(ad.imageUrl!)
              else if (ad.videoUrl != null && ad.videoUrl!.isNotEmpty && _isYouTubeUrl(ad.videoUrl!))
                // YouTube thumbnail fallback when no image provided
                (_youtubeThumbUrl(ad.videoUrl!) != null)
                    ? _buildImage(_youtubeThumbUrl(ad.videoUrl!)!)
                    : _buildGradientBackground()
              else
                // Gradient Fallback
                _buildGradientBackground(),

              // Overlay gradient for better text visibility (only for video/image)
              if (ad.videoUrl != null || ad.imageUrl != null)
                Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      ad.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Description
                    if (ad.description != null && ad.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          ad.description!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // Action Indicator (if clickable)
              if (ad.actionType != null && ad.actionType != 'none')
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.touch_app,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    // Check if it's a local asset or network image
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildGradientBackground();
        },
      );
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildGradientBackground();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildGradientBackground();
        },
      );
    }
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorPages.COLOR_PRINCIPAL,
            ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _advertisements.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? ColorPages.COLOR_PRINCIPAL
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: widget.height,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

