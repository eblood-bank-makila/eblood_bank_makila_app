import 'package:flutter/material.dart';
import '../network/network_manager.dart';

/// Enhanced NetworkStatusWidget with:
/// - Debounced backend state changes (handled in NetworkManager)
/// - Overlay banner that only takes room while offline (pushes the pages'
///   top inset down; `preserveSpace` is kept for API compatibility, unused)
/// - Smooth fade animation
/// - Retry button with progress indicator
class NetworkStatusWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;
  final String? offlineMessage; // If null, use translation key if available
  final bool absorbPointerWhenOffline;
  final bool preserveSpace;
  final Duration fadeDuration;

  const NetworkStatusWidget({
    super.key,
    required this.child,
    this.onRetry,
    this.offlineMessage,
    this.absorbPointerWhenOffline = false,
    this.preserveSpace = true,
    this.fadeDuration = const Duration(milliseconds: 300),
  });

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget>
    with SingleTickerProviderStateMixin {
  late bool _isBackendAvailable;
  late final Stream<bool> _backendStream;
  late final AnimationController _controller;
  late final Animation<double> _fade;
  bool _isRetrying = false;
  static const double _bannerHeight = 44;

  @override
  void initState() {
    super.initState();
    final manager = NetworkManager();
    _isBackendAvailable = manager.isBackendAvailable;
    _backendStream = manager.backendStatus;

    _controller = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (!_isBackendAvailable) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      widget.onRetry?.call();
      await NetworkManager().retryBackendConnection();
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _backendStream,
      initialData: _isBackendAvailable,
      builder: (context, snapshot) {
        final available = snapshot.data ?? true;
        if (available != _isBackendAvailable) {
          _isBackendAvailable = available;
          if (!_isBackendAvailable) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        }

        Widget child = widget.child;
        if (widget.absorbPointerWhenOffline && !_isBackendAvailable) {
          child = AbsorbPointer(child: child);
        }

        // The app keeps the whole screen (edge-to-edge, Android 15+). Nothing is
        // reserved while online; when offline the banner sits under the status
        // bar and the pages' top inset grows by its height, so every SafeArea /
        // AppBar moves down below it instead of being covered.
        final media = MediaQuery.of(context);
        final statusBar = media.padding.top;
        if (!_isBackendAvailable) {
          child = MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(top: statusBar + _bannerHeight),
              viewPadding: media.viewPadding.copyWith(
                top: media.viewPadding.top + _bannerHeight,
              ),
            ),
            child: child,
          );
        }

        return Stack(
          children: [
            Positioned.fill(child: child),
            if (!_isBackendAvailable)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: statusBar + _bannerHeight,
                child: FadeTransition(
                  opacity: _fade,
                  child: _OfflineBanner(
                    message: widget.offlineMessage ?? 'backend_unavailable',
                    retrying: _isRetrying,
                    onRetry: _retry,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool retrying;

  const _OfflineBanner({
    required this.message,
    required this.onRetry,
    required this.retrying,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = message;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (retrying)
                const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension NetworkStatusExtension on Widget {
  Widget withNetworkStatus({
    String? offlineMessage,
    bool absorbPointerWhenOffline = false,
    bool preserveSpace = true,
    VoidCallback? onRetry,
  }) => NetworkStatusWidget(
    child: this,
    offlineMessage: offlineMessage,
    absorbPointerWhenOffline: absorbPointerWhenOffline,
    preserveSpace: preserveSpace,
    onRetry: onRetry,
  );
}
