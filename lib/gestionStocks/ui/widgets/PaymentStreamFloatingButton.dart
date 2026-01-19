import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';

/// Model for a payment transaction
class PaymentTransaction {
  final String id;
  final String identifier;
  final String status;
  final String statusDisplay;
  final double totalAmount;
  final double totalAmountMerged;
  final double fee;
  final String? phoneNumber;
  final String? onafriqTransactionRef;
  final String? bloodBankId;
  final Map<String, dynamic>? bloodBankInfo;
  final Map<String, dynamic>? currencyInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSuccessful;
  final bool isPending;
  final bool isFailed;

  PaymentTransaction({
    required this.id,
    required this.identifier,
    required this.status,
    required this.statusDisplay,
    required this.totalAmount,
    required this.totalAmountMerged,
    required this.fee,
    this.phoneNumber,
    this.onafriqTransactionRef,
    this.bloodBankId,
    this.bloodBankInfo,
    this.currencyInfo,
    this.createdAt,
    this.updatedAt,
    required this.isSuccessful,
    required this.isPending,
    required this.isFailed,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] ?? '',
      identifier: json['identifier'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      totalAmountMerged: (json['total_amount_merged'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      phoneNumber: json['phone_number'],
      onafriqTransactionRef: json['onafriq_transaction_ref'],
      bloodBankId: json['blood_bank_id'],
      bloodBankInfo: json['blood_bank_info'] != null
          ? Map<String, dynamic>.from(json['blood_bank_info'])
          : null,
      currencyInfo: json['currency_info'] != null
          ? Map<String, dynamic>.from(json['currency_info'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      isSuccessful: json['is_successful'] ?? false,
      isPending: json['is_pending'] ?? false,
      isFailed: json['is_failed'] ?? false,
    );
  }

  Color get statusColor {
    if (isSuccessful) return Colors.green;
    if (isPending) return Colors.orange;
    if (isFailed) return Colors.red;
    return Colors.grey;
  }

  IconData get statusIcon {
    if (isSuccessful) return Iconsax.tick_circle5;
    if (isPending) return Iconsax.clock5;
    if (isFailed) return Iconsax.close_circle5;
    return Iconsax.info_circle5;
  }

  String get currencySymbol => currencyInfo?['symbol'] ?? '\$';
  String get bloodBankName => bloodBankInfo?['name'] ?? 'Unknown';
}

/// Floating button that shows recent payment transactions
class PaymentStreamFloatingButton extends StatefulWidget {
  /// Whether the button should be visible
  final bool isVisible;

  /// Optional callback when a transaction is tapped
  final Function(PaymentTransaction)? onTransactionTap;

  const PaymentStreamFloatingButton({
    super.key,
    this.isVisible = true,
    this.onTransactionTap,
  });

  @override
  State<PaymentStreamFloatingButton> createState() =>
      _PaymentStreamFloatingButtonState();
}

class _PaymentStreamFloatingButtonState
    extends State<PaymentStreamFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _transactionCount = 0;
  bool _hasNewTransactions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    if (widget.isVisible) {
      _animationController.forward();
      _fetchTransactionCount();
    }
  }

  @override
  void didUpdateWidget(covariant PaymentStreamFloatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _animationController.forward();
      _fetchTransactionCount();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactionCount() async {
    try {
      final response = await getWithDio(
        '/eblood-connect/blood-bank-address-request/payment-stream?page=0&page_size=1',
      );

      if (response.success && response.data != null) {
        final total = response.data['pagination']?['total'] ?? 0;
        if (mounted) {
          setState(() {
            _transactionCount = total;
            _hasNewTransactions = total > 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching transaction count: $e');
    }
  }

  void _showPaymentStreamSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          PaymentStreamBottomSheet(onTransactionTap: widget.onTransactionTap),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton.extended(
        heroTag: 'payment_stream_fab',
        onPressed: _showPaymentStreamSheet,
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Iconsax.receipt_item, color: Colors.white),
            if (_hasNewTransactions)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _transactionCount > 99 ? '99+' : '$_transactionCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        label: Text(
          'transactions'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet displaying the list of payment transactions
class PaymentStreamBottomSheet extends StatefulWidget {
  final Function(PaymentTransaction)? onTransactionTap;

  const PaymentStreamBottomSheet({super.key, this.onTransactionTap});

  @override
  State<PaymentStreamBottomSheet> createState() =>
      _PaymentStreamBottomSheetState();
}

class _PaymentStreamBottomSheetState extends State<PaymentStreamBottomSheet> {
  List<PaymentTransaction> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMore = false;
  final ScrollController _scrollController = ScrollController();

  // Summary data
  int _totalTransactions = 0;
  int _successfulCount = 0;
  int _pendingCount = 0;
  int _failedCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchTransactions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _fetchTransactions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _transactions = [];
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await getWithDio(
        '/eblood-connect/blood-bank-address-request/payment-stream?page=$_currentPage&page_size=10',
      );

      if (response.success && response.data != null) {
        final transactionsList = response.data['transactions'] as List? ?? [];
        final pagination = response.data['pagination'] ?? {};
        final summary = response.data['summary'] ?? {};

        final newTransactions = transactionsList
            .map((json) => PaymentTransaction.fromJson(json))
            .toList();

        setState(() {
          if (refresh || _currentPage == 0) {
            _transactions = newTransactions;
          } else {
            _transactions.addAll(newTransactions);
          }
          _hasMore = pagination['has_more'] ?? false;
          _totalTransactions = summary['total_transactions'] ?? 0;
          _successfulCount = summary['successful_count'] ?? 0;
          _pendingCount = summary['pending_count'] ?? 0;
          _failedCount = summary['failed_count'] ?? 0;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load transactions';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _buildHeader(),

          // Summary cards
          if (!_isLoading && _error == null) _buildSummaryCards(),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.receipt_item,
              color: ColorPages.COLOR_PRINCIPAL,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'recent_transactions'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'address_payment_history'.tr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _fetchTransactions(refresh: true),
            icon: Icon(Iconsax.refresh, color: ColorPages.COLOR_PRINCIPAL),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildSummaryCard(
            'total'.tr,
            '$_totalTransactions',
            Colors.blue,
            Iconsax.receipt_2,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            'success'.tr,
            '$_successfulCount',
            Colors.green,
            Iconsax.tick_circle,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            'pending'.tr,
            '$_pendingCount',
            Colors.orange,
            Iconsax.clock,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            'failed'.tr,
            '$_failedCount',
            Colors.red,
            Iconsax.close_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _fetchTransactions(refresh: true),
              icon: const Icon(Iconsax.refresh),
              label: Text('retry'.tr),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.receipt_disscount, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'no_transactions'.tr,
              style: GoogleFonts.ubuntu(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'no_transactions_desc'.tr,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchTransactions(refresh: true),
      color: ColorPages.COLOR_PRINCIPAL,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _transactions.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _transactions.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _buildTransactionCard(_transactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionCard(PaymentTransaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: transaction.statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (widget.onTransactionTap != null) {
            widget.onTransactionTap!(transaction);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: transaction.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      transaction.statusIcon,
                      color: transaction.statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.identifier,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transaction.bloodBankName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: transaction.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.statusDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: Colors.grey[200], height: 1),
              const SizedBox(height: 12),

              // Amount and details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'amount'.tr,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      Text(
                        '${transaction.currencySymbol}${transaction.totalAmountMerged.toStringAsFixed(2)}',
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                    ],
                  ),
                  if (transaction.createdAt != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'date'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          _formatDate(transaction.createdAt!),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Phone number if available
              if (transaction.phoneNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Iconsax.call, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      transaction.phoneNumber!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday'.tr;
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${'days_ago'.tr}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
