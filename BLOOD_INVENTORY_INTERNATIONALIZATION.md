# Blood Inventory Page Internationalization

## Overview

This document outlines the internationalization (i18n) implementation for the BloodBankInventoryPage and its children.

---

## ✅ Completed

### 1. Translation Keys Added to AppTranslations.dart

Added comprehensive translation keys for:

#### Blood Components
- `whole_blood`: 'Sang Complet'
- `red_cells`: 'Globules Rouges'
- `plasma`: 'Plasma'
- `platelets`: 'Plaquettes'

#### Page Structure
- `inventory_management`: 'Gestion d\'Inventaire'
- `blood_bank_makila`: 'Banque de Sang Makila'
- `overview`: 'Vue d\'ensemble'
- `blood_stock`: 'Stock de Sang'
- `reports`: 'Rapports'
- `parameters`: 'Paramètres'

#### Statistics
- `quick_statistics`: 'Statistiques Rapides'
- `total_stock`: 'Stock Total'
- `critical_stock`: 'Stock Critique'
- `expiring_soon`: 'Expiration Proche'
- `units`: 'unités'
- `pending`: 'en attente'
- `blood_types`: 'types de sang'
- `in_7_days`: 'dans 7 jours'

#### Blood Distribution
- `blood_type_distribution`: 'Distribution par Type de Sang'
- `no_stock_available`: 'Aucun stock disponible'
- `blood_group`: 'Groupe'
- `critical`: 'Critique'
- `hide_details`: 'Masquer les détails'

#### Recent Activity
- `recent_activity`: 'Activité Récente'
- `stock_added`: 'Stock ajouté'
- `request_approved`: 'Demande approuvée'
- `critical_stock_alert`: 'Stock critique'
- `units_added`: 'unités ajoutées'
- `units_remaining`: 'unités restantes'
- `only`: 'Seulement'
- `just_now`: 'À l\'instant'
- `minutes_ago`: 'Il y a @minutes min'
- `hours_ago`: 'Il y a @hoursh'
- `yesterday`: 'Hier'
- `days_ago`: 'Il y a @days jours'

#### Blood Stock Tab
- `search_stock`: 'Rechercher du stock...'
- `add_stock`: 'Ajouter Stock'
- `no_stock_to_display`: 'Aucun stock disponible'
- `add_stock_to_start`: 'Ajoutez du stock pour commencer'
- `available`: 'disponibles'
- `critical_types`: 'Types Critiques'
- `less_than_10_units`: '< 10 unités'
- `expiration_near`: 'Expiration Proche'
- `less_than_7_days`: '< 7 jours'
- `quality`: 'Qualité'
- `expired`: 'Expiré'
- `days_remaining`: 'J-@days'
- `collection_date`: 'Date de collecte'
- `expiration_date`: 'Date d\'expiration'
- `batch_number`: 'Numéro de lot'

#### Reports Tab
- `inventory_reports`: 'Rapports d\'Inventaire'
- `inventory_analysis`: 'Analyse de votre inventaire et des tendances'
- `last_30_days`: 'Dernier 30 jours'
- `loading_error`: 'Erreur de chargement'
- `loading_data_error`: 'Erreur de chargement des données: @error'
- `blood_collected`: 'Sang Collecté'
- `blood_distributed`: 'Sang Distribué'
- `daily_average`: 'Moyenne Journalière'
- `evolution`: 'Évolution'
- `units_this_month`: 'unités ce mois'
- `units_per_day`: 'unités/jour'
- `vs_last_month`: 'vs mois dernier'

#### Trends
- `inventory_trend`: 'Tendance de l\'Inventaire'
- `blood_units_per`: 'Unités de sang par @period'
- `collected`: 'Collecté'
- `distributed`: 'Distribué'
- `no_trend_data`: 'Aucune donnée de tendance disponible pour cette période'
- `day`: 'jour'
- `week`: 'semaine'
- `month`: 'mois'
- `quarter`: 'trimestre'
- `year`: 'année'
- `period`: 'période'

#### Monthly Comparison
- `monthly_comparison`: 'Comparaison Mensuelle'

#### Export Reports
- `export_reports`: 'Exporter les Rapports'
- `inventory_report`: 'Rapport d\'Inventaire'
- `current_stock_status`: 'État actuel du stock par groupe sanguin'
- `transaction_report`: 'Rapport des Transactions'
- `stock_entries_exits`: 'Entrées et sorties de stock ce mois'
- `expiration_report`: 'Rapport d\'Expiration'
- `expiring_stock`: 'Stock arrivant à expiration prochainement'
- `export`: 'Exporter'

