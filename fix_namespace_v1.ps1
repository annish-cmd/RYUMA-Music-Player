# Phoenix Music - Plugin Namespace Fix Script v1.1.0
# Fixes the namespace issue for on_audio_query_android-1.1.0

Write-Host "========================================" -ForegroundColor Green
Write-Host "Phoenix Music - Plugin Namespace Fix" -ForegroundColor Green  
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Define the plugin path
$pluginPath = "C:\Users\A C E R\AppData\Local\Pub\Cache\hosted\pub.dev\on_audio_query_android-1.1.0\android\build.gradle"

Write-Host "Checking plugin directory..." -ForegroundColor Yellow

if (Test-Path $pluginPath) {
    Write-Host "Plugin found at: $pluginPath" -ForegroundColor Green
    
    # Create backup
    $backupPath = "$pluginPath.backup"
    if (!(Test-Path $backupPath)) {
        Copy-Item $pluginPath $backupPath
        Write-Host "Backup created: build.gradle.backup" -ForegroundColor Cyan
    } else {
        Write-Host "Backup already exists" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Fixing build.gradle..." -ForegroundColor Yellow
    
    # Read the current content
    $content = Get-Content $pluginPath -Raw
    
    # Add namespace to the android block
    $fixedContent = $content -replace "android \{`r?`n    compileSdkVersion", "android {`r`n    namespace 'com.lucasjosino.on_audio_query'`r`n    compileSdkVersion"
    
    # Write the fixed content
    Set-Content -Path $pluginPath -Value $fixedContent -Encoding UTF8
    
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
    
} else {
    Write-Host "Plugin not found at: $pluginPath" -ForegroundColor Red
    Write-Host "Please check if the plugin is installed correctly." -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to continue"