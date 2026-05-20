; Inno Setup script for InVan POS
; Compiled by GitHub Actions on Windows runner.
; Version is injected via /DMyAppVersion="..." flag from the workflow.

#define MyAppName "InVan POS"
#ifndef MyAppVersion
  #define MyAppVersion "1.1.100"
#endif
#define MyAppPublisher "Invan Soft"
#define MyAppExeName "invan2.exe"
#define MyAppURL "https://github.com/Invan-Soft/invan-pos"

[Setup]
AppId={{B3D9F5E8-1A2B-4C3D-9E4F-5A6B7C8D9E01}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\InVanPos2
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=installers
OutputBaseFilename={#MyAppVersion}
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64
WizardStyle=modern
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
