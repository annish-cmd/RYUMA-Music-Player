# Phoenix Music - Plugin Fix Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Phoenix Music - Plugin Fix Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get the plugin path
$pluginPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\on_audio_query_android-1.1.0\android"
$buildGradlePath = "$pluginPath\build.gradle"
$backupPath = "$pluginPath\build.gradle.backup"

Write-Host "Checking plugin directory..." -ForegroundColor Yellow
if (-not (Test-Path $pluginPath)) {
    Write-Host "ERROR: Plugin directory not found!" -ForegroundColor Red
    Write-Host "Please run 'flutter pub get' first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Plugin found at: $pluginPath" -ForegroundColor Green
Write-Host ""

# Backup the original build.gradle
Write-Host "Creating backup..." -ForegroundColor Yellow
if (-not (Test-Path $backupPath)) {
    Copy-Item $buildGradlePath $backupPath
    Write-Host "Backup created: build.gradle.backup" -ForegroundColor Green
} else {
    Write-Host "Backup already exists, skipping..." -ForegroundColor Yellow
}
Write-Host ""

# Create the fixed build.gradle content
Write-Host "Fixing build.gradle..." -ForegroundColor Yellow

$buildGradleContent = @"
group 'com.lucasjosino.on_audio_query'
version '1.0-SNAPSHOT'

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'

android {
    namespace 'com.lucasjosino.on_audio_query'

    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 16
        targetSdkVersion 34
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    lintOptions {
        disable 'InvalidPackage'
    }
}
"@

# Write the fixed content
Set-Content -Path $buildGradlePath -Value $buildGradleContent -Encoding ASCII

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Fix applied successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "The plugin has been patched with the namespace." -ForegroundColor Cyan
Write-Host "You can now run: flutter run" -ForegroundColor Cyan
Write-Host ""
Write-Host "If you need to restore the original:" -ForegroundColor Yellow
Write-Host "The backup is saved as build.gradle.backup" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to continue"
