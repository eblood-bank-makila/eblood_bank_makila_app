import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
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

  /// Copy with the given overrides. `error` and `selected` are sticky by
  /// default (kept as-is when omitted); pass `clearError: true` /
  /// `clearSelected: true` to reset either to null — a plain nullable param
  /// can't distinguish "leave alone" from "clear" on its own.
  EWalletState copyWith({
    List<EWalletModel>? wallets,
    EWalletModel? selected,
    bool clearSelected = false,
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
      selected: clearSelected ? null : (selected ?? this.selected),
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
  /// Built via `copyWith` (not the old positional constructor) so that
  /// `payoutNumbers`/`cashOuts`/`isLoadingNumbers` — populated independently,
  /// e.g. from a payout-numbers settings screen — survive this routine
  /// reload instead of silently resetting to their defaults.
  Future<void> loadWallets() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final wallets = await _service.getMyWallets();
      final selected = wallets.isNotEmpty ? wallets.first : null;
      state = state.copyWith(
        wallets: wallets,
        selected: selected,
        clearSelected: selected == null,
        history: const [],
        isLoading: false,
        isSubmitting: false,
        clearError: true,
      );
      if (selected != null) {
        await loadHistory(selected.id);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, isSubmitting: false, error: e.toString());
    }
  }

  Future<void> loadHistory(String walletId) async {
    try {
      final pageData = await _service.getHistory(opsEwalletId: walletId);
      state = state.copyWith(history: pageData.items, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Runs one submit-style action: flips `isSubmitting`, calls [call], then
  /// either clears the error and runs [onSuccess] or records
  /// `res.message ?? defaultError`. Centralizes the isSubmitting/error
  /// bookkeeping that `savePayoutNumber`, `disablePayoutNumber`,
  /// `deletePayoutNumber`, `withdraw` and `updateSettings` all repeated
  /// verbatim — behaviour is unchanged from the inlined versions.
  Future<bool> _runAction(
    Future<IApiResponse> Function() call, {
    required String defaultError,
    Future<void> Function()? onSuccess,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final res = await call();
      if (res.success) {
        state = state.copyWith(isSubmitting: false, clearError: true);
        if (onSuccess != null) await onSuccess();
        return true;
      }
      state = state.copyWith(
        isSubmitting: false,
        error: (res.message?.isNotEmpty == true) ? res.message! : defaultError,
      );
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Submit a withdrawal against a validated payout number, for the selected
  /// wallet. Returns true on success and reloads the wallet (for its fresh
  /// balance) and the cash-outs list (so the new request shows up).
  Future<bool> withdraw({required double amount, required String payoutNumberId}) {
    final wallet = state.selected;
    if (wallet == null) return Future.value(false);
    return _runAction(
      () => _service.submitWithdrawal(opsEwalletId: wallet.id, amount: amount, payoutNumberId: payoutNumberId),
      defaultError: 'Withdrawal failed',
      onSuccess: () async {
        await loadWallets();
        await loadCashOuts();
      },
    );
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
  Future<bool> savePayoutNumber({String? id, required Map<String, dynamic> payload}) => _runAction(
        () => id == null ? _service.createPayoutNumber(payload) : _service.updatePayoutNumber(id, payload),
        defaultError: 'Failed to save payout number',
        onSuccess: loadPayoutNumbers,
      );

  /// Disable a payout number (PUT `validation_status: 'disabled'`), then
  /// reload the list. Returns true on success.
  Future<bool> disablePayoutNumber(String id) => _runAction(
        () => _service.updatePayoutNumber(id, {'validation_status': 'disabled'}),
        defaultError: 'Failed to disable payout number',
        onSuccess: loadPayoutNumbers,
      );

  /// Delete a payout number, then reload the list. Returns true on success.
  Future<bool> deletePayoutNumber(String id) => _runAction(
        () => _service.deletePayoutNumber(id),
        defaultError: 'Failed to delete payout number',
        onSuccess: loadPayoutNumbers,
      );

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
  /// section can save independently. Returns true on success. Built via
  /// `copyWith` (through `_runAction`) so `payoutNumbers`/`cashOuts` survive
  /// this reload too — same flags and error handling as before.
  Future<bool> updateSettings({
    String? authEmail,
    String? authPhoneNumber,
    bool? autoCashOut,
  }) {
    final wallet = state.selected;
    if (wallet == null) return Future.value(false);
    return _runAction(
      () => _service.updateSettings(
        opsEwalletId: wallet.id,
        authEmail: authEmail,
        authPhoneNumber: authPhoneNumber,
        autoCashOut: autoCashOut,
      ),
      defaultError: 'Update failed',
      onSuccess: loadWallets,
    );
  }
}

final ewalletProvider = StateNotifierProvider<EWalletController, EWalletState>(
  (ref) => EWalletController(ref.watch(ewalletServiceProvider)),
);
