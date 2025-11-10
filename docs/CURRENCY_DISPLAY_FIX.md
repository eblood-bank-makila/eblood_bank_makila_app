# Currency Display Fix

## Issue

The UI was displaying hardcoded "FCFA" instead of using the actual currency from the backend response.

**Backend Response:**
```json
{
  "currency": {
    "id": "68afd6842df8aaf1094631af",
    "code": "cdf",
    "symbol": "cdf",
    "name": "franc congolais"
  }
}
```

**Expected:** Display "CDF" (from `currency.code`)  
**Actual:** Display "FCFA" (hardcoded)

## Root Cause

The `InventorySettings` model was correctly parsing the currency object and extracting the `code` field, but the UI had hardcoded "FCFA" strings in two places:

1. **Price edit dialog** (line 151): `'Prix (FCFA)'`
2. **Price display** (line 1775): `'${entry.value} FCFA / unité'`

## Solution

### 1. Updated Price Edit Dialog

**File:** `lib/blood_bank/ui/pages/BloodBankInventoryPage.dart`

**Before:**
```dart
Future<void> _editPriceDialog(String product, double currentPrice) async {
  final controller = TextEditingController(text: currentPrice.toStringAsFixed(2));
  final result = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Modifier le prix de $product'),
      content: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: 'Prix (FCFA)'),
      ),
```

**After:**
```dart
Future<void> _editPriceDialog(String product, double currentPrice) async {
  final settingsState = ref.read(inventorySettingsProvider);
  final currentSettings = settingsState.settings;
  final currencyCode = currentSettings?.currency ?? 'USD';
  
  final controller = TextEditingController(text: currentPrice.toStringAsFixed(2));
  final result = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Modifier le prix de $product'),
      content: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: 'Prix ($currencyCode)'),
      ),
```

**Changes:**
- Added code to read current settings and extract currency code
- Changed hardcoded `'Prix (FCFA)'` to `'Prix ($currencyCode)'`
- Falls back to 'USD' if settings are not available

### 2. Updated Price Display

**Before:**
```dart
Text(
  '${entry.value} FCFA / unité',
  style: GoogleFonts.ubuntu(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.green.shade700,
  ),
),
```

**After:**
```dart
Text(
  '${entry.value} ${settings.currency} / unité',
  style: GoogleFonts.ubuntu(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.green.shade700,
  ),
),
```

**Changes:**
- Changed hardcoded `'FCFA'` to `'${settings.currency}'`
- Uses the currency from the settings object

## How It Works

### Backend → Flutter Data Flow

1. **Backend sends:**
   ```json
   {
     "currency": {
       "id": "68afd6842df8aaf1094631af",
       "code": "cdf",
       "symbol": "cdf",
       "name": "franc congolais"
     }
   }
   ```

2. **Flutter model parses:**
   ```dart
   String parseCurrency(dynamic currencyData) {
     if (currencyData == null) return 'USD';
     
     // If it's a string, return it
     if (currencyData is String) return currencyData;
     
     // If it's an object with code, return the code
     if (currencyData is Map && currencyData.containsKey('code')) {
       return currencyData['code'].toString().toUpperCase();
     }
     
     return 'USD';
   }
   ```
   
   Result: `"CDF"` (extracted from `currency.code` and converted to uppercase)

3. **UI displays:**
   - Price edit dialog: `"Prix (CDF)"`
   - Price display: `"10.0 CDF / unité"`

## Testing

After hot reload, you should see:

### Settings Tab - Product Prices Section

**Before:**
```
whole_blood    10.0 FCFA / unité
plasma         10.0 FCFA / unité
platelets      10.0 FCFA / unité
red_cells      10.0 FCFA / unité
```

**After:**
```
whole_blood    10.0 CDF / unité
plasma         10.0 CDF / unité
platelets      10.0 CDF / unité
red_cells      10.0 CDF / unité
```

### Price Edit Dialog

**Before:**
```
Modifier le prix de whole_blood
Prix (FCFA): [10.0]
```

**After:**
```
Modifier le prix de whole_blood
Prix (CDF): [10.0]
```

## Benefits

✅ **Dynamic Currency Display** - Currency is now read from backend settings  
✅ **No Hardcoded Values** - Easy to support multiple currencies  
✅ **Consistent with Backend** - UI matches the actual currency in the database  
✅ **Backward Compatible** - Falls back to 'USD' if currency is not available  

## Files Modified

1. **`lib/blood_bank/ui/pages/BloodBankInventoryPage.dart`**
   - Line 141-156: Updated `_editPriceDialog()` to read currency from settings
   - Line 1775: Changed hardcoded "FCFA" to use `settings.currency`

## Related Files

- **`lib/blood_bank/models/inventory_settings.dart`** - Already correctly parsing currency
- **`lib/blood_bank/services/inventory_settings_service.dart`** - Fetching settings from backend
- **`lib/blood_bank/providers/inventory_settings_provider.dart`** - Managing settings state

## Next Steps

1. Hot reload the Flutter app (should happen automatically)
2. Navigate to the Settings tab
3. Verify that prices show "CDF" instead of "FCFA"
4. Click on a price to edit it
5. Verify that the dialog shows "Prix (CDF)" instead of "Prix (FCFA)"

## Notes

- The currency code is automatically converted to uppercase in the model (`parseCurrency()`)
- The backend sends `"code": "cdf"`, which becomes `"CDF"` in the UI
- If the backend changes the currency, the UI will automatically reflect the change
- No database migration needed - this is purely a UI fix

