/// Enumeration for blood bag condition status.
enum BloodBagConditionStatus {
  excellent('excellent'),
  good('good'),
  fair('fair'),
  poor('poor'),
  none('none');

  final String value;
  const BloodBagConditionStatus(this.value);

  factory BloodBagConditionStatus.fromString(String value) {
    return BloodBagConditionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BloodBagConditionStatus.none,
    );
  }

  String get displayName {
    switch (this) {
      case BloodBagConditionStatus.excellent:
        return 'Excellent';
      case BloodBagConditionStatus.good:
        return 'Bon';
      case BloodBagConditionStatus.fair:
        return 'Moyen';
      case BloodBagConditionStatus.poor:
        return 'Mauvais';
      case BloodBagConditionStatus.none:
        return 'Non défini';
    }
  }
}

/// Enumeration for blood bag status.
enum BloodBagStatus {
  none('none'),
  available('available'),
  reserved('reserved'),
  used('used'),
  expired('expired'),
  badQuality('bad_quality'),
  quarantine('quarantine'),
  testingRequired('testing_required'),
  testedSafe('tested_safe');

  final String value;
  const BloodBagStatus(this.value);

  factory BloodBagStatus.fromString(String value) {
    return BloodBagStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BloodBagStatus.none,
    );
  }

  String get displayName {
    switch (this) {
      case BloodBagStatus.none:
        return 'Non défini';
      case BloodBagStatus.available:
        return 'Disponible';
      case BloodBagStatus.reserved:
        return 'Réservé';
      case BloodBagStatus.used:
        return 'Utilisé';
      case BloodBagStatus.expired:
        return 'Expiré';
      case BloodBagStatus.badQuality:
        return 'Mauvaise qualité';
      case BloodBagStatus.quarantine:
        return 'En quarantaine';
      case BloodBagStatus.testingRequired:
        return 'Test requis';
      case BloodBagStatus.testedSafe:
        return 'Testé & Sécurisé';
    }
  }
}

/// Enumeration for blood product type.
enum BloodProductType {
  // Core Blood Components
  wholeBlood('whole_blood'),
  plasma('plasma'),
  platelets('platelets'),
  redBloodCells('red_blood_cells'),
  
  // Plasma-Derived & Specialized Products
  cryoprecipitate('cryoprecipitate'),
  frozenPlasma('frozen_plasma'),
  freshFrozenPlasma('fresh_frozen_plasma'),
  plasmaLyophilizate('plasma_lyophilizate'),
  plasmaDerivedProducts('plasma_derived_products'),
  
  // Protein & Factor Concentrates
  albumin('albumin'),
  immunoglobulins('immunoglobulins'),
  factorConcentrates('factor_concentrates'),
  
  // Additive / Preservation Solutions
  saline('saline'),
  acdSolution('acd_solution'),
  cpdSolution('cpd_solution'),
  cpdaSolution('cpda_solution'),
  adsolSolution('adsol_solution'),
  sagmSolution('sagm_solution'),
  
  // Related Hematologic or Supportive Products
  epoetin('epoetin'),
  ironSupplements('iron_supplements'),
  granulocytes('granulocytes'),
  
  // Other / Miscellaneous
  none('none');

  final String value;
  const BloodProductType(this.value);

  factory BloodProductType.fromString(String value) {
    return BloodProductType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BloodProductType.none,
    );
  }

  String get displayName {
    switch (this) {
      case BloodProductType.wholeBlood:
        return 'Sang total';
      case BloodProductType.plasma:
        return 'Plasma';
      case BloodProductType.platelets:
        return 'Plaquettes';
      case BloodProductType.redBloodCells:
        return 'Globules rouges';
      case BloodProductType.cryoprecipitate:
        return 'Cryoprécipité';
      case BloodProductType.frozenPlasma:
        return 'Plasma congelé';
      case BloodProductType.freshFrozenPlasma:
        return 'Plasma frais congelé';
      case BloodProductType.plasmaLyophilizate:
        return 'Plasma lyophilisé';
      case BloodProductType.plasmaDerivedProducts:
        return 'Produits dérivés du plasma';
      case BloodProductType.albumin:
        return 'Albumine';
      case BloodProductType.immunoglobulins:
        return 'Immunoglobulines';
      case BloodProductType.factorConcentrates:
        return 'Concentrés de facteurs';
      case BloodProductType.saline:
        return 'Solution saline';
      case BloodProductType.acdSolution:
        return 'Solution ACD';
      case BloodProductType.cpdSolution:
        return 'Solution CPD';
      case BloodProductType.cpdaSolution:
        return 'Solution CPDA';
      case BloodProductType.adsolSolution:
        return 'Solution ADSOL';
      case BloodProductType.sagmSolution:
        return 'Solution SAGM';
      case BloodProductType.epoetin:
        return 'Époétine';
      case BloodProductType.ironSupplements:
        return 'Suppléments de fer';
      case BloodProductType.granulocytes:
        return 'Granulocytes';
      case BloodProductType.none:
        return 'Non défini';
    }
  }
}