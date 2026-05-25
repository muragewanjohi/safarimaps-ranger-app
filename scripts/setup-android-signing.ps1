# Sets up Android release signing for the Flutter app using the EAS upload keystore.
#
# Usage:
#   1) Download keystore (interactive EAS menu):
#        .\scripts\setup-android-signing.ps1 -Download
#      Or download from:
#        https://expo.dev/accounts/murage/projects/safarimap-gamewarden/credentials?platform=android
#
#   2) Best if you don't know passwords — download credentials.json from EAS (includes passwords):
#        cd apps/safarimaps-ranger
#        npx eas-cli credentials -p android
#        -> production -> credentials.json -> Download credentials from EAS to credentials.json
#        cd ../ranger
#        .\scripts\setup-android-signing.ps1 -FromCredentialsJson
#
#   3) Or configure manually if you already have the .jks and passwords:
#        .\scripts\setup-android-signing.ps1 -Configure `
#          -KeystorePath "C:\path\to\downloaded.jks" `
#          -KeyAlias "your-alias" `
#          -StorePassword "your-store-password" `
#          -KeyPassword "your-key-password"

param(
    [switch]$Download,
    [switch]$Configure,
    [switch]$FromCredentialsJson,
    [string]$CredentialsJsonPath,
    [string]$KeystorePath,
    [string]$KeyAlias,
    [string]$StorePassword,
    [string]$KeyPassword
)

$ErrorActionPreference = "Stop"
$RangerRoot = Split-Path $PSScriptRoot -Parent
$RnRoot = Join-Path (Split-Path $RangerRoot -Parent) "safarimaps-ranger"
$AndroidDir = Join-Path $RangerRoot "android"
$TargetKeystore = Join-Path $AndroidDir "upload-keystore.jks"
$KeyProperties = Join-Path $AndroidDir "key.properties"
$ExpoCredentialsUrl = "https://expo.dev/accounts/murage/projects/safarimap-gamewarden/credentials?platform=android"

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Ensure-EasLogin {
    Write-Step "Checking Expo login"
    Push-Location $RnRoot
    try {
        $whoami = npx --yes eas-cli@latest whoami 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Not logged in to Expo. Run: npx eas-cli login"
        }
        Write-Host $whoami
    } finally {
        Pop-Location
    }
}

function Start-Download {
    Ensure-EasLogin

    Write-Step "Download the upload keystore"
    Write-Host "Option A (recommended): open Expo credentials in your browser:"
    Write-Host "  $ExpoCredentialsUrl"
    Write-Host ""
    Write-Host "  Android -> Application identifier -> Keystore -> Download"
    Write-Host ""
    Write-Host "Option B: download credentials.json (includes passwords + keystore path):"
    Write-Host "  cd apps/safarimaps-ranger"
    Write-Host "  npx eas-cli credentials -p android"
    Write-Host "  -> production"
    Write-Host "  -> credentials.json: Upload/Download credentials..."
    Write-Host "  -> Download credentials from EAS to credentials.json"
    Write-Host "  cd ../ranger"
    Write-Host "  .\scripts\setup-android-signing.ps1 -FromCredentialsJson"
    Write-Host ""
    Write-Host "Option C: interactive keystore download only (passwords not included):"
    Write-Host "  cd apps/safarimaps-ranger"
    Write-Host "  npx eas-cli credentials -p android"
    Write-Host "  -> production -> Keystore -> Download existing keystore"
    Write-Host ""

    $open = Read-Host "Open Expo credentials page in browser now? [Y/n]"
    if ($open -ne "n" -and $open -ne "N") {
        Start-Process $ExpoCredentialsUrl
    }

    $runCli = Read-Host "Run interactive EAS credentials CLI now? [y/N]"
    if ($runCli -eq "y" -or $runCli -eq "Y") {
        Push-Location $RnRoot
        try {
            npx --yes eas-cli@latest credentials -p android
        } finally {
            Pop-Location
        }
    }

    Write-Host ""
    Write-Host "After download, run Configure with your keystore path and passwords."
    Write-Host "Example:"
    Write-Host "  .\scripts\setup-android-signing.ps1 -Configure \"
    Write-Host "    -KeystorePath `"C:\Users\You\Downloads\keystore.jks`" \"
    Write-Host "    -KeyAlias `"upload`" \"
    Write-Host "    -StorePassword `"***`" \"
    Write-Host "    -KeyPassword `"***`""
}

