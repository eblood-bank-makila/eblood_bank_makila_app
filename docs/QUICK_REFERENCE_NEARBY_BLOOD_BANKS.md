# Quick Reference: Nearby Blood Banks Endpoint

## 📍 Endpoint Details

| Property | Value |
|----------|-------|
| **URL** | `/api/v1/blood-donors/nearby-blood-banks` |
| **Method** | POST |
| **Authentication** | ❌ Not Required |
| **Permission Check** | ❌ Not Required |
| **API Consumer Key** | ✅ Required |

## 📤 Request Parameters

All parameters are **query parameters**:

```
POST /api/v1/blood-donors/nearby-blood-banks?latitude=-1.9441&longitude=30.0619&radius_km=50&limit=10
```

| Parameter | Type | Required | Default | Range | Description |
|-----------|------|----------|---------|-------|-------------|
| latitude | float | ✅ Yes | - | -90 to 90 | Device latitude coordinate |
| longitude | float | ✅ Yes | - | -180 to 180 | Device longitude coordinate |
| radius_km | float | ❌ No | 50 | 1-500 | Search radius in kilometers |
| limit | int | ❌ No | 10 | 1-100 | Maximum number of results |

## 📥 Response Format

### Success (200 OK)
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

### Error (422 Unprocessable Entity)
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

### Error (500 Internal Server Error)
```json
{
  "detail": "Failed to fetch nearby blood banks: [error message]"
}
```

## 🧪 cURL Examples

### Basic Request
```bash
curl -X POST "http://localhost:8000/api/v1/blood-donors/nearby-blood-banks?latitude=-1.9441&longitude=30.0619&radius_km=50&limit=10" \
  -H "Content-Type: application/json" \
  -H "api-consumer: YOUR_API_CONSUMER_KEY"
```

### With Custom Radius
```bash
curl -X POST "http://localhost:8000/api/v1/blood-donors/nearby-blood-banks?latitude=-1.9441&longitude=30.0619&radius_km=100&limit=20" \
  -H "Content-Type: application/json" \
  -H "api-consumer: YOUR_API_CONSUMER_KEY"
```

### With Minimum Parameters
```bash
curl -X POST "http://localhost:8000/api/v1/blood-donors/nearby-blood-banks?latitude=-1.9441&longitude=30.0619" \
  -H "Content-Type: application/json" \
  -H "api-consumer: YOUR_API_CONSUMER_KEY"
```

## 🎯 Use Cases

### 1. Blood Donor Registration
During registration, when user selects "blood_donor" as registration reason:
1. Get device GPS coordinates
2. Call this endpoint with coordinates
3. Display nearby blood banks
4. User selects a blood bank
5. Add `sys_health_structure_id` to registration payload
6. Submit registration

### 2. Find Nearest Blood Bank
User wants to find the closest blood bank:
```bash
curl -X POST "http://localhost:8000/api/v1/blood-donors/nearby-blood-banks?latitude=-1.9441&longitude=30.0619&radius_km=10&limit=1"
```

### 3. Find All Blood Banks in Area
User wants to see all blood banks within 50km:
```bash
curl -X POST "http://localhost:8000/api/v1/blood-donors/nearby-blood-banks?latitude=-1.9441&longitude=30.0619&radius_km=50&limit=100"
```

## 🔧 Backend Implementation

**Service Method:**
```python
@staticmethod
async def get_nearby_blood_banks(
    latitude: float,
    longitude: float,
    radius_km: float = 50,
    limit: int = 10
) -> List[Dict[str, Any]]:
```

**Location:** `eblood_bank_api/app/modules/blood_donor/services/blood_donor_service.py`

**Features:**
- ✅ Uses Haversine formula for distance calculation
- ✅ Filters by blood bank type and activation status
- ✅ Sorts by distance (closest first)
- ✅ No stock availability constraint
- ✅ Comprehensive error handling

## 📱 Flutter Integration

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
  
  return jsonDecode(response.body);
}
```

## ⚠️ Common Issues

| Issue | Solution |
|-------|----------|
| 403 Forbidden | Check if endpoint is in excluded_routes list |
| 422 Unprocessable Entity | Verify all required parameters are provided |
| 500 Internal Server Error | Check database connection and blood bank records |
| Empty data array | Verify blood banks exist with coordinates in database |
| Incorrect distances | Verify latitude/longitude are in correct format |

## 🔐 Authentication Bypass

This endpoint is excluded from:
- ✅ `verify_logged_in_user` middleware
- ✅ `PermissionCheckMiddleware`

**Excluded Routes:**
- `/api/v1/blood-donors/nearby-blood-banks`
- `/api/v1/eblood-connect/blood-donors/nearby-blood-banks`

## 📊 Response Data Fields

| Field | Type | Description |
|-------|------|-------------|
| id | string | MongoDB ObjectId |
| sys_id | string | System ID (same as id) |
| name | string | Blood bank name |
| address | string | Physical address |
| latitude | float | GPS latitude |
| longitude | float | GPS longitude |
| distance_km | float | Distance from device |
| phone | string | Contact phone |
| email | string | Contact email |
| is_activated | boolean | Active status |
| is_verified | boolean | Verified status |

## ✅ Verification Checklist

- [ ] Endpoint returns 200 OK (not 403)
- [ ] Response includes nearby blood banks
- [ ] Blood banks are sorted by distance
- [ ] Distance calculation is accurate
- [ ] Flutter app can call endpoint
- [ ] Blood bank selection works in registration flow
- [ ] sys_health_structure_id is added to payload
- [ ] Registration completes successfully

