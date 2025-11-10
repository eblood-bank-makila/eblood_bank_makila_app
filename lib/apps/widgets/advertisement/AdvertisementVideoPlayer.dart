import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'AdvertisementService.dart';

/// Video Player Widget for Advertisements
class AdvertisementVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? advertisementId;
  final bool autoPlay;
  final bool looping;
  final bool showControls;

  const AdvertisementVideoPlayer({
    super.key,
    required this.videoUrl,
    this.advertisementId,
    this.autoPlay = true,
    this.looping = true,
    this.showControls = true,
  });

  @override
  State<AdvertisementVideoPlayer> createState() => _AdvertisementVideoPlayerState();
}

class _AdvertisementVideoPlayerState extends State<AdvertisementVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  // Analytics guards
  bool _startSent = false;
  bool _pauseSent = false;
  bool _completeSent = false;

  // Service
  final AdvertisementService _adService = AdvertisementService();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  bool _isYouTube(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }


  Future<void> _initializePlayer() async {
    try {
      // Early exit for YouTube URLs (unsupported by video_player/Chewie)
      if (_isYouTube(widget.videoUrl)) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'YouTube videos are not supported for inline playback.';
          });
        }
        return;
      }

      // Determine if URL is network or asset
      if (widget.videoUrl.startsWith('http://') || widget.videoUrl.startsWith('https://')) {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );
      } else if (widget.videoUrl.startsWith('assets/')) {
        _videoPlayerController = VideoPlayerController.asset(widget.videoUrl);
      } else {
        // Assume it's a file path
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );
      }

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        showControls: widget.showControls,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de lecture vidéo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),

              ],
            ),
          );
        },
      );

      // Add analytics listener after controller is ready
      _videoPlayerController.addListener(_onVideoTick);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_onVideoTick);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _onVideoTick() {
    if (!mounted) return;
    final adId = widget.advertisementId;
    if (adId == null || adId.isEmpty) return;

    final value = _videoPlayerController.value;
    if (!value.isInitialized) return;

    final int posMs = value.position.inMilliseconds;
    final int durMs = value.duration.inMilliseconds;

    if (value.isPlaying) {
      if (!_startSent && posMs > 0) {
        _startSent = true;
        _adService.trackVideoEvent(adId, 'start', positionMs: posMs, durationMs: durMs);
      }
    } else {
      // Not playing: check for completion or pause
      final bool hasDuration = durMs > 0;
      final bool isAtEnd = hasDuration && posMs >= durMs;
      if (!_completeSent && isAtEnd) {
        _completeSent = true;
        _adService.trackVideoEvent(adId, 'complete', positionMs: posMs, durationMs: durMs);
      } else if (!_pauseSent && posMs > 0 && !_completeSent) {
        _pauseSent = true;
        _adService.trackVideoEvent(adId, 'pause', positionMs: posMs, durationMs: durMs);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized || _chewieController == null) {
      return _buildLoadingWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement de la vidéo...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _errorMessage ?? 'Video unavailable',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

