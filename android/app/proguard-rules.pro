# =============================================================
# ML Kit Text Recognition — optional language modules
# =============================================================
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_text_common.**

# =============================================================
# Flutter engine + plugin registrant
# =============================================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# =============================================================
# Firebase (core, auth, messaging)
# =============================================================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# =============================================================
# Google Sign-In
# =============================================================
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# =============================================================
# mobile_scanner (ML Kit Barcode)
# =============================================================
-keep class com.google.mlkit.vision.barcode.** { *; }
-keep class com.google.mlkit.vision.codescanner.** { *; }
-dontwarn com.google.mlkit.vision.barcode.**

# =============================================================
# local_auth (biometric)
# =============================================================
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# =============================================================
# flutter_secure_storage
# =============================================================
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# =============================================================
# flutter_local_notifications
# =============================================================
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# =============================================================
# AndroidX lifecycle (used by several plugins via reflection)
# =============================================================
-keep class androidx.lifecycle.DefaultLifecycleObserver { *; }

# =============================================================
# Kotlin coroutines / metadata (used everywhere)
# =============================================================
-dontwarn kotlinx.coroutines.**
-keepclassmembers class kotlin.Metadata { *; }

# =============================================================
# Play Core (used by deferred components on some setups)
# =============================================================
-dontwarn com.google.android.play.core.**
