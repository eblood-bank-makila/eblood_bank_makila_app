import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}

// --- Auto-incrementing versionCode -------------------------------------------
// Release builds (bundleRelease / assembleRelease) get a unique, monotonically
// increasing code = whole minutes since the Unix epoch (~29.6M as of 2026-06).
// It rises ~1 per minute, so no manual --build-number and no git commit are
// needed, and it stays far below Play's 2,100,000,000 cap. Debug/profile builds
// keep the stable pubspec code so day-to-day `flutter run` isn't churned.
// To pin a specific code (rare), set versionCodeOverride=NNN in
// android/gradle.properties (or pass -PversionCodeOverride=NNN) — it wins.
val isReleaseBuild = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
val versionCodeOverride = (project.findProperty("versionCodeOverride") as? String)?.toIntOrNull()
val autoVersionCode = (System.currentTimeMillis() / 60_000L).toInt()
// -----------------------------------------------------------------------------

android {
    namespace = "com.ebloodbank.makila.grpe.apps.eblood_bank_mak_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358" // required by jni plugin (was 27.0.12077973)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.ebloodbank.makila.grpe.apps.eblood_bank_mak_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = versionCodeOverride ?: (if (isReleaseBuild) autoVersionCode else flutter.versionCode)
        versionName = flutter.versionName

        // Ship only the locales you support to reduce resources size
        resourceConfigurations += listOf("en", "fr")
        // If you want a single-ABI APK instead of universal, uncomment below
        // ndk {
        //     abiFilters += listOf("arm64-v8a")
        // }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Use the release signing config (reads android/key.properties).
            // Falls back to debug signing if key.properties is missing so
            // `flutter run --release` still works locally.
            signingConfig = if (rootProject.file("key.properties").exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            // Ensure ProGuard/R8 uses our rules file to handle optional ML Kit modules
            isMinifyEnabled = true
            // Remove unused Android resources after code shrinking
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
