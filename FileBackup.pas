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
    fSaveFileName: string;
    fSuccess: Boolean;
    function GetDateAndTime: string;
    procedure SetFileNames(const AFileName: string);
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    property SaveFileName: string read fSaveFileName;
    property BackupName: string read fBackupFileName;
    property Success: Boolean read fSuccess;
  end;

implementation

uses
  RegularExpressions,
  RegularExpressionsCore;

const
  CRegexDatePartName = 'datepart';
  CRegexDatePart = '.*(?<' + CRegexDatePartName + '>\d{4}-\d{2}-\d{2}_\d{6}).*';
  CDateFDormat = 'yyyy-mm-dd_hhnnss';

{ TFileBackup }

constructor TFileBackup.Create(const AFileName: string);
begin
  SetFileNames(AFileName);
  fSuccess := AFileName.Equals(fBackupFileName); // backup file already exists
  if fSuccess = False then  // Backup file does not exist
    fSuccess := CopyFile(PChar(AFileName), PChar(fBackupFileName), True);
end;

destructor TFileBackup.Destroy;
begin
  fFileName := '';
  fBackupFileName := '';
  inherited;
end;

function TFileBackup.GetDateAndTime: string;
begin
  Result := FormatDateTime(CDateFDormat, Now);
end;

procedure TFileBackup.SetFileNames(const AFileName: string);
var
  lFilePath: string;
  lFileName: string;
  lExt: string;
  Match: TMatch;
begin
  if FileExists(AFileName) then
  begin
    lFilePath := ExtractFilePath(AFileName);
    lExt := ExtractFileExt(AFileName);
    lFileName := ExtractFileName(AFileName);
    lFileName := lFileName.Substring(0, lFileName.Length - lExt.Length);
    try
      Match := TRegEx.Match(lFileName, CRegexDatePart, [roNotEmpty]);
    except on E: ERegularExpressionError do
      raise Exception.Create('Regular expression exception!'); // very creative ;-)
    end;
    if Match.Success then
    begin
      // The file has backup time stamp:
      fBackupFileName := AFileName;
      repeat
        fSaveFileName := lFilePath +
          lFileName.Replace(Match.Groups[CRegexDatePartName].Value, GetDateAndTime) + lExt;
      until (FileExists(fSaveFileName) = False);
    end
    else
    begin
      repeat
        fBackupFileName := lFilePath + lFileName + '.' + GetDateAndTime + lExt;
      until (FileExists(fBackupFileName) = False);
      fSaveFileName := AFileName;
    end
  end
  else
    raise Exception.Create('Invalid file: ' + AFileName);
end;

end.
