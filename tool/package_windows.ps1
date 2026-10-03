# Packages the Windows app as a zip that runs where it is unpacked, with
# nothing to install:
#
#   build\package\docudis-<version>-windows-x64.zip
#   build\package\docudis-<version>-windows-x64.zip.sha256
#
# The zip holds the release build (with the native libraries and the Visual
# C++ runtime), LICENSE and NOTICE. -ModelsDir adds the NER models found in
# that folder (each a subfolder with model.json) under models\, where the app
# also looks for them.
#
#   powershell -ExecutionPolicy Bypass -File tool\package_windows.ps1
#   tool\package_windows.ps1 -ModelsDir "$env:APPDATA\stonetech\Docudis\models"
#
# Run tool\prepare_native.ps1 first.
param([string]$ModelsDir)
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
  & flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed with exit code $LASTEXITCODE" }
} finally { Pop-Location }

$version = (Select-String -Path (Join-Path $repoRoot 'pubspec.yaml') -Pattern '^version:\s*([^+\s]+)').Matches[0].Groups[1].Value
$name = "docudis-$version-windows-x64"
$package = Join-Path $repoRoot 'build\package'
$stage = Join-Path $package 'Docudis'
$zip = Join-Path $package "$name.zip"

if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force $stage | Out-Null
Copy-Item -Recurse (Join-Path $repoRoot 'build\windows\x64\runner\Release\*') $stage
Copy-Item (Join-Path $repoRoot 'LICENSE'), (Join-Path $repoRoot 'NOTICE') $stage

if ($ModelsDir) {
  $models = @(Get-ChildItem -Directory $ModelsDir | Where-Object { Test-Path (Join-Path $_.FullName 'model.json') })
  if ($models.Count -eq 0) { throw "no model folder (with model.json) in $ModelsDir" }
  New-Item -ItemType Directory -Force (Join-Path $stage 'models') | Out-Null
  foreach ($model in $models) {
    Copy-Item -Recurse $model.FullName (Join-Path $stage 'models')
    Write-Host "Bundled model $($model.Name)"
  }
}

if (Test-Path $zip) { Remove-Item -Force $zip }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($stage, $zip, [IO.Compression.CompressionLevel]::Optimal, $true)
$sha = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLowerInvariant()
Set-Content -Encoding ascii "$zip.sha256" "$sha  $name.zip"

Get-Item $zip | Format-Table Name, Length
Write-Host "SHA-256 $sha"
