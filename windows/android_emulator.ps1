# Powershell7 Script

# Variables
# $PSNativeCommandUseErrorActionPreference = $true
$ErrorActionPreference = 'Stop'
$JDK_ID = "Microsoft.OpenJDK.21"
$JAVA_HOME = "C:\Program Files\Microsoft\jdk-21.0.9.10-hotspot"
$ANDROID_HOME = "$HOME\.android"
$SDK_HOME_URL = "https://developer.android.com/studio#command-tools"
$EMULATOR = "emulator"


# Step 1
Write-Host "Step 1: " -NoNewline
Write-Host "Installing JDK 21" -ForegroundColor Green
winget install $JDK_ID


# Step 2
Write-Host "Step 2: " -NoNewline
Write-Host "Setting JAVA_HOME environment variable" -ForegroundColor Green
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $JAVA_HOME, "User")


# Step 3
Write-Host "Step 3: " -NoNewline
Write-Host "Downloading Latest Android SDK Tools" -ForegroundColor Green
$content = (Invoke-WebRequest -Uri $SDK_HOME_URL -UseBasicParsing).Content
$pattern = "https://dl.google.com/android/repository/commandlinetools-win-[0-9]+_latest.zip"
$SDK_DOWNLOAD_URL = [regex]::Match($content, $pattern).Value
if (-not $SDK_DOWNLOAD_URL) {
    Write-Host "`nERROR: Failed to fetch the SDK Download URL." -ForegroundColor Red
    exit
}
$temp_zip = Join-Path $env:TEMP "android_sdk_tools.zip"
Invoke-WebRequest -Uri $SDK_DOWNLOAD_URL -OutFile $temp_zip
Expand-Archive -Path $temp_zip -DestinationPath $ANDROID_HOME -Force
Remove-Item -Path $temp_zip

$cmdline_tools_base = Join-Path $ANDROID_HOME "cmdline-tools"
$cmdline_tools_latest = Join-Path $cmdline_tools_base "latest"
Remove-Item -Path $cmdline_tools_latest -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path $cmdline_tools_latest -Force | Out-Null
Get-ChildItem -Path $cmdline_tools_base | Where-Object {
    $_.Name -ne "latest"
} | Move-Item -Destination $cmdline_tools_latest -Force


# Step 4
Write-Host "Step 4: " -NoNewline
Write-Host "Setting ANDROID_HOME environment variable" -ForegroundColor Green
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $ANDROID_HOME, "User")


# Step 5
Write-Host "Step 5: " -NoNewline
Write-Host "Updating User PATH environment variable" -ForegroundColor Green
function Update-UserPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PathToAdd
    )
    $path = $env:Path -split ';'
    if ($path -notcontains $PathToAdd) {
        $current_path = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $updated_path = "$current_path;$PathToAdd"
        [System.Environment]::SetEnvironmentVariable("Path", $updated_path, "User")
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") +
                ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

Update-UserPath -PathToAdd (Join-Path $JAVA_HOME "bin")
Update-UserPath -PathToAdd (Join-Path $cmdline_tools_latest "bin")
Update-UserPath -PathToAdd (Join-Path $ANDROID_HOME "platform-tools")
Update-UserPath -PathToAdd (Join-Path $ANDROID_HOME "emulator")


# Step 6
Write-Host "Step 6: " -NoNewline
Write-Host "Agreeing SDK Manager licenses" -ForegroundColor Green
("y`n" * 20) | sdkmanager --licenses


# Step 7
Write-Host "Step 7: " -NoNewline
Write-Host "Downloading required packages" -ForegroundColor Green
function Install-SdkManagerPackage {
    param (
        [Parameter(Mandatory)]
        [string]$Package
    )

    Write-Host "`t• $Package" -ForegroundColor Blue
    $installed = sdkmanager --list_installed 2>$null |
                 Select-String -SimpleMatch $Package -Quiet
    if (-not $installed) {
        sdkmanager --install $Package
    }
}

Install-SdkManagerPackage "build-tools;35.0.0"
Install-SdkManagerPackage "emulator"
Install-SdkManagerPackage "platform-tools"
Install-SdkManagerPackage "platforms;android-35"
Install-SdkManagerPackage "system-images;android-35;google_apis;x86_64"


# Step 8
Write-Host "Step 8: " -NoNewline
Write-Host "Creating an AVD - $EMULATOR" -ForegroundColor Green
$avd_exists = avdmanager list avd 2>&1 | Select-String -SimpleMatch $EMULATOR -Quiet
$avd_config = Join-Path $ANDROID_HOME "avd\$EMULATOR.avd\config.ini"
if (-not $avd_exists) {
    avdmanager create avd -f -n $EMULATOR `
        -k "system-images;android-35;google_apis;x86_64" `
        -d "pixel_9_pro"
    
    $avd_config = Join-Path $ANDROID_HOME "avd\$EMULATOR.avd\config.ini"
    $content = Get-Content $avd_config
    $content = $content -replace '^hw\.keyboard=no', 'hw.keyboard=yes'
    Set-Content -Path $avd_config -Value $content
}

Write-Host "`nOperation Complete"
