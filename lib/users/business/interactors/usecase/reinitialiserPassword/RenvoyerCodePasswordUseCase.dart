




import 'package:eblood_bank_mak_app/users/business/service/utilisateurNetworkService.dart';

class RenvoyerCodePasswordUseCase{
  UtilisateurNetworkService network;
  RenvoyerCodePasswordUseCase(this.network);

  Future<String> run(String token) async{
    var res=await network.renvoiCodePassword(token);
    return res;
  }
}



