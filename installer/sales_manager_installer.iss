#ifndef MyAppVersion
#define MyAppVersion "1.0.0"
#endif

[Setup]
; AppId فريد لتطبيق مدير المبيعات والمخزون
AppId={{9C4D3E2F-7A1B-4E5C-8F9D-1A2B3C4D5E6F}
AppName=مدير المبيعات والمخزون
AppVersion={#MyAppVersion}
AppPublisher=Sales Manager
; التثبيت في LocalAppData حتى يتمكن نظام التحديث التلقائي من استبدال الملفات دون صلاحيات Admin
DefaultDirName={localappdata}\SalesManager
DisableProgramGroupPage=yes
OutputDir=.\Output
OutputBaseFilename=SalesManager_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; يشترط نظام ويندوز 10 أو 11 بمعمارية 64-بت
MinVersion=10.0
CloseApplications=yes

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\windows\x64\runner\Release\sales_manager.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\مدير المبيعات والمخزون"; Filename: "{app}\sales_manager.exe"
Name: "{autodesktop}\مدير المبيعات والمخزون"; Filename: "{app}\sales_manager.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\sales_manager.exe"; Description: "{cm:LaunchProgram,مدير المبيعات والمخزون}"; Flags: nowait postinstall; Check: IsNotSilent
Filename: "{app}\sales_manager.exe"; Flags: nowait; Check: IsSilentInstall

[Code]
function IsNotSilent(): Boolean;
begin
  Result := not WizardSilent();
end;

function IsSilentInstall(): Boolean;
begin
  Result := WizardSilent();
end;

function InitializeSetup(): Boolean;
var
  FreeMB, TotalMB: Cardinal;
  DriveRoot: String;
begin
  Result := True;
  
  // استخراج جذر القرص المحدد للتثبيت (مثل C:\)
  DriveRoot := AddBackslash(ExtractFileDrive(ExpandConstant('{localappdata}')));
  if Length(DriveRoot) <= 1 then
    DriveRoot := 'C:\';

  // فحص المساحة الشاغرة (الحد الأدنى 2048 ميجابايت = 2 جيجابايت) لحماية نظام التشغيل من الانهيار
  if GetSpaceOnDisk(DriveRoot, True, FreeMB, TotalMB) then
  begin
    if FreeMB < 2048 then
    begin
      SuppressibleMsgBox(
        '⚠️ تحذير أمان التثبيت (مساحة القرص منخفضة جداً):' + #13#10#13#10 +
        'المساحة المتبقية على القرص (' + DriveRoot + ') هي: ' + IntToStr(FreeMB) + ' ميجابايت فقط.' + #13#10#13#10 +
        'لحماية نظام التشغيل Windows من التوقف أو البطء الشديد، وضمان عمل قاعدة البيانات بأمان،' + #13#10 +
        'يشترط توفر مساحة فارغة لا تقل عن 2048 ميجابايت (2 جيجابايت).' + #13#10#13#10 +
        'يرجى تفريغ مساحة من القرص أولاً ثم إعادة تشغيل التثبيت.',
        mbCriticalError, MB_OK, MB_OK);
      Result := False;
      Exit;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssInstall then
  begin
    Exec('taskkill.exe', '/f /im sales_manager.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;
