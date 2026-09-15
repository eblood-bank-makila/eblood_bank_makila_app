import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/ewallet_models.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/payout_number_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/cash_out_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/data/services/ewallet_service.dart';

/// Immutable state for the per-profile e-wallet screen.
class EWalletState {
  final List<EWalletModel> wallets;
  final EWalletModel? selected;
  final List<EWalletHistoryModel> history;
  final List<PayoutNumberModel> payoutNumbers;
  final List<CashOutModel> cashOuts;
  final bool isLoading;
  final bool isLoadingNumbers;
  final bool isSubmitting;
  final String? error;

  const EWalletState({
    this.wallets = const [],
    this.selected,
    this.history = const [],
    this.payoutNumbers = const [],
    this.cashOuts = const [],
    this.isLoading = false,
    this.isLoadingNumbers = false,
    this.isSubmitting = false,
    this.error,
  });

  double get balance => selected?.ewalletAmount ?? (wallets.isNotEmpty ? wallets.first.ewalletAmount : 0.0);

  /// Payout numbers already validated by the MAIN profile — the only ones
  /// eligible as a withdrawal target.
  List<PayoutNumberModel> get validatedNumbers =>
      payoutNumbers.where((n) => n.isValidated).toList();

  /// Copy with the given overrides. `error` is sticky by default (kept as-is
  /// when omitted); pass `clearError: true` to reset it to null — a plain
  /// nullable `error` param can't distinguish "leave alone" from "clear".
  EWalletState copyWith({
    List<EWalletModel>? wallets,
    EWalletModel? selected,
    List<EWalletHistoryModel>? history,
    List<PayoutNumberModel>? payoutNumbers,
    List<CashOutModel>? cashOuts,
    bool? isLoading,
    bool? isLoadingNumbers,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return EWalletState(
      wallets: wallets ?? this.wallets,
      selected: selected ?? this.selected,
      history: history ?? this.history,
      payoutNumbers: payoutNumbers ?? this.payoutNumbers,
      cashOuts: cashOuts ?? this.cashOuts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingNumbers: isLoadingNumbers ?? this.isLoadingNumbers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final ewalletServiceProvider = Provider<EwalletService>((ref) => EwalletService());

class EWalletController extends StateNotifier<EWalletState> {
  final EwalletService _service;

  EWalletController(this._service) : super(const EWalletState());

  /// Load the caller's org wallets, select the first, then load its history.
  Future<void> loadWallets() async {
    state = EWalletState(
      wallets: state.wallets,
      selected: state.selected,
      history: state.history,
      isLoading: true,
      isSubmitting: state.isSubmitting,
      error: null,
    );
    try {
      final wallets = await _service.getMyWallets();
      final selected = wallets.isNotEmpty ? wallets.first : null;
      state = EWalletState(
        wallets: wallets,
        selected: selected,
        history: const [],
        isLoading: false,
        isSubmitting: false,
        error: null,
      );
      if (selected != null) {
        await loadHistory(selected.id);
      }
    } catch (e) {
      state = EWalletState(
        wallets: state.wallets,
        selected: state.selected,
        history: state.history,
        isLoading: false,
        isSubmitting: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadHistory(String walletId) async {
    try {
      final pageData = await _service.getHistory(opsEwalletId: walletId);
      state = EWalletState(
        wallets: state.wallets,
        selected: state.selected,
        history: pageData.items,
        isLoading: false,
        isSubmitting: state.isSubmitting,
        error: null,
      );
    } catch (e) {
      state = EWalletState(
        wallets: state.wallets,
        selected: state.selected,
        history: state.history,
        isLoading: false,
        isSubmitting: state.isSubmitting,
        error: e.toString(),
      );
    }
  }

  /// Submit a withdrawal against a validated payout number, for the selected
  /// wallet. Returns true on success and reloads the wallet (for its fresh
  /// balance) and the cash-outs list (so the new request shows up).
  Future<bool> withdraw({required double amount, required String payoutNumberId}) async {
    final wallet = state.selected;
    if (wallet == null) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final res = await _service.submitWithdrawal(
        opsEwalletId: wallet.id,
        amount: amount,
        payoutNumberId: payoutNumberId,
      );
      if (res.success) {
        state = state.copyWith(isSubmitting: false, clearError: true);
        await loadWallets();
        await loadCashOuts();
        return true;
      }
      state = state.copyWith(isSubmitting: false, error: res.message ?? 'Withdrawal failed');
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  // ──────────────────────────────────────────────────
  // Payout numbers (settlement escrow cash-out targets)
  // ──────────────────────────────────────────────────

  /// Load the caller's org payout numbers.
  Future<void> loadPayoutNumbers() async {
    state = state.copyWith(isLoadingNumbers: true, clearError: true);
    try {
      final numbers = await _service.getPayoutNumbers();
      state = state.copyWith(payoutNumbers: numbers, isLoadingNumbers: false);
    } catch (e) {
      state = state.copyWith(isLoadingNumbers: false, error: e.toString());
    }
  }

  /// Create (when [id] is null) or update an existing payout number, then
  /// reload the list. Returns true on success.
  Future<bool> savePayoutNumber({String? id, required Map<String, dynamic> payload}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final res = id == null
          ? await _service.createPayoutNumber(payload)
          : await _service.updatePayoutNumber(id, payload);
      if (res.success) {
        state = state.copyWith(isSubmitting: false, clearError: true);
        await loadPayoutNumbers();
        return true;
      }
      state = state.copyWith(isSubmitting: false, error: res.message ?? 'Failed to save payout number');
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Disable a payout number (PUT `validation_status: 'disabled'`), then
  /// reload the list. Returns true on success.
  Future<bool> disablePayoutNumber(String id) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final res = await _service.updatePayoutNumber(id, {'validation_status': 'disabled'});
      if (res.success) {
        state = state.copyWith(isSubmitting: false, clearError: true);
        await loadPayoutNumbers();
        return true;
      }
      state = state.copyWith(isSubmitting: false, error: res.message ?? 'Failed to disable payout number');
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Delete a payout number, then reload the list. Returns true on success.
  Future<bool> deletePayoutNumber(String id) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final res = await _service.deletePayoutNumber(id);
      if (res.success) {
        state = state.copyWith(isSubmitting: false, clearError: true);
        await loadPayoutNumbers();
        return true;
      }
      state = state.copyWith(isSubmitting: false, error: res.message ?? 'Failed to delete payout number');
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  // ──────────────────────────────────────────────────
  // Cash-outs (withdrawal / auto-checkout history)
  // ──────────────────────────────────────────────────

  /// Load cash-outs (withdrawal history) for the currently selected wallet.
  Future<void> loadCashOuts() async {
    final wallet = state.selected;
    if (wallet == null) return;
    try {
      final cashOuts = await _service.getCashOuts(walletId: wallet.id);
      state = state.copyWith(cashOuts: cashOuts);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update the settings (notification email / mobile-money phone / auto-reception)
  /// for the selected wallet. Only the non-null fields are sent so each settings
  /// section can save independently. Returns true on success.
  Future<bool> updateSettings({
    String? authEmail,
    String? authPhoneNumber,
    bool? autoCashOut,
  }) async {
    final wallet = state.selected;
    if (wallet == null) return false;
    state = EWalletState(
      wallets: state.wallets,
      selected: state.selected,
      history: state.history,
      isLoading: state.isLoading,
      isSubmitting: true,
      error: null,
    );
    try {
      final res = await _service.updateSettings(
        opsEwalletId: wallet.id,
        authEmail: authEmail,
        authPhoneNumber: authPhoneNumber,
        autoCashOut: autoCashOut,
      );
      state = EWalletState(
        wallets: state.wallets,
        selected: state.selected,
        history: state.history,
        isLoading: state.isLoading,
        isSubmitting: false,
        error: res.success ? null : (res.message ?? 'Update failed'),
      );
      if (res.success) {
        await loadWallets();
      }
      return res.success;
    } catch (e) {
      state = EWalletState(
        wallets: state.wallets,
        selected: state.selected,
        history: state.history,
        isLoading: state.isLoading,
        isSubmitting: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

final ewalletProvider = StateNotifierProvider<EWalletController, EWalletState>(
  (ref) => EWalletController(ref.watch(ewalletServiceProvider)),
);
