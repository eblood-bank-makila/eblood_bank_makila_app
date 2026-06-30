import 'package:eblood_bank_mak_app/users/business/models/OtpCodeModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/code_otp/DatumCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurNetworkService.dart';

class RecuperationUtilisateurNetworkCodeUseCase{
  UtilisateurNetworkService network;
  UtilisateurLocalService local;


  RecuperationUtilisateurNetworkCodeUseCase(this.network,this.local);



  Future<DatumCodeOtpModele?> run() async{
    var token=await local.recupererTokenOtp();
    var res=await network.recuperationUtilisateurOtp(token?? "");
    if(res != null){
      var user=DatumCodeOtpModele.fromJson(res.toJson());
      local.saveUserOtp(user);
    }
    return res;
  }
}