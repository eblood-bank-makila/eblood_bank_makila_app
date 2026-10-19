/// Full-screen courier call, like Yango calling a driver: where to pick
/// up, where to deliver, how far, what, and one big "Accepter".
/// Pops with a [DeliveryCallOutcome]; the dispatch can close it remotely
/// through [closedReason] (someone else took it, the call ended).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'delivery_call_payload.dart';

enum DeliveryCallOutcome { accepted, declined, closedRemotely, expired }

class DeliveryCallScreen extends StatefulWidget {
  final DeliveryCallPayload call;
  final ValueNotifier<String?> closedReason;

  /// Returns null on success, else the message to show (e.g. 409 « Course déjà prise »).
  final Future<String?> Function(String deliveryId) accept;

  const DeliveryCallScreen({
    super.key,
    required this.call,
    required this.closedReason,
    required this.accept,
  });

  @override
  State<DeliveryCallScreen> createState() => _DeliveryCallScreenState();
}

class DeliveryCallResult {
  final DeliveryCallOutcome outcome;
  final String? message;
  const DeliveryCallResult(this.outcome, [this.message]);
}

class _DeliveryCallScreenState extends State<DeliveryCallScreen> {
  Timer? _tick;
  Timer? _haptics;
  bool _busy = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _haptics = Timer.periodic(const Duration(milliseconds: 800), (_) => HapticFeedback.heavyImpact());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.call.timeLeft() == Duration.zero) {
        _finish(const DeliveryCallResult(DeliveryCallOutcome.expired, 'Appel terminé.'));
      } else {
        setState(() {});
      }
    });
    widget.closedReason.addListener(_onClosed);
  }

  void _onClosed() {
    final message = widget.closedReason.value;
    if (message != null) _finish(DeliveryCallResult(DeliveryCallOutcome.closedRemotely, message));
  }

  void _finish(DeliveryCallResult result) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(result);
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    final error = await widget.accept(widget.call.deliveryId);
    if (!mounted) return;
    if (error == null) {
      _finish(const DeliveryCallResult(DeliveryCallOutcome.accepted, 'Course acceptée.'));
    } else {
      _finish(DeliveryCallResult(DeliveryCallOutcome.closedRemotely, error));
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _haptics?.cancel();
    widget.closedReason.removeListener(_onClosed);
    super.dispose();
  }

  String _km(double? km) => km == null ? '—' : '${km.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final left = call.timeLeft();
    final mm = left.inMinutes.toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
    const white70 = TextStyle(color: Colors.white70, fontSize: 14);

    Widget stop(IconData icon, String label, String name, String address, String distance) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(icon, color: Colors.redAccent, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: white70),
                Text(name.isEmpty ? '—' : name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                if (address.isNotEmpty) Text(address, style: white70),
              ]),
            ),
            Text(distance, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(const DeliveryCallResult(DeliveryCallOutcome.declined));
      },
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                if (call.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                    child: const Text('URGENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                const Spacer(),
                Text('$mm:$ss', key: const Key('call-countdown'),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 18),
              const Text('Nouvelle livraison de sang',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              if (call.identifier.isNotEmpty)
                Text(call.identifier, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38)),
              const SizedBox(height: 20),
              stop(Icons.bloodtype, 'Banque de sang · à récupérer', call.bloodBankName, call.bloodBankAddress,
                  'à ${_km(call.kmToBloodBank)}'),
              const SizedBox(height: 10),
              stop(Icons.local_hospital, "Hôpital · à livrer", call.hospitalName, call.hospitalAddress,
                  '+ ${_km(call.kmBankToHospital)}'),
              const SizedBox(height: 14),
              if (call.bagCount != null || call.bloodSummary.isNotEmpty)
                Text(
                  [
                    if (call.bagCount != null) '${call.bagCount} poche${call.bagCount! > 1 ? 's' : ''}',
                    if (call.bloodSummary.isNotEmpty) call.bloodSummary,
                  ].join(' · '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              const Spacer(),
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  key: const Key('call-accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  onPressed: _busy ? null : _accept,
                  child: _busy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Accepter', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                key: const Key('call-decline'),
                onPressed: _busy ? null : () => _finish(const DeliveryCallResult(DeliveryCallOutcome.declined)),
                child: const Text('Ignorer', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