#### Settings Tab
- `inventory_settings`: 'Paramètres d\'Inventaire'
- `configure_stock_management`: 'Configurez les paramètres de gestion de stock'
- `last_updated`: 'Dernière mise à jour: @time'
- `unable_to_load_settings`: 'Impossible de charger les paramètres.'

#### Product Pricing
- `blood_product_pricing`: 'Prix des Produits Sanguins'
- `edit_price`: 'Modifier le prix de @product'
- `price_currency`: 'Prix (@currency)'
- `price_updated`: 'Prix mis à jour pour @product'
- `price_update_error`: 'Erreur lors de la mise à jour du prix'

#### Critical Stock Thresholds
- `critical_stock_thresholds`: 'Seuils de Stock Critique'
- `critical_threshold`: 'Seuil critique'
- `edit_threshold`: 'Modifier le seuil critique @bloodType'
- `threshold_units`: 'Seuil (unités)'
- `threshold_updated`: 'Seuil mis à jour pour @bloodType'
- `threshold_update_error`: 'Erreur lors de la mise à jour du seuil'
- `configure_all_blood_types`: 'Configurer tous les types sanguins'
- `detailed_threshold_config_coming`: 'Configuration détaillée des seuils à venir'

#### Expiration Settings
- `expiration_settings`: 'Paramètres d\'Expiration'
- `expiration_alerts`: 'Alertes d\'expiration'
- `expiration_alerts_description`: 'Recevoir des notifications pour les produits qui expirent bientôt'
- `expiration_alerts_enabled`: 'Alertes d\'expiration: activées'
- `expiration_alerts_disabled`: 'Alertes d\'expiration: désactivées'
- `early_alert`: 'Alerte anticipée'
- `days_before_expiration`: 'Jours avant expiration pour déclencher l\'alerte'
- `early_alert_modification_coming`: 'Modification de l\'alerte anticipée à venir'
- `validity_period`: 'Durée de validité'
- `configure_validity_by_product`: 'Configurer la durée de validité par type de produit'
- `validity_config_coming`: 'Configuration des durées de validité à venir'

#### Notification Settings
- `notification_settings`: 'Paramètres de Notifications'
- `critical_stock_alerts`: 'Alertes de stock critique'
- `critical_stock_alerts_description`: 'Recevoir des notifications lorsque le stock est faible'
- `critical_stock_alerts_enabled`: 'Alertes de stock critique: activées'
- `critical_stock_alerts_disabled`: 'Alertes de stock critique: désactivées'
- `daily_notifications`: 'Notifications journalières'
- `daily_summary_description`: 'Recevoir un résumé journalier de l\'état du stock'
- `daily_notifications_enabled': 'Notifications journalières: activées'
- `daily_notifications_disabled`: 'Notifications journalières: désactivées'
- `notification_channels`: 'Canaux de notification'
- `configure_notification_channels`: 'Configurer où recevoir les alertes (email, SMS, etc.)'
- `notification_channels_config_coming`: 'Configuration des canaux de notification à venir'

#### General Settings Note
- `note`: 'Note'
- `general_settings_in_profile`: 'Les paramètres généraux de l\'application (thème, langue, etc.) sont disponibles dans l\'onglet Profil.'

#### Common Actions
- `setting_updated`: 'Paramètre mis à jour'
- `update_error`: 'Erreur lors de la mise à jour'
- `configuration`: 'Configuration'

### 2. Helper Class Created

Created `BloodTranslations` helper class in `lib/blood_bank/utils/blood_translations.dart`:

```dart
class BloodTranslations {
  // Translate blood component keys
  static String getBloodComponentName(String componentKey)
  
  // Translate blood type keys
  static String getBloodTypeName(String bloodTypeKey)
  
  // Get month name from number
  static String getMonthName(int month)
  
  // Get period label for charts
  static String getPeriodLabel(String period)
  
  // Get stock level label
  static String getStockLevelLabel(int quantity)
  
