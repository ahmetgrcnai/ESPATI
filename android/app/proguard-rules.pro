# Flutter — keep all Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase — prevent R8 from stripping reflection-based Firebase internals
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Maps
-keep class com.google.android.libraries.maps.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Suppress notes about missing classes that are intentionally absent on Android
-dontnote com.google.android.gms.**
-dontnote io.flutter.**

# Play Core (dynamic feature delivery) — Flutter's embedding always references
# these classes (FlutterPlayStoreSplitApplication) even though this app never
# uses deferred components / dynamic feature modules, so the
# com.google.android.play:core dependency itself is never actually added.
# R8 then fails the release build with "Missing classes detected" since it
# can't verify code paths it will never reach at runtime. Rules below are
# copied verbatim from R8's own generated
# build/app/outputs/mapping/release/missing_rules.txt — safe to silence
# since split-install is unused, not a real missing dependency.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
