# Remove flutter_webrtc from .flutter-plugins file
# This prevents the plugin from being compiled, avoiding deprecated API errors

$flutterPluginsFile = ".flutter-plugins"
if (Test-Path $flutterPluginsFile) {
    $content = Get-Content $flutterPluginsFile
    $filtered = $content | Where-Object { $_ -notmatch "flutter_webrtc" }
    $filtered | Set-Content $flutterPluginsFile
    Write-Host "Removed flutter_webrtc from .flutter-plugins"
} else {
    Write-Host ".flutter-plugins file not found"
}

