# =========================
# Razorpay SDK Keep Rules
# =========================
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep ProGuard annotations (these may be missing)
-keep class proguard.annotation.** { *; }

# Keep any annotations used by libraries
-keepattributes *Annotation*

# AndroidX annotations
-keep class androidx.annotation.** { *; }

# =========================
# Flutter and General Rules
# =========================
# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Dart-generated code
-keep class io.flutter.plugins.** { *; }

# Don't strip out model/data classes (optional safety)
-keep class **.model.** { *; }

# =========================
# MediaKit / MPV Keep Rules
# =========================
-keep class com.alexmercerind.mediakitandroidhelper.** { *; }
-keep class com.ryanheise.** { *; }
-dontwarn com.alexmercerind.mediakitandroidhelper.**

# =========================
# Video Player / Media3 Rules
# =========================
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class io.flutter.plugins.videoplayer.** { *; }

# =========================
# AndroidX Leanback / TV Rules
# =========================
-keep class androidx.leanback.** { *; }
-dontwarn androidx.leanback.**

# =========================
# Security / KeyStore Rules
# =========================
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**
