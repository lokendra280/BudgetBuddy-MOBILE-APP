# ── Flutter Play Core split-install ────────────────────────────────────────────
# Flutter's engine references these even when you don't use deferred components.
# Without these rules R8 crashes with "Missing class SplitCompatApplication".
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ── Flutter engine ──────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# ── ML Kit text recognition ─────────────────────────────────────────────────────
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-dontwarn com.google.mlkit.**

# ── Google Mobile Ads (AdMob) ───────────────────────────────────────────────────
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ── Supabase / OkHttp / Kotlin ──────────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.**
-keep class kotlin.Metadata { *; }

# ── Hive (local database) ───────────────────────────────────────────────────────
-keep class * extends com.google.flatbuffers.Table { *; }
-keep @com.google.flatbuffers.Struct class * { *; }
-keep class * implements io.hive.** { *; }

# ── General Android ─────────────────────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception