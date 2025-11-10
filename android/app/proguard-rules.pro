# ProGuard/R8 rules for optional ML Kit Text Recognition modules
# The google_mlkit_text_recognition plugin may reference language-specific
# recognizer options that are not included in your app. Suppress missing class
# warnings for these optional artifacts.

-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**

# Keep ML Kit vision text classes that are present
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }

# Some internal ML Kit classes can trigger warnings; suppress them.
-dontwarn com.google.android.gms.internal.mlkit_vision_text_common.**
