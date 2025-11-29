@echo off
echo ========================================
echo Phoenix Music - Plugin Fix Script
echo ========================================
echo.

:: Get the plugin path
set PLUGIN_PATH=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\on_audio_query_android-1.1.0\android

echo Checking plugin directory...
if not exist "%PLUGIN_PATH%" (
    echo ERROR: Plugin directory not found!
    echo Please run 'flutter pub get' first.
    pause
    exit /b 1
)

echo Plugin found at: %PLUGIN_PATH%
echo.

:: Backup the original build.gradle
echo Creating backup...
if not exist "%PLUGIN_PATH%\build.gradle.backup" (
    copy "%PLUGIN_PATH%\build.gradle" "%PLUGIN_PATH%\build.gradle.backup"
    echo Backup created: build.gradle.backup
) else (
    echo Backup already exists, skipping...
)
echo.

:: Create the fixed build.gradle
echo Fixing build.gradle...

(
echo group 'com.lucasjosino.on_audio_query'
echo version '1.0-SNAPSHOT'
echo.
echo buildscript {
echo     repositories {
echo         google^(^)
echo         mavenCentral^(^)
echo     }
echo.
echo     dependencies {
echo         classpath 'com.android.tools.build:gradle:8.1.0'
echo     }
echo }
echo.
echo rootProject.allprojects {
echo     repositories {
echo         google^(^)
echo         mavenCentral^(^)
echo     }
echo }
echo.
echo apply plugin: 'com.android.library'
echo.
echo android {
echo     namespace 'com.lucasjosino.on_audio_query'
echo
echo     compileSdkVersion 34
echo.
echo     defaultConfig {
echo         minSdkVersion 16
echo         targetSdkVersion 34
echo     }
echo.
echo     compileOptions {
echo         sourceCompatibility JavaVersion.VERSION_1_8
echo         targetCompatibility JavaVersion.VERSION_1_8
echo     }
echo.
echo     lintOptions {
echo         disable 'InvalidPackage'
echo     }
echo }
) > "%PLUGIN_PATH%\build.gradle"

echo.
echo ========================================
echo Fix applied successfully!
echo ========================================
echo.
echo The plugin has been patched with the namespace.
echo You can now run: flutter run
echo.
echo If you need to restore the original:
echo The backup is saved as build.gradle.backup
echo.
pause
