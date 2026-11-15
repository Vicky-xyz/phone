#ifndef Version
  #define Version "0.0.0"
#endif

[Setup]
AppId={{B7C3F6C2-5D41-4C8A-9E5B-6F1A2D3E4A10}
AppName=PhoneBox
AppVersion={#Version}
AppPublisher=PhoneBox (packaged installer)
DefaultDirName={localappdata}\PhoneBox\app
DefaultGroupName=PhoneBox
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\output
OutputBaseFilename=PhoneBox-Setup-{#Version}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\PhoneBoxAgent.exe
InfoBeforeFile=NOTICE.txt

[Tasks]
Name: "desktopicon"; Description: "Create desktop shortcuts"
Name: "autostart"; Description: "Start PhoneBox when Windows starts"
Name: "prereqs"; Description: "Install missing prerequisites with winget (.NET 10 Desktop Runtime and adb)"
Name: "phoneapp"; Description: "Install the phone app on a connected Android phone (USB debugging must be on)"

[Files]
Source: "..\stage\agent\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\stage\PhoneBox.apk"; DestDir: "{app}\phone"; Flags: ignoreversion
Source: "setup-phone.ps1"; DestDir: "{app}\phone"; Flags: ignoreversion

[Icons]
Name: "{autodesktop}\PhoneBox"; Filename: "{app}\PhoneBoxAgent.exe"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{autodesktop}\PhoneBox Settings"; Filename: "msedge.exe"; Parameters: "--app=http://127.0.0.1:8765"; Tasks: desktopicon
Name: "{userstartup}\PhoneBox"; Filename: "{app}\PhoneBoxAgent.exe"; WorkingDir: "{app}"; Tasks: autostart
Name: "{group}\PhoneBox"; Filename: "{app}\PhoneBoxAgent.exe"; WorkingDir: "{app}"
Name: "{group}\PhoneBox Settings"; Filename: "msedge.exe"; Parameters: "--app=http://127.0.0.1:8765"
Name: "{group}\Install phone app on connected phone"; Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\phone\setup-phone.ps1"" -AppDir ""{app}"" -Apk -Pause"

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\phone\setup-phone.ps1"" -AppDir ""{app}""{code:PhoneArgs}"; StatusMsg: "Setting up the phone..."; Flags: waituntilterminated; Check: AnyPhoneTask
Filename: "{app}\PhoneBoxAgent.exe"; WorkingDir: "{app}"; Description: "Start PhoneBox now"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "taskkill.exe"; Parameters: "/F /IM PhoneBoxAgent.exe"; Flags: runhidden; RunOnceId: "StopAgent"

[Code]
function AnyPhoneTask: Boolean;
begin
  Result := WizardIsTaskSelected('prereqs') or WizardIsTaskSelected('phoneapp');
end;

function PhoneArgs(Param: string): string;
begin
  Result := '';
  if WizardIsTaskSelected('prereqs') then Result := Result + ' -Prereqs';
  if WizardIsTaskSelected('phoneapp') then Result := Result + ' -Apk';
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  R: Integer;
begin
  Exec('taskkill.exe', '/F /IM PhoneBoxAgent.exe', '', SW_HIDE, ewWaitUntilTerminated, R);
  Sleep(800);
  Result := '';
end;
