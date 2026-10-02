$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot

$Source = Join-Path $Root "src\runphp.d"

$BuildDir = Join-Path $Root "build"
$BuildExe = Join-Path $BuildDir "runphp.exe"
$BuildConfig = Join-Path $BuildDir "runphp.ini"
$BuildConfigExample = Join-Path $BuildDir "runphp.ini.example"

$ReleaseDir = Join-Path $Root "release"
$ReleaseExe = Join-Path $ReleaseDir "runphp.exe"

Write-Host "Building RunPHP..."
Write-Host ""

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null


# ------------------------------------------------------------
# Development configuration
# ------------------------------------------------------------

if (-not (Test-Path $BuildConfig))
{
    if (-not (Test-Path $BuildConfigExample))
    {
        throw "Development configuration template not found: $BuildConfigExample"
    }

    Copy-Item $BuildConfigExample $BuildConfig

    Write-Host "Development configuration created:"
    Write-Host $BuildConfig
    Write-Host ""
    Write-Host "Configure your PHP executable and run build.ps1 again."
    exit 0
}


# ------------------------------------------------------------
# Compile
# ------------------------------------------------------------

Remove-Item $BuildExe -Force -ErrorAction SilentlyContinue

Push-Location (Join-Path $Root "src")

try
{
    dmd -O -release -of="$BuildExe" "$Source"

    if ($LASTEXITCODE -ne 0)
    {
        throw "DMD compilation failed."
    }

    Remove-Item "runphp.obj" -Force -ErrorAction SilentlyContinue
}
finally
{
    Pop-Location
}

Write-Host "Build complete:"
Write-Host $BuildExe


# ------------------------------------------------------------
# Verify
# ------------------------------------------------------------

Write-Host ""
Write-Host "Testing build..."
Write-Host ""

& $BuildExe --help

if ($LASTEXITCODE -ne 0)
{
    throw "RunPHP test failed."
}

Write-Host ""
Write-Host "Build verified successfully."


# ------------------------------------------------------------
# Release
# ------------------------------------------------------------

Copy-Item $BuildExe $ReleaseExe -Force

Write-Host ""
Write-Host "Release executable updated:"
Write-Host $ReleaseExe