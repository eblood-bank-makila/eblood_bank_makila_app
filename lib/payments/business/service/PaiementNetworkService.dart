import 'package:eblood_bank_mak_app/payments/business/models/PaiementModel.dart';
import 'package:eblood_bank_mak_app/payments/business/models/PaiementResponseModel.dart';

abstract class PaiementNetworkService {
  Future<PaiementResponseModel?> ajouterPaiement(
      PaiementModel data, String authBearer);
}
