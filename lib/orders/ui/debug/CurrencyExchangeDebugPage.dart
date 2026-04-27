import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:eblood_bank_mak_app/orders/ui/pages/panier/PanierCtrl.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../../apps/config/AppConfig.dart';
import '../../../utilisateurs/business/interactors/UtilisateurInteractor.dart';
import '../../business/service/CurrencyExchangeService.dart';

class CurrencyExchangeDebugPage extends ConsumerStatefulWidget {
  const CurrencyExchangeDebugPage({super.key});

  @override
  ConsumerState<CurrencyExchangeDebugPage> createState() => _CurrencyExchangeDebugPageState();
}

class _CurrencyExchangeDebugPageState extends ConsumerState<CurrencyExchangeDebugPage> {
  String _debugInfo = '';
  bool _showRawData = false;

  @override
  Widget build(BuildContext context) {
    final panierState = ref.watch(panierCtrlProvider);
    final amount = panierState.paniers?.data.isNotEmpty == true
        ? panierState.paniers!.data[0].totalPrice.toDouble()
        : 0.0;
    final cart = panierState.paniers?.data.isNotEmpty == true ? panierState.paniers!.data[0] : null;
    final itemCurrencyId = (cart?.cartItems.isNotEmpty == true) ? cart!.cartItems[0].currencyId : '';
    final currencyId = itemCurrencyId.isNotEmpty ? itemCurrencyId : (cart?.refCurrencyId ?? '');
    final currencyExchangeAsync = ref.watch(
      currencyExchangeProvider(
        CurrencyExchangeParams(amount: amount, refCurrencyId: currencyId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Currency Exchange Debug',
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // Refresh the provider with current params
              final ps = ref.read(panierCtrlProvider);
              final amt = ps.paniers?.data.isNotEmpty == true
                  ? ps.paniers!.data[0].totalPrice.toDouble()
                  : 0.0;
              final cart = ps.paniers?.data.isNotEmpty == true ? ps.paniers!.data[0] : null;
              final itemCurrencyId = (cart?.cartItems.isNotEmpty == true) ? cart!.cartItems[0].currencyId : '';
              final cid = itemCurrencyId.isNotEmpty ? itemCurrencyId : (cart?.refCurrencyId ?? '');
              ref.invalidate(currencyExchangeProvider(CurrencyExchangeParams(amount: amt, refCurrencyId: cid)));
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => _testManualFetch(),
            icon: const Icon(Icons.bug_report),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currency Exchange API Debug',
              style: GoogleFonts.ubuntu(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: currencyExchangeAsync.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading currency exchanges...'),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading currencies',
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: GoogleFonts.ubuntu(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final ps = ref.read(panierCtrlProvider);
                          final amt = ps.paniers?.data.isNotEmpty == true
                              ? ps.paniers!.data[0].totalPrice.toDouble()
                              : 0.0;
                          final cart = ps.paniers?.data.isNotEmpty == true ? ps.paniers!.data[0] : null;
                          final itemCurrencyId = (cart?.cartItems.isNotEmpty == true) ? cart!.cartItems[0].currencyId : '';
                          final cid = itemCurrencyId.isNotEmpty ? itemCurrencyId : (cart?.refCurrencyId ?? '');
                          ref.invalidate(currencyExchangeProvider(CurrencyExchangeParams(amount: amt, refCurrencyId: cid)));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (currencyResponse) => SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Manual Test Button
                      _buildManualTestCard(),
                      const SizedBox(height: 16),

                      // Response Status
                      _buildStatusCard(currencyResponse),
                      const SizedBox(height: 16),

                      // Detailed API Info
                      _buildApiInfoCard(),
                      const SizedBox(height: 16),

                      // Currency Data
                      if (currencyResponse.data.isNotEmpty) ...[
                        Text(
                          'Available Currencies (${currencyResponse.data.length})',
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...currencyResponse.data.map((currency) =>
                          _buildCurrencyCard(currency)
                        ),
                      ] else ...[
                        _buildEmptyStateCard(),
                      ],

                      const SizedBox(height: 16),

                      // Test Conversion
                      _buildTestConversionCard(currencyResponse),

                      const SizedBox(height: 16),

                      // Raw Data Toggle
                      _buildRawDataCard(currencyResponse),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(currencyResponse) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  currencyResponse.success ? Icons.check_circle : Icons.error,
                  color: currencyResponse.success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'API Response Status',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Success: ${currencyResponse.success}'),
            Text('Data Count: ${currencyResponse.data.length}'),
            if (currencyResponse.message.isNotEmpty)
              Text('Message: ${currencyResponse.message}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyCard(currency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${currency.currencyFromCode} → ${currency.currencyToCode}',
                    style: GoogleFonts.ubuntu(
                      fontWeight: FontWeight.w600,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Rate: ${currency.exchangedValue}',
                  style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('ID: ${currency.id}'),
            Text('From: ${currency.currencyFrom}'),
            Text('To: ${currency.currencyTo}'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.currency_exchange,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              'No Currency Exchanges Found',
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'The API returned no currency exchange data.',
              style: GoogleFonts.ubuntu(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestConversionCard(currencyResponse) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversion preview (server-calculated amounts)',
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (currencyResponse.data.isNotEmpty) ...[
              ...currencyResponse.data.map((currency) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${currency.currencyFromCode} → ${currency.currencyToCode}'),
                      Text(
                        '${currency.convertedAmount.toStringAsFixed(2)} ${currency.currencyToCode} (amount: ${currency.amount.toStringAsFixed(2)})',
                        style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              const Text('No currencies available for conversion'),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _testManualFetch() async {
    try {
      final service = ref.read(currencyExchangeServiceProvider);
      final ps = ref.read(panierCtrlProvider);
      final amt = ps.paniers?.data.isNotEmpty == true
          ? ps.paniers!.data[0].totalPrice.toDouble()
          : 0.0;
      final cart = ps.paniers?.data.isNotEmpty == true ? ps.paniers!.data[0] : null;
      final itemCurrencyId = (cart?.cartItems.isNotEmpty == true) ? cart!.cartItems[0].currencyId : '';
      final cid = itemCurrencyId.isNotEmpty ? itemCurrencyId : (cart?.refCurrencyId ?? '');
      final result = await service.getCurrencyExchanges(amt, cid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Manual test: Success=${result.success}, Data=${result.data.length} items',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Manual test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildManualTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Manual Test',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Test the currency exchange API directly'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _testManualFetch,
              child: const Text('Run Manual Test'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'API Information',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Endpoint: /eblood-connect/amount-exchances'),
            const Text('Method: POST'),
            const Text('Body: {"amount": <double>, "ref_currency_id": "<currencyId>"}'),
            const SizedBox(height: 8),
            const Text(
              'If you see "No currency data available", check:\n'
              '• Backend has currency exchanges configured\n'
              '• User authentication is working\n'
              '• API endpoint is accessible\n'
              '• Entity has currencies configured',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawDataCard(currencyResponse) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.code, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Raw Data',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _showRawData,
                  onChanged: (value) {
                    setState(() {
                      _showRawData = value;
                    });
                  },
                ),
              ],
            ),
            if (_showRawData) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  'Success: ${currencyResponse.success}\n'
                  'Message: ${currencyResponse.message}\n'
                  'Data Length: ${currencyResponse.data.length}\n'
                  'Data: ${currencyResponse.data.toString()}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
