import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import '../../../apps/config/utils/LocaleHelper.dart';
import '../../../core/rbac/services/rbac_guard.dart';
import '../../providers/ewallet_provider.dart';
import '../../business/models/ewallet_models.dart';


class WalletManagementPage extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const WalletManagementPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<WalletManagementPage> createState() => _WalletManagementPageState();
}

class _WalletManagementPageState extends ConsumerState<WalletManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _formatAmount(num amount, {bool signed = false}) {
    final locale = Get.locale?.toString() ?? 'en_US';
    final fmt = LocaleHelper.createNumberFormat(locale: locale, symbol: '', decimalDigits: 2);
    final positive = fmt.format(amount.abs());
    if (!signed) return fmt.format(amount);
    return amount >= 0 ? '+$positive' : '-$positive';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final locale = Get.locale?.toString() ?? 'en_US';
    final safeLocale = LocaleHelper.getSafeLocale(locale);
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dt.year, dt.month, dt.day);
    final time = LocaleHelper.formatDate(dt, 'HH:mm', safeLocale);
    if (dateOnly == today) {
      return '${'today'.tr}, $time';
    }
    if (dateOnly == today.subtract(const Duration(days: 1))) {
      return '${'yesterday'.tr}, $time';
    }
    final datePart = LocaleHelper.formatDate(dt, 'dd MMM', safeLocale);
    return '$datePart, $time';
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _withdrawalPhoneController = TextEditingController();
  final TextEditingController _withdrawAmountController = TextEditingController();
  bool _autoReception = false;
  // Tracks which wallet's settings have been loaded into the fields, so we hydrate
  // the email/phone/toggle once when the wallet arrives without clobbering edits on
  // every provider rebuild.
  String? _settingsHydratedForWalletId;

  @override
  void initState() {
    super.initState();
    // Shared wallet screen (blood bank + CNTS). Visibility is already gated by the RBAC
    // nav + screen registry, so guard on the shared home app flag (both profiles have it)
    // rather than the blood-bank-only wallet flag — otherwise CNTS users get redirected.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_home_app',
    );
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // Settings fields are hydrated from the loaded wallet (see _hydrateSettingsFromWallet),
    // not hardcoded — so they reflect what is actually persisted on the backend.

    // Load the authenticated org's wallet(s) + history once the first frame is scheduled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(ewalletProvider.notifier).loadWallets();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _withdrawalPhoneController.dispose();
    _withdrawAmountController.dispose();
    super.dispose();
  }

  /// Populate the settings fields from the loaded wallet once (per wallet id), so the
  /// email / phone / auto-reception controls reflect the persisted backend values and
  /// don't get clobbered on every provider rebuild.
  void _hydrateSettingsFromWallet(EWalletModel? wallet) {
    if (wallet == null || wallet.id == _settingsHydratedForWalletId) return;
    _settingsHydratedForWalletId = wallet.id;
    // Show the most recent submitted value while a change is pending/rejected, otherwise
    // the validated value that is actually live on the wallet.
    String fieldValue(EWalletSettingStatus s, String validated) =>
        (s.isPending || s.isRejected) && s.pendingValue != null ? s.pendingValue! : validated;
    _emailController.text = fieldValue(wallet.emailStatus, wallet.authEmail);
    _phoneController.text = fieldValue(wallet.phoneStatus, wallet.authPhoneNumber);
    _withdrawalPhoneController.text = fieldValue(wallet.withdrawalPhoneStatus, wallet.withdrawalPhoneNumber);
    final aco = wallet.autoCashOutStatus;
    final autoVal = (aco.isPending || aco.isRejected) && aco.pendingValue != null
        ? aco.pendingValue == 'true'
        : wallet.autoCashOut;
    if (mounted) {
      setState(() => _autoReception = autoVal);
    } else {
      _autoReception = autoVal;
    }
  }

  /// A small status pill for a setting's validation state (pending / rejected / validated).
  Widget _settingStatusBadge(EWalletSettingStatus s) {
    if (s.isNotSet) return const SizedBox.shrink();
    late final Color color;
    late final IconData icon;
    late final String label;
    if (s.isPending) {
      color = Colors.orange;
      icon = Iconsax.clock;
      label = 'status_pending_validation'.tr;
    } else if (s.isRejected) {
      color = Colors.red;
      icon = Iconsax.close_circle;
      label = 'status_rejected'.tr;
    } else {
      color = Colors.green;
      icon = Iconsax.tick_circle;
      label = 'status_validated'.tr;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.ubuntu(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
        if (s.isRejected && (s.rejectionReason?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${'rejection_reason'.tr}: ${s.rejectionReason}',
              style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // React to wallet load/changes to hydrate the settings tab from persisted values.
    ref.listen<EWalletState>(ewalletProvider, (previous, next) {
      _hydrateSettingsFromWallet(next.selected);
    });
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Tab Navigation
            _buildTabNavigation(),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWalletTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'financial_management'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'wallet_and_settings'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.wallet,
                color: Colors.green,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              icon: const Icon(Iconsax.wallet, size: 20),
              text: 'wallet'.tr,
            ),
            Tab(
              icon: const Icon(Iconsax.setting_2, size: 20),
              text: 'settings'.tr,
            ),
          ],
        ),
      ),
    );
  }

  // WALLET TAB
  Widget _buildWalletTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Credit card style wallet
          _buildWalletCard(),
          const SizedBox(height: 24),

          // Withdraw action
          _buildWithdrawSection(),
          const SizedBox(height: 24),

          // Transaction history
          _buildTransactionHistory(),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    final walletState = ref.watch(ewalletProvider);
    final selected = walletState.selected;
    final currency = selected == null
        ? 'USD'
        : (selected.currencySymbol.isNotEmpty
            ? selected.currencySymbol
            : (selected.currencyCode.isNotEmpty ? selected.currencyCode : 'USD'));
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'e_blood_wallet'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Icon(
                  Iconsax.card,
                  color: Colors.white,
                  size: 30,
                ),
              ],
            ),
            const Spacer(),
            Text(
              'available_balance'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatAmount(walletState.balance, signed: false)} $currency',
              style: GoogleFonts.ubuntu(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'blood_bank_makila'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  'verified'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'make_withdrawal'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _withdrawAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'amount'.tr,
                prefixText: 'USD ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Capture the messenger from the *page* context up-front. The dialog
                  // builder below shadows `context` with its own (dialog) context, which is
                  // torn down the instant Navigator.pop runs — reusing it for the post-await
                  // snackbar silently dropped every success/error toast.
                  final messenger = ScaffoldMessenger.of(context);
                  final walletState = ref.read(ewalletProvider);
                  final amt = double.tryParse(
                        _withdrawAmountController.text.trim().replaceAll(',', '.'),
                      ) ??
                      0;
                  // Validate everything BEFORE opening the confirm dialog so a withdrawal that
                  // cannot possibly succeed (invalid amount, no wallet, or more than the
                  // available balance) never gets sent to the backend.
                  if (amt <= 0) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('enter_valid_amount'.tr),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }
                  if (walletState.selected == null) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('no_wallet_available'.tr),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }
                  if (amt > walletState.balance) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('insufficient_balance'.tr),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text('confirm_withdrawal'.tr),
                      content: Text('confirm_withdrawal_message'.tr),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text('cancel'.tr),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            final ok = await ref
                                .read(ewalletProvider.notifier)
                                .withdraw(amount: amt);
                            // `mounted` here is the page State's — still mounted after the
                            // dialog pops — so it is safe to read the provider and show the
                            // toast via the captured (page) messenger.
                            if (!mounted) return;
                            final err = ref.read(ewalletProvider).error;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'withdrawal_initiated_successfully'.tr
                                    : ((err != null && err.isNotEmpty)
                                        ? err
                                        : 'withdrawal_failed'.tr)),
                                backgroundColor: ok ? Colors.green : Colors.red,
                              ),
                            );
                            if (ok) _withdrawAmountController.clear();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('confirm'.tr),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'withdraw'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    // Real transactions from the per-profile e-wallet provider (mapped to the
    // tile shape the renderer below already expects). `.tr` on a non-key label is a no-op.
    final walletState = ref.watch(ewalletProvider);
    final transactions = walletState.history
        .map((tx) => <String, dynamic>{
              'titleKey': tx.title,
              'subtitleKey': 'from',
              'party': tx.userName ?? '',
              'amount': tx.isCredit ? tx.amount : -tx.amount,
              'date': tx.createdAt ?? DateTime.now(),
              'icon': tx.icon,
              'isPositive': tx.isCredit,
            })
        .toList();

    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'transaction_history'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final isPositive = transaction['isPositive'] as bool;

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      transaction['icon'] as IconData,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    (transaction['titleKey'] as String).tr,
                    style: GoogleFonts.ubuntu(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    "${(transaction['subtitleKey'] as String).tr}: ${transaction['party']}",
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                    ),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${_formatAmount(transaction['amount'] as num, signed: true)} USD",
                        style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w700,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        _formatDate(transaction['date'] as DateTime),
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // SETTINGS TAB
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification settings
          _buildEmailNotificationSection(),
          const SizedBox(height: 24),

          // Mobile payment settings
          _buildMobilePaymentSection(),
          const SizedBox(height: 24),

          // Withdrawal payout phone
          _buildWithdrawalPhoneSection(),
          const SizedBox(height: 24),

          // Auto reception settings
          _buildAutoReceptionSection(),
        ],
      ),
    );
  }

  Widget _buildEmailNotificationSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.notification, color: Colors.green),
                const SizedBox(width: 10),
                Text(
                  'email_notifications'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'email_for_transaction_notifications'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'email_address'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            if (!(ref.watch(ewalletProvider).selected?.emailStatus.isNotSet ?? true)) ...[
              const SizedBox(height: 12),
              _settingStatusBadge(ref.watch(ewalletProvider).selected?.emailStatus ?? const EWalletSettingStatus()),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final email = _emailController.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('enter_valid_email'.tr),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }
                  if (ref.read(ewalletProvider).selected == null) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('no_wallet_available'.tr),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }
                  final ok = await ref
                      .read(ewalletProvider.notifier)
                      .updateSettings(authEmail: email);
                  if (!mounted) return;
                  final err = ref.read(ewalletProvider).error;
                  messenger.showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'settings_submitted_for_validation'.tr
                        : ((err != null && err.isNotEmpty)
                            ? err
                            : 'settings_save_failed'.tr)),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'submit_for_validation'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePaymentSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.mobile, color: Colors.green),
                const SizedBox(width: 10),
                Text(
                  'mobile_payment'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'phone_number_for_mobile_payments'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'phone_number'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            if (!(ref.watch(ewalletProvider).selected?.phoneStatus.isNotSet ?? true)) ...[
              const SizedBox(height: 12),
              _settingStatusBadge(ref.watch(ewalletProvider).selected?.phoneStatus ?? const EWalletSettingStatus()),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final phone = _phoneController.text.trim();
                  if (phone.isEmpty) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('enter_valid_phone'.tr),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }
                  if (ref.read(ewalletProvider).selected == null) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('no_wallet_available'.tr),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }
                  final ok = await ref
                      .read(ewalletProvider.notifier)
                      .updateSettings(authPhoneNumber: phone);
                  if (!mounted) return;
                  final err = ref.read(ewalletProvider).error;
                  messenger.showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'settings_submitted_for_validation'.tr
                        : ((err != null && err.isNotEmpty)
                            ? err
                            : 'settings_save_failed'.tr)),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'submit_for_validation'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalPhoneSection() {
    final status = ref.watch(ewalletProvider).selected?.withdrawalPhoneStatus ?? const EWalletSettingStatus();
    return FadeInUp(
      delay: const Duration(milliseconds: 550),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.money_send, color: Colors.green),
                const SizedBox(width: 10),
                Text(
                  'withdrawal_phone'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'withdrawal_phone_description'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _withdrawalPhoneController,
              decoration: InputDecoration(
                labelText: 'phone_number'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            if (!status.isNotSet) ...[
              const SizedBox(height: 12),
              _settingStatusBadge(status),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final phone = _withdrawalPhoneController.text.trim();
                  if (phone.isEmpty) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('enter_valid_phone'.tr),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }
                  if (ref.read(ewalletProvider).selected == null) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('no_wallet_available'.tr),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }
                  final ok = await ref
                      .read(ewalletProvider.notifier)
                      .updateSettings(withdrawalPhoneNumber: phone);
                  if (!mounted) return;
                  final err = ref.read(ewalletProvider).error;
                  messenger.showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'settings_submitted_for_validation'.tr
                        : ((err != null && err.isNotEmpty)
                            ? err
                            : 'settings_save_failed'.tr)),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'submit_for_validation'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoReceptionSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.setting, color: Colors.green),
                const SizedBox(width: 10),
                Text(
                  'reception_mode'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'configure_payment_reception_mode'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'automatic_reception'.tr,
                style: GoogleFonts.ubuntu(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'accept_incoming_payments_automatically'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              value: _autoReception,
              onChanged: (value) async {
                final messenger = ScaffoldMessenger.of(context);
                if (ref.read(ewalletProvider).selected == null) {
                  messenger.showSnackBar(SnackBar(
                    content: Text('no_wallet_available'.tr),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                // Flip optimistically, then revert if the backend rejects the change.
                setState(() => _autoReception = value);
                final ok = await ref
                    .read(ewalletProvider.notifier)
                    .updateSettings(autoCashOut: value);
                if (!mounted) return;
                if (!ok) {
                  setState(() => _autoReception = !value);
                  final err = ref.read(ewalletProvider).error;
                  messenger.showSnackBar(SnackBar(
                    content: Text((err != null && err.isNotEmpty)
                        ? err
                        : 'settings_save_failed'.tr),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                messenger.showSnackBar(SnackBar(
                  content: Text('settings_submitted_for_validation'.tr),
                  backgroundColor: Colors.green,
                ));
              },
              activeColor: Colors.green,
            ),
            if (!(ref.watch(ewalletProvider).selected?.autoCashOutStatus.isNotSet ?? true)) ...[
              const SizedBox(height: 12),
              _settingStatusBadge(ref.watch(ewalletProvider).selected?.autoCashOutStatus ?? const EWalletSettingStatus()),
            ],
            if (!_autoReception) ...[
              const SizedBox(height: 16),
              Text(
                'manual_approval_notification_message'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}