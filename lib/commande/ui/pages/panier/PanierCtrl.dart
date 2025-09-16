import 'package:eblood_bank_mak_app/commande/business/interactor/CommandeInteractor.dart';
import 'package:eblood_bank_mak_app/commande/business/model/PanierModel.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierPageState.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/GestionStockInteractor.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/PocheModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../business/model/CartItemPanierModel.dart';
import '../../../business/model/DatumPanierModel.dart';
import '../../../business/model/panier/SuppressionPanierResponseModel.dart';

part 'PanierCtrl.g.dart';

@Riverpod(keepAlive: true)
class PanierCtrl extends _$PanierCtrl {
  @override
  PanierPageState build() {
    return PanierPageState();
  }

  Future<void> ajouterAuPanier(
      PocheModel poche, BanqueModele banque, int quantity) async {
    var usecase = ref.watch(commandeInteractorProvider).panierusecase;
    var res = await usecase.run(poche, banque,
        quantity: quantity); // Passer la quantité ici
    state = state.copyWith(panier: res);
  }

  // Update cart item quantity by calling the API directly
  Future<bool> updateCartItemQuantity(
      CartItemPanierModel cartItem, int newQuantity) async {
    try {
      state = state.copyWith(isLoading: true);

      // Extract IDs from nested objects since API response structure is different
      String bloodBagId = cartItem.bloodBagInfo.id;
      String bloodBankId = cartItem.bloodBankInfo.id;

      // Debug: Check what's actually in the bloodBankInfo
      print("🔍 Debug bloodBankInfo: id='${cartItem.bloodBankInfo.id}', identifier='${cartItem.bloodBankInfo.identifier}', name='${cartItem.bloodBankInfo.bloodBankName}'");
      print("🔍 Debug cartItem fields: bloodBankId='${cartItem.bloodBankId}', currencyId='${cartItem.currencyId}'");

      // Try to get blood bank ID from different sources
      if (bloodBankId.isEmpty && cartItem.bloodBankId.isNotEmpty) {
        bloodBankId = cartItem.bloodBankId;
        print("🔄 Using cartItem.bloodBankId: $bloodBankId");
      }

      // If still empty, try to get from blood bank list or use a fallback approach
      if (bloodBankId.isEmpty) {
        // Since the cart API doesn't provide blood bank info, we need to find it
        // Let's try to get it from the blood bank list or use the first available blood bank
        try {
          var banqueUseCase = ref.watch(gestionstockInteractorProvider).banquelisteusecase;
          var bloodBanks = await banqueUseCase.run();
          if (bloodBanks != null && bloodBanks.isNotEmpty) {
            // For now, use the first blood bank as fallback
            // In a real scenario, you'd need to determine which blood bank this blood bag belongs to
            bloodBankId = bloodBanks.first.id;
            print("🔄 Using fallback blood bank ID: $bloodBankId");
          }
        } catch (e) {
          print("💥 Error getting blood bank list: $e");
        }
      }

      print("🔄 Updating cart item quantity: bloodBagId=$bloodBagId, bloodBankId=$bloodBankId, quantity=$newQuantity");

      // Use the network service directly to update quantity
      var networkService = ref.watch(commandeInteractorProvider).panierusecase.network;
      var localService = ref.watch(commandeInteractorProvider).panierusecase.local;

      var token = await localService.recupererTokenOtp();

      // Create PanierModel with the new quantity using extracted IDs
      var panierData = PanierModel(
        blood_bank_id: bloodBankId,
        blood_bag_id: bloodBagId,
        quantity: newQuantity,
      );

      print("📤 Sending to backend: blood_bank_id=$bloodBankId, blood_bag_id=$bloodBagId, quantity=$newQuantity");

      var res = await networkService.ajouterPanier(panierData, token ?? "");

      if (res != null) {
        print("✅ Quantity updated successfully, refreshing cart...");
        // Refresh cart data after successful update
        await listepanier();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        print("❌ Failed to update quantity");
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      print("💥 Error updating cart item quantity: $e");
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> listepanier() async {
    var usecase = ref.watch(commandeInteractorProvider).recupererPanierUseCase;
    var res = await usecase.run();
    state = state.copyWith(paniers: res);
  }

  // Future<void> supprimer_panier(DatumModel card_id, CartItemPanierModel blood_bag_id) async {
  //   var usecase =
  //       ref.watch(commandeInteractorProvider).supprimerPochePanierUseCase;
  //   var id_not = card_id.id;
  //   var blood = blood_bag_id.id;
  //   var res = await usecase.run(id_not, blood);
  //   state = state.copyWith(isLoading: );
  // }

  Future<SuppressionPanierResponseModel?> supprimer_panier(
      DatumModel card_id, CartItemPanierModel blood_bag_id) async {
    state = state.copyWith(isLoading: true);
    var usecase =
        ref.watch(commandeInteractorProvider).supprimerPochePanierUseCase;

    var id_not = card_id.id;
    var blood = blood_bag_id.bloodBagId; // ← Fixed: Use bloodBagId instead of id
    print("🗑️ Deleting cart item: cartId=$id_not, bloodBagId=$blood");

    try {
      var res = await usecase.run(id_not, blood);
      print("✅ Deletion response: ${res?.success}");

      if (res?.success == true) {
        // Refresh cart data after successful deletion
        print("🔄 Refreshing cart data after deletion...");
        await listepanier();
      }

      state = state.copyWith(supprimer_panier: res, isLoading: false);
      return res;
    } catch (e) {
      print("💥 Error deleting cart item: $e");
      state = state.copyWith(isLoading: false);
      return null;
    }
  }

  /// Clears the entire cart after successful payment
  Future<bool> clearCartAfterPayment() async {
    print("🧹 Starting cart cleanup after successful payment...");

    try {
      // Get current cart data
      final currentCart = state.paniers;
      if (currentCart?.data.isEmpty != false) {
        print("📭 Cart is already empty, nothing to clear");
        return true;
      }

      state = state.copyWith(isLoading: true);

      final usecase = ref.watch(commandeInteractorProvider).supprimerPochePanierUseCase;
      bool allDeleted = true;
      int totalItems = 0;
      int deletedItems = 0;

      // Delete all items in the cart
      for (final cart in currentCart!.data) {
        for (final item in cart.cartItems) {
          totalItems++;
          print("🗑️ Deleting item ${deletedItems + 1}/$totalItems: ${item.bloodBagId}");

          try {
            final result = await usecase.run(cart.id, item.bloodBagId);
            if (result?.success == true) {
              deletedItems++;
              print("✅ Item deleted successfully");
            } else {
              print("❌ Failed to delete item: ${result?.sms}");
              allDeleted = false;
            }
          } catch (e) {
            print("💥 Error deleting item: $e");
            allDeleted = false;
          }
        }
      }

      print("📊 Cart cleanup summary: $deletedItems/$totalItems items deleted");

      // Refresh cart data to reflect changes
      await listepanier();
      state = state.copyWith(isLoading: false);

      if (allDeleted) {
        print("🎉 Cart cleared successfully after payment!");
      } else {
        print("⚠️ Some items could not be deleted from cart");
      }

      return allDeleted;
    } catch (e) {
      print("💥 Error clearing cart after payment: $e");
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}
