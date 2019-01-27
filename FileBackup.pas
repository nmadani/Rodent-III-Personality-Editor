unit FileBackup;

interface

uses
  Windows,
  System.SysUtils,
  System.Classes;

type
  TFileBackup = class
  private
    fFileName: string;
    fBackupFileName: string;
    fSuccess: Boolean;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    property BackupName: string read fBackupFileName;
    property Success: Boolean read fSuccess;
  end;

implementation

{ TFileBackup }

constructor TFileBackup.Create(const AFileName: string);
var
  BackupName: string;
  lFilePath: string;
  lFileName: string;
  lExt: string;
begin
  if FileExists(AFileName) then
  begin
    lFilePath := ExtractFilePath(AFileName);
    lExt := ExtractFileExt(AFileName);
    lFileName := ExtractFileName(AFileName);
    lFileName := lFileName.Substring(0, lFileName.Length - lExt.Length);
    BackupName := AFileName;
    while FileExists(BackupName) do
    begin
      BackupName := lFilePath + lFileName + '.' + FormatDateTime('yyyymmddhhnnss', Now) + lExt;
    end;
    fSuccess := CopyFile(PChar(AFileName), PChar(BackupName), True);
  end;
end;

destructor TFileBackup.Destroy;
begin
  fFileName := '';
  fBackupFileName := '';
  inherited;
end;

end.
