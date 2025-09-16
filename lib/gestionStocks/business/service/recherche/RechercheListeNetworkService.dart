import '../../model/recherche/DatumRecherchePocheModel.dart';

abstract class RechercheListeNetworkService {
  Future<List<DatumRecherchePocheModel>> recuperationRechercheListeBanque(String searchKey, String authBarear);


}
