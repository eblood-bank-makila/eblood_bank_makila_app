import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../apps/config/utils/LocaleHelper.dart';


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
  bool _autoReception = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // Load saved settings (in a real app, these would come from persistent storage)
    _emailController.text = 'notification@eblood.com';
    _phoneController.text = '+243 970123456';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              '${_formatAmount(1250, signed: false)} USD',
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
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('confirm_withdrawal'.tr),
                      content: Text('confirm_withdrawal_message'.tr),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('cancel'.tr),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('withdrawal_initiated_successfully'.tr),
                                backgroundColor: Colors.green,
                              ),
                            );
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
    // Sample transaction data (localized)
    final now = DateTime.now();
    final transactions = [
      {
        'titleKey': 'payment_received',
        'subtitleKey': 'from',
        'party': 'Hôpital Central',
        'amount': 320.00,
        'date': DateTime(now.year, now.month, now.day, 14, 30),
        'icon': Iconsax.money_recive,
        'isPositive': true,
      },
      {
        'titleKey': 'withdrawal_made',
        'subtitleKey': 'to',
        'party': 'bank_account'.tr,
        'amount': -500.00,
        'date': DateTime(now.year, now.month, now.day - 1, 10, 15),
        'icon': Iconsax.money_send,
        'isPositive': false,
      },
      {
        'titleKey': 'payment_received',
        'subtitleKey': 'from',
        'party': 'Clinique Saint-Joseph',
        'amount': 180.00,
        'date': DateTime(now.year, now.month, 8, 16, 45),
        'icon': Iconsax.money_recive,
        'isPositive': true,
      },
      {
        'titleKey': 'payment_received',
        'subtitleKey': 'from',
        'party': 'Centre Médical Espoir',
        'amount': 420.00,
        'date': DateTime(now.year, now.month, 5, 9, 20),
        'icon': Iconsax.money_recive,
        'isPositive': true,
      },
      {
        'titleKey': 'withdrawal_made',
        'subtitleKey': 'to',
        'party': 'mobile_money'.tr,
        'amount': -300.00,
        'date': DateTime(now.year, now.month, 1, 11, 30),
        'icon': Iconsax.money_send,
        'isPositive': false,
      },
    ];

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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Save email settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('settings_saved'.tr),
                      backgroundColor: Colors.green,
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
                  'save'.tr,
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Save phone settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('phone_number_saved'.tr),
                      backgroundColor: Colors.green,
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
                  'save'.tr,
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
              onChanged: (value) {
                setState(() {
                  _autoReception = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'automatic_reception_enabled'.tr
                          : 'on_demand_reception_enabled'.tr
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              activeColor: Colors.green,
            ),
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