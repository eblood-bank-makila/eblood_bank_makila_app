# Adding Authentication Token to BloodBankApiService

This implementation adds authentication token support to the BloodBankApiService by retrieving the token from the UtilisateurLocalService and adding it to the request headers.

## Implementation Overview

1. The `BloodBankApiService` now accepts a `UtilisateurLocalService` in its constructor.
2. The `_getHeaders()` method has been updated to retrieve and use the authentication token.
3. Error handling has been added for cases where token retrieval might fail.

## How to Complete the Integration

To fully integrate this implementation, you need to update the `main.dart` file to inject the `UtilisateurLocalService` into the `BloodBankApiService`. Here's how:

### Option 1: Direct Provider Override (Recommended)

Add the following code to `main.dart` after creating the UtilisateurLocalServiceImpl:

```dart
// After creating the user interactor
var container = ProviderContainer();
container.read(bloodBankApiServiceProvider.overrideWithValue(
  BloodBankApiService(userLocalService: utilisateurLocalImpl)
));
```

### Option 2: Update the BloodBankApiServiceProvider

If you prefer not to use provider overrides, modify the `bloodBankApiServiceProvider` in `BloodBankController.dart` to directly access the service:

```dart
// In BloodBankController.dart
final bloodBankApiServiceProvider = Provider<BloodBankApiService>((ref) {
  // Access the database from a global variable or singleton
  final db = AppDatabase.instance.database;
  final userLocalService = UtilisateurLocalServiceImpl(db);
  return BloodBankApiService(userLocalService: userLocalService);
});
```

## Testing the Implementation

To verify that the authentication token is being included in the headers:

1. Login to the app to generate a valid token
2. Add logging in one of your API endpoints to print the headers:

```dart
Future<ApiResponse<List<BloodStock>>> getBloodStock() async {
  try {
    final headers = await _getHeaders();
    print('🔍 DEBUG: API Headers: $headers'); // Add this line to see headers
    final response = await http.get(
      Uri.parse(ApiConfig.buildUrl(ApiConfig.bloodStock)),
      headers: headers,
    );
    // Rest of the method...
```

3. Watch the logs when making an API request to verify that the Authorization header is being included.

4. Alternatively, use a network inspection tool like Charles Proxy to verify the headers in network requests.

## Troubleshooting

If the token is not being included in the headers, check the following:

1. Ensure the user is logged in and has a valid token
2. Check if `recupererTokenOtp()` or `recupererToken()` are returning non-empty values
3. Verify that `_userLocalService` is properly injected into `BloodBankApiService`
4. Add additional logging in the `_getHeaders()` method to debug token retrieval