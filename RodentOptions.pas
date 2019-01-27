unit RodentOptions;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  RegularExpressions,
  RegularExpressionsCore, Vcl.Graphics, Vcl.Controls;

type
  ROption = record
    Option: string;
    Value: string;
  public
    constructor Create(const aOption, aValue: string);
  end;

  TOptionArray = array of ROption;

  IRodentOptions = interface
  ['{EF928B5F-DD9E-4235-B073-384AC1FBE0C8}']
    function GetCount: Integer;
    function GetComments: string;
    function GetOptions: TOptionArray;
    function Save(const AFileName: string): Boolean;
    procedure SetComments(const Value: string); stdcall;
    property Count: Integer read GetCount;
    property Comments: string read GetComments write SetComments;
    property Options: TOptionArray read GetOptions;
  end;

  TRodentOptions = class(TInterfacedObject, IRodentOptions)
  private
    fOptions: TOptionArray;
    fHeader: TStringList;
    procedure ParseFile(const aFileName: string);
    function RunRegex(const aText: string): TMatchCollection;
    procedure ParseMatch(const Matches: TMatchCollection);
    function GetCount: Integer;
    procedure SetComments(const Value: string); stdcall;
    function GetComments: string;
    function GetOptions: TOptionArray;
    function Save(const AFileName: string): Boolean;
		constructor Create; overload;
    procedure TextToHeader(const Comments: string);
    procedure ControlToOptions(const Container: TWinControl);
	public
		constructor Create(const aFileName: string); overload;
		constructor Create(const Comments: string; const Container: TWinControl); overload;
		/// <summary>
		///   Constructor to create a list of options not present in existing options
		/// </summary>
		/// <param name="AExistingOptions">
		///   Options that exist
		/// </param>
    constructor Create(const AExistingOptions: IRodentOptions); overload;
		destructor Destroy; override;
  end;

implementation

uses
  OptionDisplay,
  Guidelines;

resourcestring
	CStrSetoptionName = 'setoption name ';

constructor TRodentOptions.Create(const aFileName: string);
begin
	Create;
	ParseFile(aFileName);
end;

constructor TRodentOptions.Create(const Comments: string; const Container: TWinControl);
begin
	Create;
	TextToHeader(Comments);
	ControlToOptions(Container);
end;

constructor TRodentOptions.Create;
begin
	inherited Create;
	fHeader := TStringList.Create;
end;

destructor TRodentOptions.Destroy;
begin
  fHeader.Free;
  inherited;
end;

procedure TRodentOptions.ControlToOptions(const Container: TWinControl);
var
  OptionCount: Integer;
  i: Integer;
  OD: TOptionDisplay;
begin
  OptionCount := 0;
  for i := 0 to Container.ControlCount - 1 do
  begin
    if Container.Controls[i] is TOptionDisplay then
      Inc(OptionCount);
  end;
  SetLength(fOptions, OptionCount);
  OptionCount := 0;
  for i := 0 to Container.ControlCount - 1 do
  begin
    if Container.Controls[i] is TOptionDisplay then
    begin
      OD := Container.Controls[i] as TOptionDisplay;
      fOptions[OptionCount].Option := OD.Option;
      fOptions[OptionCount].Value := OD.Value;
      Inc(OptionCount);
    end;
  end;
end;

procedure TRodentOptions.TextToHeader(const Comments: string);
var
  sl: TStringList;
  line: string;
begin
  sl := TStringList.Create;
  try
    sl.Text := Comments;
    for line in sl do
    begin
      if line.StartsWith(';') then
        fHeader.Add(line)
      else
        fHeader.Add('; ' + line);
    end;
  finally
    sl.Free;
  end;
end;

function TRodentOptions.GetComments: string;
begin
  Result := fHeader.Text;
end;

function TRodentOptions.GetCount: Integer;
begin
  Result := Length(fOptions);
end;

function TRodentOptions.GetOptions: TOptionArray;
begin
  Result := fOptions;
end;

procedure TRodentOptions.ParseFile(const aFileName: string);
var
  lTextFile: TStringList;
  lLine: string;
begin
  lTextFile := TStringList.Create;
  try
    lTextFile.LoadFromFile(aFileName);
    for lLine in lTextFile do
    begin
      if lLine.Trim.StartsWith(';') then
      begin
        fHeader.Add(lLine.Trim);
      end;
    end;
     ParseMatch(RunRegex(lTextFile.Text));
  finally
    lTextFile.Free;
  end;

end;

procedure TRodentOptions.ParseMatch(const Matches: TMatchCollection);
var
  i: Integer;
begin
  SetLength(fOptions, Matches.Count);
  for i := 0 to Matches.Count - 1 do
  begin
    fOptions[i].Option := Matches.Item[i].Groups['option'].Value;
    fOptions[i].Value := Matches.Item[i].Groups['value'].Value;
  end;
end;

function TRodentOptions.RunRegex(const aText: string): TMatchCollection;
begin
  try
    Result := TRegEx.Matches(aText.Trim, 'setoption name (?<option>.+) value (?<value>.+)', [roNotEmpty]);
  except
    on E: ERegularExpressionError do begin
      raise;
    end;
  end;
end;

function TRodentOptions.Save(const AFileName: string): Boolean;
var
  sl: TStringList;
  i: Integer;
  line: string;
begin
  if (AFileName <> '') and
      TPath.HasValidPathChars(AFileName, False) and
      TPath.HasValidFileNameChars(ExtractFileName(AFileName), False) then
  begin
    sl := TStringList.Create;
    try
      for line in fHeader do
      begin
        if line.StartsWith(';') then
          sl.Add(line)
        else
          sl.Add('; ' + line);
      end;
      for i := Low(fOptions) to High(fOptions) do
      begin
        sl.Add('setoption name ' + fOptions[i].Option + ' value ' + fOptions[i].Value);
      end;
      sl.SaveToFile(AFileName);
      Result := True;
    finally
      sl.Free;
    end;
  end
  else
    Result := false;
end;

procedure TRodentOptions.SetComments(const Value: string);
begin
  fHeader.Text := Value;
end;

constructor ROption.Create(const aOption, aValue: string);
begin
  Option := aOption;
	Value := aValue;
end;

constructor TRodentOptions.Create(const AExistingOptions: IRodentOptions);
var
  i, j: Integer;
  Found: Boolean;
begin
  Create;
  fHeader.Text := AExistingOptions.Comments;
  for i := 0 to gGuidelines.Count - 1 do
  begin
    Found := False;
    for j := 0 to AExistingOptions.Count - 1 do
    begin
      if AExistingOptions.Options[j].Option = gGuidelines.Option[i] then
      begin
        Found := True;
        Break;
      end;
    end;
    if not Found then
    begin
      SetLength(fOptions, Length(fOptions) + 1);
      fOptions[Length(fOptions) - 1].Option := gGuidelines.Option[i];
      fOptions[Length(fOptions) - 1].Value := gGuidelines.DefaultValue[i];
    end;
  end;
end;

end.
