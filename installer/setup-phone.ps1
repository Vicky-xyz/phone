param(
  [string]$AppDir,
  [switch]$Prereqs,
  [switch]$Apk,
  [switch]$Pause
)

$ErrorActionPreference = 'Continue'
$logDir = Join-Path $env:LOCALAPPDATA 'PhoneBox'
New-Item -ItemType Directory -Force $logDir | Out-Null
$log = Join-Path $logDir 'setup.log'

function Log([string]$m) {
  $line = "$(Get-Date -Format s)  $m"
  Write-Host $line
  Add-Content -Path $log -Value $line
}

function Get-Dotnet {
  $c = Get-Command dotnet -ErrorAction SilentlyContinue
  if ($c) { return $c.Source }
  $p = Join-Path $env:ProgramFiles 'dotnet\dotnet.exe'
  if (Test-Path $p) { return $p }
  return $null
}

function Has-DesktopRuntime10 {
  $d = Get-Dotnet
  if (-not $d) { return $false }
  return [bool]((& $d --list-runtimes 2>$null) -match '^Microsoft\.WindowsDesktop\.App 10\.')
}

function Find-Adb {
  $c = Get-Command adb -ErrorAction SilentlyContinue
  if ($c) { return $c.Source }
  $links = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\adb.exe'
  if (Test-Path $links) { return $links }
  $pk = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
  if (Test-Path $pk) {
    $hit = Get-ChildItem $pk -Directory -Filter 'Google.PlatformTools*' -ErrorAction SilentlyContinue |
      ForEach-Object { Get-ChildItem $_.FullName -Recurse -Filter adb.exe -ErrorAction SilentlyContinue } |
      Select-Object -First 1
    if ($hit) { return $hit.FullName }
  }
  $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
  if (Test-Path $sdk) { return $sdk }
  return $null
}

function Winget-Install([string]$id) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Log "winget is not available. Install $id manually."
    return
  }
  Log "Installing $id with winget..."
  winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements
  Log "winget exit code for ${id}: $LASTEXITCODE"
}

if ($Prereqs) {
  if (Has-DesktopRuntime10) { Log '.NET 10 Desktop Runtime: already installed.' }
  else { Winget-Install 'Microsoft.DotNet.DesktopRuntime.10' }

  if (Find-Adb) { Log 'adb: already installed.' }
  else { Winget-Install 'Google.PlatformTools' }
}

if ($Apk) {
  $apkPath = Join-Path $AppDir 'phone\PhoneBox.apk'
  $adb = Find-Adb
  if (-not (Test-Path $apkPath)) {
    Log "APK not found at $apkPath"
  } elseif (-not $adb) {
    Log 'adb was not found. Install Google.PlatformTools (winget install Google.PlatformTools), then use "Install phone app on connected phone" in the Start menu.'
  } else {
    & $adb start-server | Out-Null
    $serials = @(& $adb devices | ForEach-Object { if ($_ -match '^(\S+)\s+device$') { $Matches[1] } })
    if ($serials.Count -eq 0) {
      Log 'No phone found. Plug it in, turn on USB debugging, accept the prompt on the phone, then use "Install phone app on connected phone" in the Start menu.'
    }
    foreach ($s in $serials) {
      Log "Installing the phone app on $s ..."
      $out = & $adb -s $s install -r $apkPath 2>&1 | Out-String
      Log $out.Trim()
      if ($out -match 'INSTALL_FAILED_UPDATE_INCOMPATIBLE') {
        Log 'The phone has a copy signed with a different key. Uninstall PhoneBox on the phone (this resets its pairing) and run this again.'
      }
    }
  }
}

Log "Done. Log file: $log"
if ($Pause) { Read-Host 'Press Enter to close' | Out-Null } else { Start-Sleep -Seconds 4 }
