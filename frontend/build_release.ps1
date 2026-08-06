[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectDirectory = $PSScriptRoot
$pubspecPath       = Join-Path $projectDirectory 'pubspec.yaml'
$apkDirectory      = Join-Path $projectDirectory 'build\app\outputs\flutter-apk'
$utf8WithoutBom    = New-Object System.Text.UTF8Encoding($false)

# ── 1. Read current version from pubspec.yaml ─────────────────────────────────
$originalPubspec = [System.IO.File]::ReadAllText($pubspecPath)
$versionPattern  = '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$'
$versionMatch    = [regex]::Match($originalPubspec, $versionPattern)

if (-not $versionMatch.Success) {
    throw 'Could not find a version in pubspec.yaml using major.minor.patch+build format.'
}

$major       = [int]$versionMatch.Groups[1].Value
$minor       = [int]$versionMatch.Groups[2].Value + 1   # auto-increment minor
$buildNumber = [int]$versionMatch.Groups[4].Value + 1   # auto-increment versionCode
$versionName = "$major.$minor.0"
$displayVersion = "$major.$minor"                        # e.g.  1.6

# ── 2. Write incremented version back to pubspec.yaml ─────────────────────────
$nextVersion    = "version: $versionName+$buildNumber"
$updatedPubspec = [regex]::Replace($originalPubspec, $versionPattern, $nextVersion, 1)
[System.IO.File]::WriteAllText($pubspecPath, $updatedPubspec, $utf8WithoutBom)

try {
    # ── 3. Build all ABI splits ────────────────────────────────────────────────
    Write-Host ""
    Write-Host "========================================================"
    Write-Host "  BBT-ERP  v$displayVersion  (versionCode $buildNumber)"
    Write-Host "========================================================"
    Write-Host ""

    & flutter build apk --release --split-per-abi `
        --build-name $versionName `
        --build-number $buildNumber

    if ($LASTEXITCODE -ne 0) {
        throw "Flutter release build failed with exit code $LASTEXITCODE."
    }

    # ── 4. Rename output APKs to BBT-ERP-version.X.X format ──────────────────
    $abiMap = @{
        'app-arm64-v8a-release.apk'  = "BBT-ERP-version.$displayVersion-arm64.apk"
        'app-armeabi-v7a-release.apk'= "BBT-ERP-version.$displayVersion-armv7.apk"
        'app-x86_64-release.apk'     = "BBT-ERP-version.$displayVersion-x86_64.apk"
    }

    $produced = @()
    foreach ($entry in $abiMap.GetEnumerator()) {
        $src = Join-Path $apkDirectory $entry.Key
        if (Test-Path -LiteralPath $src) {
            $dst = Join-Path $apkDirectory $entry.Value
            Copy-Item -LiteralPath $src -Destination $dst -Force
            $produced += $entry.Value
        }
    }

    # ── 5. Summary ────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "Release complete!"
    Write-Host "  Version name  : $versionName"
    Write-Host "  Version code  : $buildNumber"
    Write-Host "  Output folder : $apkDirectory"
    Write-Host ""
    Write-Host "APKs produced:"
    foreach ($f in $produced | Sort-Object) {
        Write-Host "  $f"
    }
    Write-Host ""
    Write-Host "Recommended for most phones:"
    Write-Host "  BBT-ERP-version.$displayVersion-arm64.apk"
    Write-Host ""
}
catch {
    # Roll back pubspec.yaml on failure so the version isn't wasted.
    [System.IO.File]::WriteAllText($pubspecPath, $originalPubspec, $utf8WithoutBom)
    throw
}
