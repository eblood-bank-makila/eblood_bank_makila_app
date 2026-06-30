import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';

class BanquePageState {
  bool isLoading;
  List<BanqueModele> banques;

  BanquePageState({
    this.isLoading = false,
    this.banques = const [],
    //chargements
  });

  BanquePageState copyWith({bool? isLoading, List<BanqueModele>? banques}) =>
      BanquePageState(
          isLoading: isLoading ?? this.isLoading,
          banques: banques ?? this.banques);
}
