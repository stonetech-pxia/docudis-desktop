# Builds the native libraries the app loads on Windows, at the revisions
# pinned in tool/native.lock.json, into build\native\windows\:
#
#   docudis_capi.dll        docudis-core (with language identification)
#   docudis_ner_capi.dll    docudis-ner
#   onnxruntime.dll         ONNX Runtime, verified against its SHA-256
#
# windows\CMakeLists.txt installs them next to docudis.exe.
#
#   powershell -ExecutionPolicy Bypass -File tool\prepare_native.ps1
#   $env:DOCUDIS_CORE_SOURCE = '..\docudis-core'; tool\prepare_native.ps1
#
# DOCUDIS_CORE_SOURCE / DOCUDIS_NER_SOURCE use a local checkout instead of a
# fresh clone; it must be at the pinned revision. Needs git, the Rust MSVC
# toolchain and Visual Studio's C++ build tools. Only Windows x64 for now.
$ErrorActionPreference = 'Stop'

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
  throw 'prepare_native.ps1 supports Windows x64 only'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$lock = Get-Content -Raw (Join-Path $repoRoot 'tool\native.lock.json') | ConvertFrom-Json

$out = Join-Path $repoRoot 'build\native\windows'
$cache = Join-Path $repoRoot 'build\native-cache'
$env:CARGO_TARGET_DIR = Join-Path $cache 'target'
New-Item -ItemType Directory -Force $out, $cache | Out-Null

# Runs a native command and stops when it fails.
# Plain $args, so flags such as -C reach the command instead of binding here.
function Invoke-Checked {
  $command, $arguments = $args
  & $command @arguments
  if ($LASTEXITCODE -ne 0) { throw "$args failed with exit code $LASTEXITCODE" }
}

# Checks out $Repository at $Revision into the cache, or verifies the local
# checkout in the environment variable named $Override.
function Get-Source {
  param([string]$Override, [string]$Repository, [string]$Revision, [string]$Name)
  $local = [Environment]::GetEnvironmentVariable($Override)
  if ($local) {
    $actual = (& git -C $local rev-parse HEAD)
    if ($actual -ne $Revision) { throw "$Override is at $actual, expected $Revision" }
    return (Resolve-Path $local).Path
  }
  $dir = Join-Path $cache "src\$Name-$Revision"
  if (-not (Test-Path (Join-Path $dir '.git'))) {
    New-Item -ItemType Directory -Force $dir | Out-Null
    Invoke-Checked git -C $dir init -q
    Invoke-Checked git -C $dir remote add origin $Repository
  }
  $head = (& git -C $dir rev-parse -q --verify HEAD 2>$null)
  if ($head -ne $Revision) {
    Invoke-Checked git -C $dir fetch -q --depth 1 origin $Revision
    Invoke-Checked git -C $dir checkout -q --detach FETCH_HEAD
  }
  return $dir
}

$core = $lock.docudis_core
$coreSrc = Get-Source DOCUDIS_CORE_SOURCE $core.repository $core.revision docudis-core
Write-Host "Building docudis-core ($($core.revision.Substring(0, 7)))"
Push-Location $coreSrc
try { Invoke-Checked cargo build --release -p docudis-capi --features $core.features }
finally { Pop-Location }
Copy-Item -Force (Join-Path $env:CARGO_TARGET_DIR 'release\docudis_capi.dll') $out

$ner = $lock.docudis_ner
$nerSrc = Get-Source DOCUDIS_NER_SOURCE $ner.repository $ner.revision docudis-ner
Write-Host "Building docudis-ner ($($ner.revision.Substring(0, 7)))"
Push-Location $nerSrc
try { Invoke-Checked cargo build --release -p docudis-ner-capi }
finally { Pop-Location }
Copy-Item -Force (Join-Path $env:CARGO_TARGET_DIR 'release\docudis_ner_capi.dll') $out

$ortVersion = $lock.onnxruntime.version
$ort = $lock.onnxruntime.'windows-x64'
$archive = Join-Path $cache ([IO.Path]::GetFileName($ort.url))
function Get-Sha256([string]$Path) { (Get-FileHash -Algorithm SHA256 $Path).Hash.ToLowerInvariant() }
if (-not (Test-Path $archive) -or (Get-Sha256 $archive) -ne $ort.sha256) {
  Write-Host "Downloading ONNX Runtime $ortVersion"
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest -UseBasicParsing -Uri $ort.url -OutFile "$archive.part"
  Move-Item -Force "$archive.part" $archive
}
$actualSha = Get-Sha256 $archive
if ($actualSha -ne $ort.sha256) {
  throw "ONNX Runtime archive SHA-256 is $actualSha, expected $($ort.sha256)"
}
Expand-Archive -Force $archive $cache
Copy-Item -Force (Join-Path $cache "onnxruntime-win-x64-$ortVersion\lib\onnxruntime.dll") $out

Get-ChildItem $out | Format-Table Name, Length
