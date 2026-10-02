$ErrorActionPreference = "Stop"

$Version = "1.0.1"

$Root = $PSScriptRoot
$ReleaseDir = Join-Path $Root "release"
$PackageDir = Join-Path $ReleaseDir "packages"

$ZipName = "RunPHP-$Version.zip"
$ZipFile = Join-Path $PackageDir $ZipName

$StageDir = Join-Path `
    ([System.IO.Path]::GetTempPath()) `
    ("RunPHP-Package-" + [Guid]::NewGuid().ToString("N"))


# ------------------------------------------------------------
# Files included in the release
# ------------------------------------------------------------

$ReleaseFiles = @(
    "runphp.exe",
    "runphp.ini",
    "README.txt"
)

$RootFiles = @(
    "LICENSE"
)

$ExpectedZipFiles = @(
    "runphp.exe",
    "runphp.ini",
    "README.txt",
    "LICENSE"
)


# ------------------------------------------------------------
# Validate source files
# ------------------------------------------------------------

Write-Host "Packaging RunPHP $Version..."
Write-Host ""
Write-Host "Validating release files..."

if (-not (Test-Path $ReleaseDir -PathType Container))
{
    throw "Release directory not found: $ReleaseDir"
}

foreach ($File in $ReleaseFiles)
{
    $Path = Join-Path $ReleaseDir $File

    if (-not (Test-Path $Path -PathType Leaf))
    {
        throw "Required release file not found: $Path"
    }
}

foreach ($File in $RootFiles)
{
    $Path = Join-Path $Root $File

    if (-not (Test-Path $Path -PathType Leaf))
    {
        throw "Required repository file not found: $Path"
    }
}

Write-Host "Release files verified."


# ------------------------------------------------------------
# Package
# ------------------------------------------------------------

New-Item `
    -ItemType Directory `
    -Force `
    -Path $PackageDir | Out-Null

try
{
    Write-Host ""
    Write-Host "Creating staging directory..."

    New-Item `
        -ItemType Directory `
        -Path $StageDir | Out-Null


    # --------------------------------------------------------
    # Copy release files and record source hashes
    # --------------------------------------------------------

    $ExpectedHashes = @{}

    foreach ($File in $ReleaseFiles)
    {
        $SourcePath = Join-Path $ReleaseDir $File
        $StagePath = Join-Path $StageDir $File

        $ExpectedHashes[$File] =
            (Get-FileHash `
                -Path $SourcePath `
                -Algorithm SHA256).Hash

        Copy-Item `
            $SourcePath `
            $StagePath
    }

    foreach ($File in $RootFiles)
    {
        $SourcePath = Join-Path $Root $File
        $StagePath = Join-Path $StageDir $File

        $ExpectedHashes[$File] =
            (Get-FileHash `
                -Path $SourcePath `
                -Algorithm SHA256).Hash

        Copy-Item `
            $SourcePath `
            $StagePath
    }


    # --------------------------------------------------------
    # Verify staged files
    # --------------------------------------------------------

    Write-Host "Verifying staged file hashes..."

    foreach ($File in $ExpectedZipFiles)
    {
        $StagePath = Join-Path $StageDir $File

        $StageHash =
            (Get-FileHash `
                -Path $StagePath `
                -Algorithm SHA256).Hash

        if ($StageHash -ne $ExpectedHashes[$File])
        {
            throw @"
Staging verification failed.

File:
  $File

Expected SHA-256:
  $($ExpectedHashes[$File])

Staged SHA-256:
  $StageHash
"@
        }
    }

    Write-Host "Staged file hashes verified."


    # --------------------------------------------------------
    # Create ZIP
    # --------------------------------------------------------

    # Only remove an older package after all source and
    # staged files have been successfully verified.

    if (Test-Path $ZipFile)
    {
        Write-Host "Removing previous package..."
        Remove-Item $ZipFile -Force
    }


    Write-Host "Creating $ZipName..."

    Compress-Archive `
        -Path (Join-Path $StageDir "*") `
        -DestinationPath $ZipFile


    if (-not (Test-Path $ZipFile -PathType Leaf))
    {
        throw "Package was not created: $ZipFile"
    }

    if ((Get-Item $ZipFile).Length -eq 0)
    {
        throw "Package was created but is empty: $ZipFile"
    }


    # --------------------------------------------------------
    # Verify ZIP contents
    # --------------------------------------------------------

    Write-Host "Verifying package contents..."

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $Archive =
        [System.IO.Compression.ZipFile]::OpenRead($ZipFile)

    try
    {
        $ActualZipFiles = @(
            $Archive.Entries |
                Where-Object { $_.Name -ne "" } |
                ForEach-Object {
                    $_.FullName.Replace("\", "/")
                }
        )

        $ExpectedSorted = @(
            $ExpectedZipFiles |
                Sort-Object
        )

        $ActualSorted = @(
            $ActualZipFiles |
                Sort-Object
        )

        $ContentsMatch =
            $ExpectedSorted.Count -eq $ActualSorted.Count

        if ($ContentsMatch)
        {
            for (
                $Index = 0;
                $Index -lt $ExpectedSorted.Count;
                $Index++
            )
            {
                if (
                    $ExpectedSorted[$Index] -ne
                    $ActualSorted[$Index]
                )
                {
                    $ContentsMatch = $false
                    break
                }
            }
        }

        if (-not $ContentsMatch)
        {
            $ExpectedText =
                $ExpectedSorted -join "`n  "

            $ActualText =
                $ActualSorted -join "`n  "

            throw @"