function Start-FromCredentialsJson {
    if (-not $CredentialsJsonPath) {
        $CredentialsJsonPath = Join-Path $RnRoot "credentials.json"
    }
    if (-not (Test-Path $CredentialsJsonPath)) {
        throw "credentials.json not found at $CredentialsJsonPath. Download it from EAS first."
    }

    Write-Step "Reading $CredentialsJsonPath"
    $json = Get-Content $CredentialsJsonPath -Raw | ConvertFrom-Json
    $ks = $json.android.keystore

    $resolvedKeystore = $ks.keystorePath
    if (-not [System.IO.Path]::IsPathRooted($resolvedKeystore)) {
        $resolvedKeystore = Join-Path $RnRoot $resolvedKeystore
    }
    if (-not (Test-Path $resolvedKeystore)) {
        throw "Keystore file from credentials.json not found: $resolvedKeystore"
    }

    Start-Configure `
        -KeystorePath $resolvedKeystore `
        -KeyAlias $ks.keyAlias `
        -StorePassword $ks.keystorePassword `
        -KeyPassword $ks.keyPassword
}

function Start-Configure {
    if (-not $KeystorePath) {
        $KeystorePath = Read-Host "Path to downloaded .jks keystore"
    }
    if (-not (Test-Path $KeystorePath)) {
        throw "Keystore not found: $KeystorePath"
    }

    if (-not $KeyAlias) {
        $KeyAlias = Read-Host "Key alias (shown by EAS when keystore was created)"
    }
    if (-not $StorePassword) {
        $StorePassword = Read-Host "Keystore password" -AsSecureString
        $StorePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($StorePassword)
        )
    }
    if (-not $KeyPassword) {
        $KeyPassword = Read-Host "Key password (often same as keystore password)" -AsSecureString
        $KeyPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($KeyPassword)
        )
    }

    Write-Step "Copying keystore to android/upload-keystore.jks"
    Copy-Item -Path $KeystorePath -Destination $TargetKeystore -Force

    Write-Step "Writing android/key.properties"
    @(
        "storePassword=$StorePassword"
        "keyPassword=$KeyPassword"
        "keyAlias=$KeyAlias"
        "storeFile=../upload-keystore.jks"
    ) | Set-Content -Path $KeyProperties -Encoding Ascii

    Write-Step "Keystore certificate fingerprints (add release SHA-1 to Google Maps API key)"
    $keytool = "keytool"
    if ($env:JAVA_HOME) {
        $candidate = Join-Path $env:JAVA_HOME "bin\keytool.exe"
        if (Test-Path $candidate) { $keytool = $candidate }
    }
    & $keytool -list -v -keystore $TargetKeystore -alias $KeyAlias -storepass $StorePassword 2>&1 |
        Select-String -Pattern "SHA1:|SHA256:"

    Write-Host ""
    Write-Host "Release signing configured." -ForegroundColor Green
    Write-Host "Next:"
    Write-Host "  cd apps/ranger"
    Write-Host "  flutter build appbundle --dart-define-from-file=env.json"
}

if ($FromCredentialsJson) {
    Start-FromCredentialsJson
    exit 0
}

if ($Download) {
    Start-Download
    exit 0
}

if ($Configure) {
    Start-Configure
    exit 0
}

Write-Host "Android release signing setup"
Write-Host ""
Write-Host "  -Download    Open Expo / run EAS credentials to fetch keystore"
Write-Host "  -FromCredentialsJson  Use apps/safarimaps-ranger/credentials.json from EAS (has passwords)"
Write-Host "  -Configure            Copy keystore + write android/key.properties manually"
Write-Host ""
Write-Host "Typical flow:"
Write-Host "  .\scripts\setup-android-signing.ps1 -Download"
Write-Host "  .\scripts\setup-android-signing.ps1 -Configure -KeystorePath ... -KeyAlias ... -StorePassword ... -KeyPassword ..."
