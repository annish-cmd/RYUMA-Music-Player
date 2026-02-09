# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.BuildConfig { *; }
-keep class io.flutter.embedding.** { *; }
-keep class androidx.lifecycle.** { *; }

# Flutter plugins
-keep class com.ryanheise.** { *; }
-keep class com.ryanheise.audio_session.** { *; }
-keep class com.ryanheise.audioservice.** { *; }

# Audio Service - Media Session and Notification
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }
-keep class android.media.session.** { *; }

# AndroidX
-keep class androidx.** { *; }
-keep class com.google.android.material.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Google Play Core Library - Fix for R8 optimization (use dontwarn for optional dependencies)
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

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep setters and getters
-keepclassmembers class * {
    *** set*(***);
    *** get*();
}

# Keep enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep serialized classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotated classes
-keepclasseswithmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep reflection used classes
-keepclassmembers class * {
    @android.view.View$InjectView *;
    @android.view.View$OnClick *;
}