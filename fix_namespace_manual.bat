@echo off
echo ========================================
echo Phoenix Music - Manual Namespace Fix
echo ========================================

set PLUGIN_PATH=C:\Users\A C E R\AppData\Local\Pub\Cache\hosted\pub.dev\on_audio_query_android-1.1.0\android\build.gradle

echo Checking plugin directory...
if exist "%PLUGIN_PATH%" (
    echo Plugin found at: %PLUGIN_PATH%
    
    REM Create backup
    copy "%PLUGIN_PATH%" "%PLUGIN_PATH%.backup2" >nul
    echo Backup created: build.gradle.backup2
    
    echo Fixing build.gradle...
    
    REM Read the file and add namespace
    powershell -Command "(Get-Content '%PLUGIN_PATH%' -Raw) -replace 'android {\r?\n    compileSdkVersion', 'android {\r\n    namespace ''com.lucasjosino.on_audio_query''\r\n    compileSdkVersion' | Set-Content '%PLUGIN_PATH%' -Encoding ASCII"
    
    echo.
    echo ========================================
    echo Fix applied successfully!
    echo ========================================
    echo.
    echo The plugin has been patched with the namespace.
    echo You can now run: flutter run
    echo.
    echo If you need to restore the original:
    echo The backup is saved as build.gradle.backup2
) else (
    echo Plugin not found at: %PLUGIN_PATH%
    echo Please check if the plugin is installed correctly.
)

pause