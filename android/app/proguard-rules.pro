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
# Google Cast SDK Keep Rules
# =========================
-keep class com.google.android.gms.cast.** { *; }
-keep class com.filmytell.ott.cast.** { *; }
-keep class androidx.mediarouter.** { *; }
-dontwarn com.google.android.gms.cast.**
-dontwarn androidx.mediarouter.**

