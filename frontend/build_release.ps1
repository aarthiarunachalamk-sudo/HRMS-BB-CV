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

    Set-Location $projectDirectory
    & flutter build apk --release --split-per-abi `
        --build-name $versionName `
        --build-number $buildNumber

    if ($LASTEXITCODE -ne 0) {
        throw "Flutter release build failed with exit code $LASTEXITCODE."
    }

    # ── 4. Rename arm64 APK to BBT-ERP-version.X.X.apk ───────────────────────
    $releaseApkName = "BBT-ERP-version.$displayVersion.apk"
    $src = Join-Path $apkDirectory 'app-arm64-v8a-release.apk'

    if (-not (Test-Path -LiteralPath $src)) {
        throw "arm64 release APK not found at: $src"
    }

    $dst = Join-Path $apkDirectory $releaseApkName
    Copy-Item -LiteralPath $src -Destination $dst -Force

    # ── 5. Summary ────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "Release complete!"
    Write-Host "  Version name  : $versionName"
    Write-Host "  Version code  : $buildNumber"
    Write-Host "  Output folder : $apkDirectory"
    Write-Host ""
    Write-Host "Release APK:"
    Write-Host "  $releaseApkName"
    Write-Host ""
}
catch {
    # Roll back pubspec.yaml on failure so the version isn't wasted.
    [System.IO.File]::WriteAllText($pubspecPath, $originalPubspec, $utf8WithoutBom)
    throw
}
