# Testing Nearby Blood Banks Endpoint

## 🧪 Test Cases

### Test 1: Basic Request (No Authentication)
**Endpoint:** `POST /api/v1/blood-donors/nearby-blood-banks`

**cURL Command:**
```bash
curl -X POST "http://localhost:8000/api/v1/blood-donors/nearby-blood-banks?latitude=-1.9441&longitude=30.0619&radius_km=50&limit=10" \
  -H "Content-Type: application/json" \
  -H "api-consumer: YOUR_API_CONSUMER_KEY"
```

**Expected Response (200 OK):**
```json
{
  "status_code": 200,
  "message": "Nearby blood banks retrieved successfully",
  "data": [
    {
      "id": "507f1f77bcf86cd799439011",
      "sys_id": "507f1f77bcf86cd799439011",
      "name": "Kigali Central Blood Bank",
      "address": "123 Main Street, Kigali",
      "latitude": -1.9441,
      "longitude": 30.0619,
      "distance_km": 0.0,
      "phone": "+250788123456",
      "email": "info@bloodbank.rw",
      "is_activated": true,
      "is_verified": true
    }
  ]
}
```

### Test 2: With Different Radius
**cURL Command:**
```bash
curl -X POST "http://localhost:8000/api/v1/blood-donors/nearby-blood-banks?latitude=-1.9441&longitude=30.0619&radius_km=100&limit=20" \
  -H "Content-Type: application/json" \
  -H "api-consumer: YOUR_API_CONSUMER_KEY"
```

### Test 3: Missing Required Parameters
**cURL Command:**
```bash
curl -X POST "http://localhost:8000/api/v1/blood-donors/nearby-blood-banks" \
  -H "Content-Type: application/json" \
  -H "api-consumer: YOUR_API_CONSUMER_KEY"
```

**Expected Response (422 Unprocessable Entity):**
```json
{
  "detail": [
    {
      "loc": ["query", "latitude"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

### Test 4: Invalid Radius (Out of Range)
**cURL Command:**
```bash
curl -X POST "http://localhost:8000/api/v1/blood-donors/nearby-blood-banks?latitude=-1.9441&longitude=30.0619&radius_km=1000&limit=10" \
  -H "Content-Type: application/json" \
  -H "api-consumer: YOUR_API_CONSUMER_KEY"
```

**Expected Response (422 Unprocessable Entity):**
```json
{
  "detail": [
    {
      "loc": ["query", "radius_km"],
      "msg": "ensure this value is less than or equal to 500",
      "type": "value_error.number.not_le"
    }
  ]
}
```

### Test 5: Invalid Limit (Out of Range)
**cURL Command:**
```bash
curl -X POST "http://localhost:8000/api/v1/blood-donors/nearby-blood-banks?latitude=-1.9441&longitude=30.0619&radius_km=50&limit=200" \
  -H "Content-Type: application/json" \
  -H "api-consumer: YOUR_API_CONSUMER_KEY"
```

**Expected Response (422 Unprocessable Entity):**
```json
{
  "detail": [
    {
      "loc": ["query", "limit"],
      "msg": "ensure this value is less than or equal to 100",
      "type": "value_error.number.not_le"
    }
  ]
}
```

## 🔐 Authentication Status

✅ **No Authentication Required** - This endpoint is in the excluded routes list
✅ **No Permission Check Required** - This endpoint is in the permission check excluded routes list
✅ **API Consumer Key Required** - Standard API consumer validation still applies

## 📊 Response Fields

| Field | Type | Description |
|-------|------|-------------|
| id | string | MongoDB ObjectId of the blood bank |
| sys_id | string | System ID (same as id) |
| name | string | Blood bank name |
| address | string | Physical address |
| latitude | float | GPS latitude coordinate |
| longitude | float | GPS longitude coordinate |
| distance_km | float | Distance from device in kilometers |
| phone | string | Contact phone number |
| email | string | Contact email address |
| is_activated | boolean | Whether the blood bank is active |
| is_verified | boolean | Whether the blood bank is verified |

## 🚀 Integration with Flutter

The Flutter app calls this endpoint during blood donor registration:

```dart
Future<Map<String, dynamic>> getNearbyBloodBanks({
  required double latitude,
  required double longitude,
  double radiusKm = 50.0,
  int limit = 10,
}) async {
  final endpoint = '$baseApiUrl/eblood-connect/blood-donors/nearby-blood-banks';
  
  final body = {
    'latitude': latitude,
    'longitude': longitude,
    'radius_km': radiusKm,
    'limit': limit,
  };
  
  final response = await http.post(
    Uri.parse(endpoint),
    headers: headers,
    body: jsonEncode(body),
  );
  
  // Returns: {'success': bool, 'data': List, 'message': String}
}
```

## ✅ Verification Checklist

- [ ] API server is running on localhost:8000
- [ ] Database has blood bank records with coordinates
- [ ] Blood banks have `health_structure_type_flag == EHealthStructureType.BLOOD_BANK`
- [ ] Blood banks have `is_activated == true`
- [ ] API consumer key is valid
- [ ] Test endpoint returns 200 OK (not 403 Forbidden)
- [ ] Response includes nearby blood banks sorted by distance
- [ ] Flutter app can successfully call the endpoint
- [ ] Blood bank selection updates registration payload with `sys_health_structure_id`

