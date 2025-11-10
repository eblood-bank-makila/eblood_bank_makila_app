#!/bin/bash

# Script to get SHA-1 fingerprint for Google Sign-In configuration
# This is needed to configure Firebase/Google Sign-In properly

echo "=========================================="
echo "Getting SHA-1 Fingerprint for Debug Build"
echo "=========================================="
echo ""

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ Error: keytool not found!"
    echo "Please make sure Java JDK is installed and in your PATH"
    exit 1
fi

# Get debug keystore SHA-1
echo "📱 Debug Keystore SHA-1:"
echo "Location: ~/.android/debug.keystore"
echo ""

keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -A 2 "Certificate fingerprints"

echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo "1. Copy the SHA1 fingerprint above"
echo "2. Go to Firebase Console: https://console.firebase.google.com/"
echo "3. Select project: e-blood-bankv1-1"
echo "4. Go to Project Settings (gear icon)"
echo "5. Scroll to 'Your apps' section"
echo "6. Find Android app: com.ebloodbank.makila.grpe.apps.eblood_bank_mak_app"
echo "7. Click 'Add fingerprint'"
echo "8. Paste the SHA1 fingerprint"
echo "9. Click Save"
echo "10. Download updated google-services.json"
echo "11. Replace android/app/google-services.json"
echo "12. Run: flutter clean && flutter pub get && flutter run"
echo ""
echo "=========================================="
echo "For Release Build (when ready):"
echo "=========================================="
echo "You'll also need to add the SHA-1 from your release keystore"
echo "Run: keytool -list -v -keystore /path/to/your/release.keystore"
echo ""

