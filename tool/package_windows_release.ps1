# Builds falcontvpc.exe (copy of flutter output) and a full Release zip.
param(
  [string]$ReleaseDir = "build\windows\x64\runner\Release",
  [string]$OutDir = "build\windows\release-assets"
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path "$ReleaseDir\falconiptv.exe")) {
  throw "Windows Release paketi bulunamadi: $ReleaseDir\falconiptv.exe"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Copy-Item -Force "$ReleaseDir\falconiptv.exe" "$OutDir\falcontvpc.exe"

$zipPath = Join-Path $OutDir "falcontvpc.zip"
if (Test-Path $zipPath) {
  Remove-Item -Force $zipPath
}

$stage = Join-Path $OutDir "FalconIPTV-PC"
if (Test-Path $stage) {
  Remove-Item -Recurse -Force $stage
}
Copy-Item -Recurse $ReleaseDir $stage
Copy-Item -Force "$OutDir\falcontvpc.exe" "$stage\falcontvpc.exe"
Compress-Archive -Path "$stage\*" -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $stage

Write-Host "Hazir: $OutDir\falcontvpc.exe"
Write-Host "Hazir: $zipPath"
