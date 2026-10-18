import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';

class BanquePageState {
  bool isLoading;
  List<BanqueModele> banques;

  /// The phone's position is unknown, so no nearby search was made: the page
  /// asks for the location instead of claiming there is no bank.
  bool locationUnavailable;

  BanquePageState({
    this.isLoading = false,
    this.banques = const [],
    this.locationUnavailable = false,
    //chargements
  });

  BanquePageState copyWith({bool? isLoading, List<BanqueModele>? banques, bool? locationUnavailable}) =>
      BanquePageState(
          isLoading: isLoading ?? this.isLoading,
          banques: banques ?? this.banques,
          locationUnavailable: locationUnavailable ?? this.locationUnavailable);
}
