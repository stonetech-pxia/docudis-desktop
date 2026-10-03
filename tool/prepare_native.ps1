# Builds the native libraries the app loads on Windows, at the revisions
# pinned in tool/native.lock.json, into build\native\windows\:
#
#   docudis_capi.dll        docudis-core (with language identification)
#   docudis_ner_capi.dll    docudis-ner
#   onnxruntime.dll         ONNX Runtime, built from source without telemetry
#
# windows\CMakeLists.txt installs them next to docudis.exe.
#
#   powershell -ExecutionPolicy Bypass -File tool\prepare_native.ps1
#   $env:DOCUDIS_CORE_SOURCE = '..\docudis-core'; tool\prepare_native.ps1
#
# DOCUDIS_CORE_SOURCE / DOCUDIS_NER_SOURCE use a local checkout instead of a
# fresh clone; it must be at the pinned revision. Needs git, Python 3, the
# Rust MSVC toolchain and Visual Studio's C++ build tools with CMake. The
# first ONNX Runtime build takes a while; later runs reuse it. Only Windows
# x64 for now.
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

# Checks out $Repository at $Revision into $Dir, or verifies the local
# checkout in the environment variable named $Override, if any.
function Get-Source {
  param([string]$Override, [string]$Repository, [string]$Revision, [string]$Dir)
  $local = if ($Override) { [Environment]::GetEnvironmentVariable($Override) }
  if ($local) {
    $actual = (& git -C $local rev-parse HEAD)
    if ($actual -ne $Revision) { throw "$Override is at $actual, expected $Revision" }
    return (Resolve-Path $local).Path
  }
  $dir = $Dir
  if (-not (Test-Path (Join-Path $dir '.git'))) {
    New-Item -ItemType Directory -Force $dir | Out-Null
    Invoke-Checked git -C $dir init -q
    Invoke-Checked git -C $dir config core.longpaths true
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
$coreSrc = Get-Source DOCUDIS_CORE_SOURCE $core.repository $core.revision `
  (Join-Path $cache "src\docudis-core-$($core.revision)")
Write-Host "Building docudis-core ($($core.revision.Substring(0, 7)))"
Push-Location $coreSrc
try { Invoke-Checked cargo build --release -p docudis-capi --features $core.features }
finally { Pop-Location }
Copy-Item -Force (Join-Path $env:CARGO_TARGET_DIR 'release\docudis_capi.dll') $out

$ner = $lock.docudis_ner
$nerSrc = Get-Source DOCUDIS_NER_SOURCE $ner.repository $ner.revision `
  (Join-Path $cache "src\docudis-ner-$($ner.revision)")
Write-Host "Building docudis-ner ($($ner.revision.Substring(0, 7)))"
Push-Location $nerSrc
try { Invoke-Checked cargo build --release -p docudis-ner-capi }
finally { Pop-Location }
Copy-Item -Force (Join-Path $env:CARGO_TARGET_DIR 'release\docudis_ner_capi.dll') $out

# ONNX Runtime from source with --no_telemetry. The official Windows build
# registers its event provider in Microsoft's telemetry group, so Windows
# may upload what it logs while the environment starts, before ort can turn
# telemetry off. FETCHCONTENT_TRY_FIND_PACKAGE_MODE=NEVER keeps CMake to the
# dependencies ONNX Runtime pins, not ones installed on the machine. Short
# folder names: MSBuild still trips over long paths.
$ort = $lock.onnxruntime
$ortName = $ort.revision.Substring(0, 12)
$ortSrc = Get-Source '' $ort.repository $ort.revision (Join-Path $cache "ort\$ortName")
$ortBuild = Join-Path $cache "ort\$ortName-build"
$ortDll = Join-Path $ortBuild 'Release\Release\onnxruntime.dll'
if (-not (Test-Path $ortDll)) {
  Write-Host "Building ONNX Runtime $($ort.version) ($($ort.revision.Substring(0, 7))) without telemetry"
  $vs = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
  $cmakeBin = Join-Path $vs 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin'
  Invoke-Checked python (Join-Path $ortSrc 'tools\ci_build\build.py') `
    --build_dir $ortBuild --config Release --build_shared_lib --parallel `
    --no_telemetry --skip_tests --skip_submodule_sync --skip_pip_install `
    --compile_no_warning_as_error `
    --cmake_extra_defines FETCHCONTENT_TRY_FIND_PACKAGE_MODE=NEVER `
    --cmake_path (Join-Path $cmakeBin 'cmake.exe') `
    --ctest_path (Join-Path $cmakeBin 'ctest.exe') `
    --cmake_generator 'Visual Studio 17 2022'
}
Copy-Item -Force $ortDll $out

Get-ChildItem $out | Format-Table Name, Length
