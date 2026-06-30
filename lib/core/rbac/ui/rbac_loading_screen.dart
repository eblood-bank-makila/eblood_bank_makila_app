import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import '../providers/rbac_provider.dart';

// ── Loading phases ──
enum _Phase { connecting, authenticating, discovering, loadingApps, ready }

class _AppProgress {
  final int index;
  String name;
  String flag;
  int subMenusCount;
  bool completed;

  _AppProgress({
    required this.index,
    this.name = '',
    this.flag = '',
    this.subMenusCount = 0,
    this.completed = false,
  });
}

class RbacLoadingScreen extends ConsumerStatefulWidget {
  const RbacLoadingScreen({super.key});

  @override
  ConsumerState<RbacLoadingScreen> createState() => _RbacLoadingScreenState();
}

class _RbacLoadingScreenState extends ConsumerState<RbacLoadingScreen>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  bool _hasFailed = false;
  _Phase _phase = _Phase.connecting;
  int _totalApps = 0;
  int _completedApps = 0;
  final List<_AppProgress> _apps = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadWithProgress();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadWithProgress() async {
    setState(() {
      _hasFailed = false;
      _phase = _Phase.connecting;
      _totalApps = 0;
      _completedApps = 0;
      _apps.clear();
    });

    // Phase 1: Connecting
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _phase = _Phase.authenticating);

    // Phase 2: Authenticating
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _phase = _Phase.discovering);

    try {
      // Phase 3+4: Discovering apps → Loading each one
      await ref.read(rbacProvider.notifier).loadApplicationsWithProgress(
        (event) {
          if (!mounted) return;

          switch (event.event) {
            case 'init':
              setState(() {
                _phase = _Phase.loadingApps;
                _totalApps = event.total;
                _apps.clear();
                for (int i = 0; i < event.total; i++) {
                  _apps.add(_AppProgress(index: i));
                }
              });
              break;

            case 'app_complete':
              setState(() {
                final idx = event.index;
                if (idx < _apps.length) {
                  _apps[idx]
                    ..name = event.name
                    ..flag = event.flag
                    ..subMenusCount = event.subMenusCount
                    ..completed = true;
                }
                _completedApps = _apps.where((a) => a.completed).length;
              });
              break;

            case 'done':
              if (mounted) setState(() => _phase = _Phase.ready);
              break;
          }
        },
      );

      final state = ref.read(rbacProvider);
      if (state.hasError) {
        if (mounted) setState(() => _hasFailed = true);
        return;
      }

      if (mounted) setState(() => _phase = _Phase.ready);
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.go('/app/MainApp');
      }
    } catch (e) {
      debugPrint('[RBAC Loading] Error: $e');
      if (mounted) setState(() => _hasFailed = true);
    }
  }

  void _retry() {
    ref.read(rbacProvider.notifier).reset();
    _hasNavigated = false;
    _loadWithProgress();
  }

  // ── Phase metadata ──
  IconData get _phaseIcon {
    switch (_phase) {
      case _Phase.connecting:
        return Iconsax.wifi;
      case _Phase.authenticating:
        return Iconsax.shield_tick;
      case _Phase.discovering:
        return Iconsax.search_normal;
      case _Phase.loadingApps:
        return Iconsax.element_3;
      case _Phase.ready:
        return Iconsax.tick_circle;
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case _Phase.connecting:
        return 'loading_step_connecting'.tr;
      case _Phase.authenticating:
        return 'loading_step_profile'.tr;
      case _Phase.discovering:
        return 'loading_step_applications'.tr;
      case _Phase.loadingApps:
        if (_totalApps > 0) {
          return '${'loading_step_applications'.tr} $_completedApps/$_totalApps';
        }
        return 'loading_step_applications'.tr;
      case _Phase.ready:
        return 'loading_step_preparing'.tr;
    }
  }

  double get _overallProgress {
    // 5 phases: connecting(0.1), authenticating(0.2), discovering(0.3), loadingApps(0.3→0.9), ready(1.0)
    switch (_phase) {
      case _Phase.connecting:
        return 0.1;
      case _Phase.authenticating:
        return 0.2;
      case _Phase.discovering:
        return 0.3;
      case _Phase.loadingApps:
        final appProgress = _totalApps > 0 ? _completedApps / _totalApps : 0.0;
        return 0.3 + (appProgress * 0.6); // 0.3 → 0.9
      case _Phase.ready:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rbacState = ref.watch(rbacProvider);

    if (rbacState.isLoaded && !_hasNavigated && _phase == _Phase.ready) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/app/MainApp');
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFF5F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _hasFailed ? _buildErrorView() : _buildLoadingView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.08);
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _phase == _Phase.ready
                  ? Colors.green.withValues(alpha: 0.12)
                  : ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _phaseIcon,
                key: ValueKey(_phase),
                size: 36,
                color: _phase == _Phase.ready
                    ? Colors.green
                    : ColorPages.COLOR_PRINCIPAL,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Phase label (animated text swap)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _phaseLabel,
            key: ValueKey(_phaseLabel),
            style: GoogleFonts.ubuntu(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Overall progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _overallProgress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _phase == _Phase.ready
                    ? Colors.green
                    : ColorPages.COLOR_PRINCIPAL,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Percentage
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _overallProgress),
          duration: const Duration(milliseconds: 400),
          builder: (context, value, _) => Text(
            '${(value * 100).round()}%',
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Phase step dots (always visible — shows overall journey)
        _buildPhaseSteps(),
        const SizedBox(height: 16),

        // Per-app indicators (only during loadingApps phase)
        if (_phase == _Phase.loadingApps && _apps.isNotEmpty) ...[
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _apps.length,
              itemBuilder: (context, i) => _buildAppRow(_apps[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhaseSteps() {
    final phases = [
      (_Phase.connecting, Iconsax.wifi, 'loading_step_connecting'.tr),
      (_Phase.authenticating, Iconsax.shield_tick, 'loading_step_profile'.tr),
      (_Phase.discovering, Iconsax.search_normal, 'loading_step_applications'.tr),
      (_Phase.loadingApps, Iconsax.element_3, 'loading_step_applications'.tr),
      (_Phase.ready, Iconsax.tick_circle, 'loading_step_preparing'.tr),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(phases.length, (i) {
        final (phase, icon, _) = phases[i];
        final isCompleted = _phase.index > phase.index;
        final isActive = _phase == phase;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: isActive ? 28 : 20,
            height: isActive ? 28 : 20,
            decoration: BoxDecoration(
              color: isCompleted
                  ? ColorPages.COLOR_PRINCIPAL
                  : isActive
                      ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(color: ColorPages.COLOR_PRINCIPAL, width: 2)
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : Icon(icon, size: isActive ? 14 : 10,
                      color: isActive
                          ? ColorPages.COLOR_PRINCIPAL
                          : Colors.grey.shade300),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAppRow(_AppProgress app) {
    return AnimatedOpacity(
      opacity: app.completed ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: app.completed
                    ? ColorPages.COLOR_PRINCIPAL
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: !app.completed
                    ? Border.all(
                        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                        width: 1.5)
                    : null,
              ),
              child: Center(
                child: app.completed
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.5)),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      app.completed && app.name.isNotEmpty
                          ? app.name
                          : '...',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        fontWeight: app.completed ? FontWeight.w600 : FontWeight.w400,
                        color: app.completed
                            ? Colors.grey.shade800
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  if (app.completed && app.subMenusCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${app.subMenusCount}',
                        style: GoogleFonts.ubuntu(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.wifi_square, size: 36, color: Colors.red),
        ),
        const SizedBox(height: 28),
        Text(
          'error_occurred'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'error_loading_data'.tr,
          textAlign: TextAlign.center,
          style: GoogleFonts.ubuntu(fontSize: 14, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _retry,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: Text('retry'.tr),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPages.COLOR_PRINCIPAL,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
        ),
      ],
    );
  }
}