  // Format time ago
  static String formatTimeAgo(DateTime dateTime)
}
```

### 3. Imports Added

Added to BloodBankInventoryPage.dart:
```dart
import 'package:get/get.dart';
import '../../utils/blood_translations.dart';
```

### 4. Methods Updated

- `_formatLastUpdated()` - Now uses `BloodTranslations.formatTimeAgo()`

---

## ⏳ Remaining Work

### Update All Hardcoded Strings

The BloodBankInventoryPage.dart file contains ~274 hardcoded French strings that need to be replaced with `.tr` calls.

#### Key Sections to Update:

1. **Dialog Titles and Messages** (Lines 138-180)
   - Edit price dialog
   - Edit threshold dialog
   - Success/error messages

2. **Tab Labels** (Lines 502-515)
   - 'Vue d\'ensemble' → 'overview'.tr
   - 'Stock de Sang' → 'blood_stock'.tr
   - 'Rapports' → 'reports'.tr
   - 'Paramètres' → 'parameters'.tr

3. **Statistics Cards** (Lines 555-606)
   - 'Statistiques Rapides' → 'quick_statistics'.tr
   - 'Stock Total' → 'total_stock'.tr
   - 'Demandes Actives' → 'active_requests'.tr
   - etc.

4. **Blood Distribution Section** (Lines 707-733)
   - 'Distribution par Type de Sang' → 'blood_type_distribution'.tr
   - 'Aucun stock disponible' → 'no_stock_available'.tr

5. **Recent Activity** (Lines 827-890)
   - 'Activité Récente' → 'recent_activity'.tr
   - Activity titles and subtitles

6. **Blood Stock Tab** (Lines 918-1485)
   - Search placeholder
   - Empty state messages
   - Stock details

7. **Reports Tab** (Lines 1628-2660)
   - Report titles
   - Chart labels
   - Metric names
   - Month names (use `BloodTranslations.getMonthName()`)

8. **Settings Tab** (Lines 1675-2050)
   - Section titles
   - Setting descriptions
   - Toggle labels

9. **Export Section** (Lines 3070-3310)
   - Export options
   - Format labels

10. **Helper Methods** (Lines 3319-3375)
    - `_getMonthName()` - Replace with `BloodTranslations.getMonthName()`
    - `_getPeriodLabel()` - Replace with `BloodTranslations.getPeriodLabel()`
    - `_getStockLevel()` - Update labels to use `.tr`

---

## 📝 Implementation Pattern

### Before:
```dart
Text('Gestion d\'Inventaire')
```

### After:
```dart
Text('inventory_management'.tr)
```

### With Parameters:
```dart
// Before
Text('Prix mis à jour pour $product')

// After
Text('price_updated'.trParams({'product': BloodTranslations.getBloodComponentName(product)}))
```

### Blood Components:
```dart
// Before
Text(product) // Shows 'whole_blood'

// After
Text(BloodTranslations.getBloodComponentName(product)) // Shows 'Sang Complet'
```

### Blood Types:
```dart
// Before
Text(bloodType) // Shows 'A+'

// After
Text(BloodTranslations.getBloodTypeName(bloodType)) // Shows 'A+' (already correct, but consistent)
```

---

## 🧪 Testing

After implementing all translations:

1. **Test French (default)**
   - All text should display in French
   - Blood components should show French names
   - Dates and times should be formatted correctly

2. **Test English** (if added)
   - Switch language to English
   - Verify all translations appear
   - Check blood component names

3. **Test Dynamic Content**
   - Blood component names in dialogs
   - Blood type names in lists
   - Month names in charts
   - Time ago formatting

---

## 🚀 Next Steps

1. **Update all hardcoded strings** in BloodBankInventoryPage.dart to use `.tr`
2. **Add English translations** to AppTranslations.dart (if needed)
3. **Test language switching** throughout the page
4. **Update child widgets** (RealDataChartPainter, ReportPreviewDialog) if they contain hardcoded strings
5. **Add Russian translations** (already partially in AppTranslations.dart)

---

## 📊 Progress

- ✅ Translation keys added: **100%**
- ✅ Helper class created: **100%**
- ✅ Imports added: **100%**
- ⏳ Hardcoded strings replaced: **1%** (1 of ~274)
- ⏳ Testing completed: **0%**

**Overall Progress: ~25%**

---

## 💡 Tips

1. **Use Find & Replace** carefully for common patterns
2. **Test frequently** to catch errors early
3. **Keep translation keys consistent** with existing patterns
4. **Use `trParams`** for dynamic content
5. **Use `BloodTranslations` helper** for blood-related keys

---

## 📚 References

- Translation keys: `lib/apps/translations/AppTranslations.dart`
- Helper class: `lib/blood_bank/utils/blood_translations.dart`
- Main page: `lib/blood_bank/ui/pages/BloodBankInventoryPage.dart`
- Get package docs: https://pub.dev/packages/get

