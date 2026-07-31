[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectDirectory = $PSScriptRoot
$pubspecPath = Join-Path $projectDirectory 'pubspec.yaml'
$apkDirectory = Join-Path $projectDirectory 'build\app\outputs\flutter-apk'
$flutterApkPath = Join-Path $apkDirectory 'app-release.apk'
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

$originalPubspec = [System.IO.File]::ReadAllText($pubspecPath)
$versionPattern = '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$'
$versionMatch = [regex]::Match($originalPubspec, $versionPattern)

if (-not $versionMatch.Success) {
    throw 'Could not find a version in pubspec.yaml using major.minor.patch+build format.'
}

$major = [int]$versionMatch.Groups[1].Value
$minor = [int]$versionMatch.Groups[2].Value + 1
$buildNumber = [int]$versionMatch.Groups[4].Value + 1
$versionName = "$major.$minor.0"
$displayVersion = "$major.$minor"
$nextVersion = "version: $versionName+$buildNumber"
$updatedPubspec = [regex]::Replace(
    $originalPubspec,
    $versionPattern,
    $nextVersion,
    1
)

[System.IO.File]::WriteAllText($pubspecPath, $updatedPubspec, $utf8WithoutBom)

try {
    Write-Host "Building BBT HRMS $displayVersion (Android build $buildNumber)..."
    & flutter build apk --release --build-name $versionName --build-number $buildNumber
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter release build failed with exit code $LASTEXITCODE."
    }

    if (-not (Test-Path -LiteralPath $flutterApkPath)) {
        throw "Flutter completed without producing $flutterApkPath."
    }

    $versionedApkPath = Join-Path $apkDirectory "BBT-HRMS-version $displayVersion.apk"
    Copy-Item -LiteralPath $flutterApkPath -Destination $versionedApkPath -Force

    Write-Host "Release complete: $versionedApkPath"
    Write-Host "App version: $versionName | Android versionCode: $buildNumber"
}
catch {
    [System.IO.File]::WriteAllText($pubspecPath, $originalPubspec, $utf8WithoutBom)
    throw
}
