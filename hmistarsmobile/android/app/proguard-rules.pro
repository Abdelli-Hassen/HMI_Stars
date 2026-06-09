# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google ML Kit - keep all classes to avoid R8 missing class errors
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ML Kit text recognition scripts (Chinese, Japanese, Korean, Devanagari)
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**

# Google Android Gms
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