Package verification failed.

Expected:
  $ExpectedText

Found:
  $ActualText
"@
        }

        Write-Host "Package contents verified."


        # ----------------------------------------------------
        # Verify hashes directly from ZIP
        # ----------------------------------------------------

        Write-Host "Verifying package file hashes..."

        foreach ($File in $ExpectedZipFiles)
        {
            $Entry =
                $Archive.Entries |
                Where-Object {
                    $_.FullName.Replace("\", "/") -eq $File
                } |
                Select-Object -First 1

            if ($null -eq $Entry)
            {
                throw "ZIP entry not found: $File"
            }


            $Stream = $Entry.Open()

            try
            {
                $SHA256 =
                    [System.Security.Cryptography.SHA256]::Create()

                try
                {
                    $HashBytes =
                        $SHA256.ComputeHash($Stream)

                    $ZipHash =
                        [BitConverter]::ToString($HashBytes).
                            Replace("-", "")
                }
                finally
                {
                    $SHA256.Dispose()
                }
            }
            finally
            {
                $Stream.Dispose()
            }


            if ($ZipHash -ne $ExpectedHashes[$File])
            {
                throw @"
ZIP hash verification failed.

File:
  $File

Expected SHA-256:
  $($ExpectedHashes[$File])

ZIP SHA-256:
  $ZipHash
"@
            }
        }

        Write-Host "Package file hashes verified."
    }
    finally
    {
        $Archive.Dispose()
    }


    # --------------------------------------------------------
    # Success
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "Package created successfully:"
    Write-Host $ZipFile

    Write-Host ""
    Write-Host "SHA-256:"

    foreach ($File in $ExpectedZipFiles)
    {
        Write-Host `
            "$File  $($ExpectedHashes[$File])"
    }
}
catch
{
    # Never leave behind a package that failed verification.

    if (Test-Path $ZipFile)
    {
        Remove-Item `
            $ZipFile `
            -Force `
            -ErrorAction SilentlyContinue
    }

    throw
}
finally
{
    # Always remove temporary staging files.

    if (Test-Path $StageDir)
    {
        Remove-Item `
            $StageDir `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}
$PackageHash =
    (Get-FileHash `
        -Path $ZipFile `
        -Algorithm SHA256).Hash

Write-Host ""
Write-Host "Package SHA-256:"
Write-Host $PackageHash