# Flutter core
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }

# Prevent removal of plugin classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Keep model classes (Hive / JSON)
-keep class **.model.** { *; }
# Play Core (REQUIRED for Flutter release builds)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }