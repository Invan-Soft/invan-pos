; Inno Setup script for INVAN 2
; Compiled by GitHub Actions on Windows runner.
; Version is injected via /DMyAppVersion="..." flag from the workflow.

#define MyAppName "INVAN 2"
#ifndef MyAppVersion
  #define MyAppVersion "1.1.100"
#endif
#define MyAppPublisher "Invan Soft"
#define MyAppExeName "pos_desktop_flutter.exe"
#define MyAppURL "https://github.com/Invan-Soft/invan-pos"

[Setup]
AppId={{79533c12-cc3a-4d69-8f13-b0cd39959206}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\INVAN 2
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
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{userdesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
