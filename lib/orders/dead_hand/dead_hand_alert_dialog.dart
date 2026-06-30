/// Sprint M — full-screen ringing alert when a dead-hand broadcast lands.
///
/// Shown via `Navigator.push` on top of every other route. Behaviour:
///   * Plays a heavy haptic on mount and every 800ms while visible
///     (substitutes for the iOS Critical-Alerts ringing without
///     needing the entitlement).
///   * Counts down `ttlSeconds` and auto-declines on expiry.
///   * Accept → resolves the future with `true` so the caller can
///     fire the claim API call.
///   * Decline / system back → resolves with `false`.
///
/// The dialog is intentionally a full route (not a Material `Dialog`)
/// so it can show even if no other dialog is on top.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dead_hand_alert_payload.dart';

class DeadHandAlertScreen extends StatefulWidget {
  final DeadHandAlertPayload payload;

  const DeadHandAlertScreen({super.key, required this.payload});

  /// Push the alert onto the given navigator and return the user's
  /// decision: `true` for accept, `false` for decline / timeout.
  static Future<bool> show(
    NavigatorState navigator,
    DeadHandAlertPayload payload,
  ) async {
    final result = await navigator.push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => DeadHandAlertScreen(payload: payload),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
    return result ?? false;
  }

  @override
  State<DeadHandAlertScreen> createState() => _DeadHandAlertScreenState();
}

class _DeadHandAlertScreenState extends State<DeadHandAlertScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _countdown;
  Timer? _hapticLoop;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.payload.ttlSeconds;

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Heavy haptic on mount + every 800ms after — looks-and-feels
    // like a phone ringing without needing the iOS Critical Alerts
    // entitlement.
    HapticFeedback.heavyImpact();
    _hapticLoop = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) {
        if (mounted) HapticFeedback.heavyImpact();
      },
    );

    // Countdown — auto-decline at 0.
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) {
        timer.cancel();
        _close(false);
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _countdown?.cancel();
    _hapticLoop?.cancel();
    super.dispose();
  }

  void _close(bool accepted) {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(accepted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return PopScope(
      // System back is the same as Decline.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(false);
      },
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: media.size.height * 0.05,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Pulsing red drop icon ──
                Expanded(
                  child: Center(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                      ),
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.redAccent,
                            width: 3,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.bloodtype,
                            size: 72,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Headline ──
                Column(
                  children: [
                    const Text(
                      'Livraison disponible',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.payload.scopeLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Réf. : ${widget.payload.orderId}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),

                // ── Countdown bar ──
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: widget.payload.ttlSeconds == 0
                          ? 0
                          : _secondsLeft / widget.payload.ttlSeconds,
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _secondsLeft <= 10 ? Colors.redAccent : Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _secondsLeft > 0
                          ? '$_secondsLeft s pour accepter'
                          : 'Expiré',
                      style: TextStyle(
                        color: _secondsLeft <= 10
                            ? Colors.redAccent
                            : Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // ── Buttons ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _close(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Refuser',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => _close(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Accepter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
