import 'package:eblood_bank_mak_app/paiement/businness/models/PaiementModel.dart';
import 'package:eblood_bank_mak_app/paiement/businness/models/PaiementResponseModel.dart';

abstract class PaiementNetworkService {
  Future<PaiementResponseModel?> ajouterPaiement(
      PaiementModel data, String authBearer);
}
