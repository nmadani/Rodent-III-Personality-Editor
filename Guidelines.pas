unit Guidelines;

interface

uses
	Windows,
	ShLwApi,
	System.SysUtils,
	System.Classes,
	System.Generics.Collections,
	FireDAC.Comp.Client,
	FireDAC.Comp.DataSet,
	FireDAC.Comp.UI,
	FireDAC.Phys.Intf,
	FireDAC.Phys,
	FireDAC.Phys.SQLite,
	FireDAC.Phys.SQLiteDef,
	FireDAC.Stan.Async,
	FireDAC.Stan.Def,
	FireDAC.Stan.Error,
	FireDAC.Stan.ExprFuncs,
	FireDAC.Stan.Intf,
	FireDAC.Stan.Option,
	FireDAC.Stan.Param,
	FireDAC.Stan.Pool,
	FireDAC.DApt,
	FireDAC.UI.Intf,
	FireDAC.VCLUI.Wait,
{$IFDEF FireDACMonitor}
	FireDAC.Moni.RemoteClient,
{$ENDIF}
	Data.DB, Vcl.Graphics;

type
  TGuideline = class
  private
    fOptionName: string;
    fDefaultValue: string;
    fGuideline: string;
  public
    constructor Create(const OptName, DefValue, GLn: string);
    destructor Destroy; override;
    property OptionName: string read fOptionName;
    property DefaultValue: string read fDefaultValue;
    property Guideline: string read fGuideline;
  end;

  TGuidelines = class
  private
    fGuideLines: TObjectList<TGuideline>;
    function GetCount: Integer;
    function GetOption(Index: integer): string;
    function GetDefaultValue(Index: integer): string;
    function GetGuideline(Option: string): string; overload;
    procedure LoadDatabase;
  public
    constructor Create;
    destructor Destroy; override;
    function GetMaxOptionWidth(const Canvas: TCanvas): Integer;
    property Guideline[Option: string]: string read GetGuideline; default;
    property Count: Integer read GetCount;
    property Option[Index: Integer]: string read GetOption;
    property DefaultValue[Index: Integer]: string read GetDefaultValue;
  end;

var
	gGuidelines: TGuidelines;

implementation

const
	CSQLitePooledName = 'SQLitePooled';
	CSQLiteDriverName = 'SQLite';
	CDatabaseName = 'RodentIIIOptions.db3';

var
	lDatabaseName: string;
	SQLiteConnectionPool: TFDManager;
	oParams: TStrings;
{$IFDEF FireDACMonitor}
	MoniLink: TFDMoniRemoteClientLink;
{$ENDIF}



{ TGuidelines }

constructor TGuidelines.Create;
begin
  fGuideLines := TObjectList<TGuideline>.Create(True);
  LoadDatabase;
end;

destructor TGuidelines.Destroy;
begin
  fGuideLines.Free;
  inherited;
end;

function TGuidelines.GetCount: Integer;
begin
  Result := fGuideLines.Count;
end;

function TGuidelines.GetDefaultValue(Index: integer): string;
begin
  if (Index < 0) or (Index >= fGuideLines.Count) then
    raise EArgumentOutOfRangeException.Create('Index out of bounds');
  Result := fGuideLines[Index].fDefaultValue;
end;

function TGuidelines.GetGuideline(Option: string): string;
var
  gl: TGuideline;
begin
  Result := '';
  for gl in fGuideLines do
  begin
    if gl.OptionName = Option then
      Exit(gl.Guideline);
  end;
end;

function TGuidelines.GetMaxOptionWidth(const Canvas: TCanvas): Integer;
var
  i: Integer;
  MaxWidth: Integer;
begin
  if Canvas = nil then
    raise Exception.Create('Nil Canvas reference.');
  Result := 0;
  for i := 0 to fGuideLines.Count - 1 do
  begin
    MaxWidth := Canvas.TextWidth(fGuideLines[i].fOptionName);
    if MaxWidth > Result then
      Result := MaxWidth;
  end;
end;

function TGuidelines.GetOption(Index: integer): string;
begin
  if (Index < 0) or (Index >= fGuideLines.Count) then
    raise EArgumentOutOfRangeException.Create('Index out of bounds');
  Result := fGuideLines[Index].fOptionName;
end;

procedure TGuidelines.LoadDatabase;
var
  lConn: TFDConnection;
  lTable: TFDTable;
begin
  lTable := nil;
  lConn := TFDConnection.Create(nil);
  try
    lConn.ConnectionDefName := CSQLitePooledName;
    lTable := TFDTable.Create(nil);
    lTable.Connection := lConn;
    lTable.Open('options');
    lTable.First;
    while not lTable.Eof do
    begin
      fGuideLines.Add(TGuideline.Create(
        lTable.Fields[1].AsString,
        lTable.Fields[2].AsString,
        lTable.Fields[3].AsString
      ));
      lTable.Next;
    end;
  finally
    lTable.Free;
    lConn.Free;
  end;
end;

{ TGuideline }

constructor TGuideline.Create(const OptName, DefValue, GLn: string);
begin
	fOptionName := OptName;
	fDefaultValue := DefValue;
	fGuideline := GLn;
end;

destructor TGuideline.Destroy;
begin
	fOptionName := '';
	fDefaultValue := '';
	fGuideline := '';
	inherited;
end;

// Credit to:
// https://stackoverflow.com/questions/5329472/conversion-between-absolute-and-relative-paths-in-delphi
function RelativeToAbsolutePath(const RelativePath, BasePath: string): string;
var
	Destination: array[0..MAX_PATH-1] of char;
begin
	PathCanonicalize(@Destination[0], PChar(IncludeTrailingBackslash(BasePath) + RelativePath));
	result := Destination;
end;

initialization
{$IFDEF FireDACMonitor}
	MoniLink := TFDMoniRemoteClientLink.Create(nil);
	MoniLink.Tracing := True;
{$ENDIF}

{ TODO -oNM -cImplementation : Ensure database is accessible and handle gracefully if not }
oParams := TSTringList.Create;
	try
		oParams.Add('DriverID=SQLite');
{$IFDEF DEBUG}
		lDatabaseName := RelativeToAbsolutePath('..\..\Db',
												ExtractFilePath(System.ParamStr(0))) + PathDelim + CDatabaseName;
{$ELSE}
		lDatabaseName := CDatabaseName;
{$ENDIF}
		oParams.Add('Database=' + lDatabaseName);
{$IFDEF FireDACMonitor}
		oParams.Add('MonitorBy=Remote');
{$ENDIF}
		oParams.Add('Pooled=True');
		oParams.Add('LockingMode=Normal');
		oParams.Add('Synchronous=Full');
		oParams.Add('UpdateOptions.LockWait=True');
		oParams.Add('BusyTimeout=10000');
		oParams.Add('JournalMode=WAL');
		oParams.Add('SharedCache=False');
		oParams.Add('BusyTimeout=Normal');
		oParams.Add('TxOptions.Isolation=xiSnapshot');
		SQLiteConnectionPool := TFDManager.Create(nil);
		SQLiteConnectionPool.AddConnectionDef(CSQLitePooledName, CSQLiteDriverName, oParams);
	finally
		oParams.Free;
	end;

	gGuidelines := TGuidelines.Create;

finalization
	gGuidelines.Free;

	SQLiteConnectionPool.Free;
{$IFDEF FireDACMonitor}
	MoniLink.Free;
{$ENDIF}
end.
