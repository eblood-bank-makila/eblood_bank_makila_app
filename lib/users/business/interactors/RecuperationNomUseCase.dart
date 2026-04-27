import 'package:eblood_bank_mak_app/users/business/service/utilisateurNetworkService.dart';

class RecuperationNomUseCase{
  UtilisateurNetworkService network;
  RecuperationNomUseCase(this.network);

  Future<List<String>> run(String name) async{
    var res= await network.recuperationNomUtilisateur(name);
    return res;
  }
}