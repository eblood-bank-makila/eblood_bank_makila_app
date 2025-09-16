
import '../../../business/model/recherche/DatumRecherchePocheModel.dart';

class RecherchePageState {
  bool isLoading;
  List<DatumRecherchePocheModel> recherche;

  RecherchePageState({
    this.isLoading = false,
    this.recherche= const [],
    //chargements
  });

  RecherchePageState copyWith({bool? isLoading, List<DatumRecherchePocheModel>? recherche}) =>
      RecherchePageState(
          isLoading: isLoading ?? this.isLoading,
          recherche: recherche ?? this.recherche);
}
