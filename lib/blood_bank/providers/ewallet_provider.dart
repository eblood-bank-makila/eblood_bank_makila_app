import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/ewallet_models.dart';
import 'package:eblood_bank_mak_app/blood_bank/data/services/ewallet_service.dart';

/// Immutable state for the per-profile e-wallet screen.
class EWalletState {
  final List<EWalletModel> wallets;
  final EWalletModel? selected;
  final List<EWalletHistoryModel> history;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const EWalletState({
    this.wallets = const [],
    this.selected,
    this.history = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  double get balance => selected?.ewalletAmount ?? (wallets.isNotEmpty ? wallets.first.ewalletAmount : 0.0);
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

  /// Submit a withdrawal for the selected wallet. Returns true on success.
  Future<bool> withdraw({required double amount, String? phoneNumber}) async {
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
      final res = await _service.submitWithdrawal(opsEwalletId: wallet.id, amount: amount, phoneNumber: phoneNumber);
      state = EWalletState(
        wallets: state.wallets,
        selected: state.selected,
        history: state.history,
        isLoading: state.isLoading,
        isSubmitting: false,
        error: res.success ? null : (res.message ?? 'Withdrawal failed'),
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

  /// Update the settings (notification email / mobile-money phone / auto-reception)
  /// for the selected wallet. Only the non-null fields are sent so each settings
  /// section can save independently. Returns true on success.
  Future<bool> updateSettings({
    String? authEmail,
    String? authPhoneNumber,
    bool? autoCashOut,
    String? withdrawalPhoneNumber,
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
        withdrawalPhoneNumber: withdrawalPhoneNumber,
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
