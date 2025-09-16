import '../../../model/banque/BanqueModele.dart';
import '../../../service/banque/BanqueListeLocalService.dart';

class SaveListeBanqueCodeUseCase {
  BanqueListeLocalService local;

  SaveListeBanqueCodeUseCase(this.local);

  Future<bool> run(List<BanqueModele> banques) async {
    var res = await local.saveListeBanque(banques);
    return res;
  }
}
