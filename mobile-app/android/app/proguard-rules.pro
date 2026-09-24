# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Gson rules
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.examples.android.model.** { <fields>; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp rules
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Video player rules
-keep class com.google.android.exoplayer2.** { *; }

# Keep all model classes
-keep class ** { *; }

# General Android rules
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep annotation default values (e.g., retrofit2.http.Field.encoded)
-keepattributes AnnotationDefault

# Keep generic signature of Call, Response (R8 full mode strips signatures from non-kept items).
-keep,allowshrinking,allowoptimization interface retrofit2.Call
-keep,allowshrinking,allowoptimization class retrofit2.Response

# Keep inherited services.
-if interface * { @retrofit2.http.* <methods>; }
-keep,allowoptimization class <1>

# Keep generic signature of retrofit2.Response (R8 full mode strips signatures from non-kept items).
-keep,allowshrinking,allowoptimization class retrofit2.Response

# Google Play Core rules
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.** 