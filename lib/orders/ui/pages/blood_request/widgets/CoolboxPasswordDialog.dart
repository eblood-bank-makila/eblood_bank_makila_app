import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import 'package:eblood_bank_mak_app/apps/config/api/ApiConfig.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/orders/business/model/blood_request/BloodRequestModel.dart';
import 'package:eblood_bank_mak_app/orders/ui/framework/blood_request/BloodRequestNetworkServiceImpl.dart';

class CoolboxPasswordDialog extends StatefulWidget {
  final BloodRequestModel request;

  const CoolboxPasswordDialog({super.key, required this.request});

  @override
  State<CoolboxPasswordDialog> createState() => _CoolboxPasswordDialogState();
}

class _CoolboxPasswordDialogState extends State<CoolboxPasswordDialog> {
  final _service = BloodRequestNetworkServiceImpl(ApiConfig.BASE_URL);
  bool _loading = false;
  bool _obscure = true;
  String? _password;
  String? _error;

  Future<void> _fetchPassword() async {
    setState(() {
      _loading = true;
      _password = null;
      _error = null;
    });
    try {
      // Prefer deliveryCoolboxId if present, otherwise fallback to request id
      final deliveryId = widget.request.deliveryCoolboxId?.isNotEmpty == true
          ? widget.request.deliveryCoolboxId!
          : widget.request.id;
      final IApiResponse res = await _service.requestCoolboxPassword(deliveryId);
      if (res.success) {
        final data = res.data;
        String? pwd;
        if (data is Map<String, dynamic>) {
          pwd = (data['coolbox_password'] ?? data['password'] ?? data['code'])?.toString();
        } else if (data is String) {
          pwd = data;
        }
        setState(() => _password = pwd ?? '');
      } else {
        setState(() => _error = res.message ?? 'Impossible de récupérer le mot de passe du coolbox');
      }
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPassword();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Mot de passe du coolbox', style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            : _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: GoogleFonts.ubuntu(color: Colors.red)),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _fetchPassword, child: const Text('Réessayer')),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Code actuel', style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _obscure && (_password ?? '').isNotEmpty ? '••••••••' : (_password ?? ''),
                                style: GoogleFonts.ubuntu(fontSize: 18, letterSpacing: 1.2),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              tooltip: _obscure ? 'Afficher' : 'Masquer',
                            ),
                            IconButton(
                              onPressed: (_password ?? '').isEmpty
                                  ? null
                                  : () async {
                                      await Clipboard.setData(ClipboardData(text: _password!));
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Mot de passe copié')),
                                      );
                                    },
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copier',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

