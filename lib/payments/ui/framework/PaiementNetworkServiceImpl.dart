import 'package:eblood_bank_mak_app/payments/business/models/PaiementModel.dart';
import 'package:eblood_bank_mak_app/payments/business/models/PaiementResponseModel.dart';
import 'package:eblood_bank_mak_app/payments/business/models/DatumPaiementModel.dart';
import 'package:eblood_bank_mak_app/payments/business/service/PaiementNetworkService.dart';
import 'package:eblood_bank_mak_app/payments/business/service/PaymentApi.dart';

/// Sprint 15 — server-side first leg of the payment flow.
///
/// Replaces the legacy POST /eblood-connect/cart/submit-payment call
/// (onafriq-shaped request body) with the gateway-agnostic
/// PaymentApi.initiate which talks to /api/v1/payments/initiate. The
/// SECOND leg (showing the lokotro_pay widget to actually collect the
/// funds) is launched from the UI in DetailCommandePage with
/// LokotroPayCheckoutService — kept separate because the checkout
/// widget needs a BuildContext.
///
/// The legacy PaiementResponseModel shape is preserved so the rest of
/// the app — including the navigation to PaymentStatusPage — can keep
/// using `result.data.systemRef` as the opaque payment identifier.
/// In the new world that string is the backend's `customer_reference`.
class PaiementServiceNetworkImpl implements PaiementNetworkService {
  // Kept for ABI compatibility with main.dart's bootstrap; not used
  // by the new dio_client-driven flow.
  String baseURL;

  PaiementServiceNetworkImpl(this.baseURL);

  @override
  Future<PaiementResponseModel?> ajouterPaiement(
    PaiementModel data,
    String authBearer,
  ) async {
    final result = await PaymentApi.initiate(
      purpose: 'delivery',
      entityId: data.cartId,
      amountCents: data.amountCents ?? 0,
      currency: data.currency ?? 'USD',
      description: _buildDescription(data),
    );

    if (!result.isSuccess || result.customerReference == null) {
      return PaiementResponseModel(
        data: null,
        sms: result.errorMessage ?? 'Échec de l\'initiation du paiement.',
        statusCode: 0,
        success: false,
      );
    }

    return PaiementResponseModel(
      data: DatumPaiementModel(
        // systemRef is now the customer_reference — the opaque token
        // used by both lokotro_pay's widget and the backend webhook.
        systemRef: result.customerReference!,
        bloodRequestId: data.cartId,
      ),
      sms: 'Payment intent created',
      statusCode: 201,
      success: true,
    );
  }

  String? _buildDescription(PaiementModel data) {
    final parts = <String>[];
    if (data.requestFor != null && data.requestFor!.isNotEmpty) {
      parts.add(data.requestFor!);
    }
    if (data.requestReason != null && data.requestReason!.isNotEmpty) {
      parts.add(data.requestReason!);
    }
    if (data.urgencyLevel != null && data.urgencyLevel!.isNotEmpty) {
      parts.add('urgence: ${data.urgencyLevel}');
    }
    return parts.isEmpty ? null : parts.join(' — ');
  }
}
