; Build with Inno Setup 6: https://jrsoftware.org/isinfo.php
; Open this file in Inno Setup Compiler and click Build (or ISCC.exe TrackerTracker.iss).

#define MyAppName "Tracker Tracker"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "bermicha"
#define MyAppURL "https://github.com/bermicha/trackerTracker"

[Setup]
AppId={{A7B2C9E1-4F3D-4A1B-9E8C-112233445566}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={localappdata}\TrackerTracker
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=.
OutputBaseFilename=TrackerTracker-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\manifest.json"; DestDir: "{app}\extension"; Flags: ignoreversion
Source: "..\background.js"; DestDir: "{app}\extension"; Flags: ignoreversion
Source: "..\content.js"; DestDir: "{app}\extension"; Flags: ignoreversion
Source: "..\content.css"; DestDir: "{app}\extension"; Flags: ignoreversion
Source: "..\blocked-pixel.png"; DestDir: "{app}\extension"; Flags: ignoreversion
Source: "..\lib\*"; DestDir: "{app}\extension\lib"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\rules\*"; DestDir: "{app}\extension\rules"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\icons\*"; DestDir: "{app}\extension\icons"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName} (Chrome)"; Filename: "{code:GetChromeExe}"; Parameters: "--load-extension=""{app}\extension"""; Comment: "Launch Chrome with Tracker Tracker loaded"
Name: "{autodesktop}\{#MyAppName} (Chrome)"; Filename: "{code:GetChromeExe}"; Parameters: "--load-extension=""{app}\extension"""; Comment: "Launch Chrome with Tracker Tracker loaded"

[Code]
function GetChromeExe(Dummy: string): string;
begin
  if FileExists(ExpandConstant('{pf}\Google\Chrome\Application\chrome.exe')) then
    Result := ExpandConstant('{pf}\Google\Chrome\Application\chrome.exe')
  else if FileExists(ExpandConstant('{pf32}\Google\Chrome\Application\chrome.exe')) then
    Result := ExpandConstant('{pf32}\Google\Chrome\Application\chrome.exe')
  else if FileExists(ExpandConstant('{localappdata}\Google\Chrome\Application\chrome.exe')) then
    Result := ExpandConstant('{localappdata}\Google\Chrome\Application\chrome.exe')
  else
    Result := ExpandConstant('{pf}\Google\Chrome\Application\chrome.exe');
end;

[UninstallDelete]
Type: filesandordirs; Name: "{app}\extension"
