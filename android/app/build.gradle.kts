import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase — must come after the Android plugin.
    id("com.google.gms.google-services") version "4.4.2"
}

val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) load(file.inputStream())
}

android {
    namespace = "com.espati.espati"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (and timezone package) so that
        // java.time.* API calls are back-ported to API 21+ via D8/R8 desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.espati.espati"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        // Recommended alongside desugaring: the desugar_jdk_libs adds enough
        // methods to risk hitting the 64K DEX limit on older toolchains.
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Inject Maps API key from local.properties into AndroidManifest.xml
        manifestPlaceholders["MAPS_API_KEY"] = localProperties.getProperty("MAPS_API_KEY", "")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Provides the back-ported java.time.* implementations used by
    // flutter_local_notifications and the timezone package.
    // Keep this version in sync with your AGP version:
    //   AGP 8.x → desugar_jdk_libs 2.0.x is the proven-stable range.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
