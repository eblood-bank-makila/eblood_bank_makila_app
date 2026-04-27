




import 'package:eblood_bank_mak_app/users/business/service/utilisateurNetworkService.dart';

class RenvoyerCodeUseCase{
  UtilisateurNetworkService network;
  RenvoyerCodeUseCase(this.network);

  Future<String> run(String token) async{
    var res=await network.renvoiCode(token);
    return res;
  }
}



