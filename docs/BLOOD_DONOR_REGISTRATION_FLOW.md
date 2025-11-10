# Blood Donor Registration Flow Implementation

## Overview
This document describes the enhanced personal registration process for blood donors. After OTP verification succeeds, the system now checks the registration reason. If the user is registering as a blood donor, they are directed to select a nearby blood bank before completing registration.

## Flow Diagram

```
PersonalRegistrationPage
    ↓
    [User fills form with registration_reason = 'blood_donor']
    ↓
OTPVerificationPage
    ↓
    [OTP verification succeeds]
    ↓
    [Check registration_reason]
    ↓
    IF registration_reason == 'blood_donor':
        ↓
        NearbyBloodBankSelectionPage
        ↓
        [Get device location (latitude, longitude)]
        ↓
        [Call /eblood-connect/nearby-blood-bank API]
        ↓
        [Display list of nearby blood banks]
        ↓
        [User selects a blood bank]
        ↓
        [Add sys_health_structure_id to registration payload]
        ↓
        [Submit registration with blood bank ID]
        ↓
        RegistrationSuccessPage
    ELSE:
        ↓
        [Direct registration submission]
        ↓
        RegistrationSuccessPage
```

## Implementation Details

### 1. AuthService Enhancement
**File:** `lib/apps/services/AuthService.dart`

Added new method `getNearbyBloodBanks()`:
- Takes device latitude and longitude
- Calls `/eblood-connect/nearby-blood-bank` endpoint
- Returns list of nearby blood banks within specified radius (default 50km)
- Handles errors and timeouts gracefully

```dart
Future<Map<String, dynamic>> getNearbyBloodBanks({
  required double latitude,
  required double longitude,
  double radiusKm = 50.0,
  int limit = 10,
})
```

### 2. NearbyBloodBankSelectionPage
**File:** `lib/apps/demarrage/NearbyBloodBankSelectionPage.dart`

New screen that:
- Requests device location permission
- Fetches nearby blood banks using Geolocator
- Displays blood banks in a scrollable list
- Allows user to select a blood bank
- Updates registration payload with `sys_health_structure_id`
- Submits registration with the selected blood bank

Features:
- Loading state with spinner
- Error handling with retry option
- Visual feedback for selected blood bank
- Smooth animations for list items

### 3. OTPVerificationPage Enhancement
**File:** `lib/apps/demarrage/OTPVerificationPage.dart`

Modified verification flow:
- After OTP verification succeeds, checks `registration_reason` field
- If `registration_reason == 'blood_donor'`:
  - Navigates to `NearbyBloodBankSelectionPage`
  - Passes userData, phoneNumber, and email
- Otherwise:
  - Proceeds with direct registration (existing flow)

### 4. API Integration

**Endpoint:** `/eblood-connect/nearby-blood-bank`
- **Method:** POST
- **Body Parameters:**
  - `latitude` (float): Device latitude
  - `longitude` (float): Device longitude
  - `radius_km` (float): Search radius in kilometers (default: 50)
  - `limit` (int): Maximum number of results (default: 10)

**Response:**
```json
{
  "status_code": 200,
  "message": "Nearby blood banks retrieved successfully",
  "data": [
    {
      "id": "blood_bank_id",
      "sys_id": "system_id",
      "name": "Blood Bank Name",
      "address": "Address",
      "latitude": 0.0,
      "longitude": 0.0,
      "distance_km": 5.2
    }
  ]
}
```

## Registration Payload Update

When a blood bank is selected, the registration payload is updated:

```dart
updatedUserData['sys_health_structure_id'] = selectedBloodBank['id'];
```

This ensures the user's registration is linked to the selected blood bank.

## User Experience

1. **Personal Registration Form**
   - User selects "blood_donor" as registration reason
   - Fills all required fields
   - Submits form

2. **OTP Verification**
   - User enters OTP code
   - System verifies OTP

3. **Blood Bank Selection** (NEW)
   - System detects blood donor registration
   - Requests location permission
   - Fetches nearby blood banks
   - User selects preferred blood bank
   - System adds blood bank ID to registration

4. **Registration Success**
   - User is registered as blood donor
   - Account is linked to selected blood bank
   - User can proceed to app

## Error Handling

- **Location Permission Denied:** Shows error message with retry option
- **API Timeout:** Displays timeout error with retry button
- **No Blood Banks Found:** Shows appropriate message
- **Network Error:** Graceful error handling with retry functionality

## Testing Checklist

- [ ] Test registration with blood_donor reason
- [ ] Verify location permission request
- [ ] Confirm nearby blood banks are fetched
- [ ] Test blood bank selection
- [ ] Verify sys_health_structure_id is added to payload
- [ ] Confirm registration completes successfully
- [ ] Test with non-blood-donor reasons (should skip blood bank selection)
- [ ] Test error scenarios (no location, no blood banks, network errors)

## Future Enhancements

- Add map view for blood bank locations
- Show distance to each blood bank
- Add blood bank details (hours, services, etc.)
- Add favorites/bookmarks for blood banks
- Implement blood bank search/filter
- Add real-time blood bank availability

