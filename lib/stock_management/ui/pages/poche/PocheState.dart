import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/poche/PocheModel.dart';

class PocheState {
  bool isLoading;
  List<PocheModel> poches;
  BanqueModele? banque;

  PocheState({this.isLoading = false, this.poches = const [], this.banque
      //chargement
      });

  PocheState copyWith(
          {bool? isLoading, List<PocheModel>? poches, BanqueModele? banque}) =>
      PocheState(
          isLoading: isLoading ?? this.isLoading,
          poches: poches ?? this.poches,
          banque: banque ?? this.banque);
}
