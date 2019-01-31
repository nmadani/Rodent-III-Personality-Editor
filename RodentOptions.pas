//  Copyright 2019 Navid Madani
//  Distributed under GNU General Public License Version 3.0, June 29, 2007
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
    Comment: string;
  public
    constructor Create(const aOption, aValue: string);
  end;

  TOptionArray = array of ROption;

  IRodentOptions = interface
  ['{EF928B5F-DD9E-4235-B073-384AC1FBE0C8}']
    function GetComments(Index: Integer): string;
    function GetCount: Integer;
    function GetHeader: string;
    function GetItems(Index: Integer): ROption;
    procedure SetHeader(const Value: string);
    function GetOptions(Index: Integer): string;
    procedure SetOptions(Index: Integer; const Value: string);
    function Save(const AFileName: string): Boolean;
    function MatchStringToOption(const aString: string; out Index: Integer): Boolean;
    procedure SetComments(Index: Integer; const Value: string);
    function GetValues(Index: Integer): string;
    procedure SetValues(Index: Integer; const Value: string);
    property Count: Integer read GetCount;
    property Header: string read GetHeader write SetHeader;
    property Comments[Index: Integer]: string read GetComments write SetComments;
    property Items[Index: Integer]: ROption read GetItems; default;
    property Options[Index: Integer]: string read GetOptions write SetOptions;
    property Values[Index: Integer]: string read GetValues write SetValues;
  end;

  TRodentOptions = class(TInterfacedObject, IRodentOptions)
  private
    fOptions: TOptionArray;
    fHeader: string;
    procedure ParseFile(const aFileName: string);
    function RunRegex(const aText: string): TMatchCollection;
    procedure ParseMatch(const Matches: TMatchCollection);
    procedure ParseComments(const aSL: TStringList);
    function GetCount: Integer;
    function GetItems(Index: Integer): ROption;
    procedure SetHeader(const Value: string);
    function GetHeader: string;
    function GetOptions(Index: Integer): string;
    procedure SetOptions(Index: Integer; const Value: string);
    function GetValues(Index: Integer): string;
    procedure SetValues(Index: Integer; const Value: string);
    function GetComments(Index: Integer): string;
    procedure SetComments(Index: Integer; const Value: string);
    function Save(const AFileName: string): Boolean;
		constructor Create; overload;
    procedure ControlToOptions(const Container: TWinControl);
    function MatchStringToOption(const aString: string; out Index: Integer): Boolean;
    function StringToComment(const aString: string): string;
    function CommentToString(const aString: string): string;
    function IsEmptyAsComment(const aString: string): Boolean;
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
  CStrIndexOutOfRange = 'Index out of range!';

const
  CStrSetoptionName = 'setoption name ';
  CRodentOptionRegex = 'setoption name (?<option>.+) value (?<value>.+)';

constructor TRodentOptions.Create(const aFileName: string);
begin
	Create;
	ParseFile(aFileName);
end;

constructor TRodentOptions.Create(const Comments: string; const Container: TWinControl);
begin
	Create;
  fHeader := StringToComment(Comments);
	ControlToOptions(Container);
end;

constructor TRodentOptions.Create;
begin
	inherited Create;
end;

destructor TRodentOptions.Destroy;
begin
  fHeader := '';
  inherited;
end;

function TRodentOptions.CommentToString(const aString: string): string;
var
  inSl: TStringList;
  outSl: TStringList;
  lLine: string;
begin
  Result := '';
  outSl := nil;
  inSl := TStringList.Create;
  try
    outSl := TStringList.Create;
    inSl.Text := aString;
    for lLine in inSl do
    begin
      if lLine.StartsWith('; ') then
        outSl.Add(lLine.Substring(2))
      else if lLine.StartsWith(';') then
        outSl.Add(lLine.Substring(1));
    end;
    Result := outSl.Text;
  finally
    inSl.Free;
    outSl.Free;
  end;
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

function TRodentOptions.GetHeader: string;
begin
  Result := CommentToString(fHeader);
end;

function TRodentOptions.GetItems(Index: Integer): ROption;
begin
  if (Index < Low(fOptions)) or (Index > High(fOptions)) then
    raise EArgumentOutOfRangeException.Create(CStrIndexOutOfRange);
  Result := fOptions[Index];
end;

function TRodentOptions.GetOptions(Index: Integer): string;
begin
  if (Index < Low(fOptions)) or (Index > High(fOptions)) then
    raise EArgumentOutOfRangeException.Create(CStrIndexOutOfRange);
  Result := fOptions[Index].Option;
end;

function TRodentOptions.GetValues(Index: Integer): string;
begin
  if (Index < Low(fOptions)) or (Index > High(fOptions)) then
    raise EArgumentOutOfRangeException.Create(CStrIndexOutOfRange);
  Result := fOptions[Index].Value;
end;

function TRodentOptions.IsEmptyAsComment(const aString: string): Boolean;
begin
  Result := aString.Replace(';', '', [rfReplaceAll]).Trim.IsEmpty;
end;

function TRodentOptions.GetComments(Index: Integer): string;
begin
  if (Index < Low(fOptions)) or (Index > High(fOptions)) then
    raise EArgumentOutOfRangeException.Create(CStrIndexOutOfRange);
  Result := CommentToString(fOptions[Index].Comment);
end;

function TRodentOptions.GetCount: Integer;
begin
  Result := Length(fOptions);
end;

function TRodentOptions.MatchStringToOption(const aString: string; out Index: Integer): Boolean;
var
  i: Integer;
begin
  for i := Low(fOptions) to High(fOptions) do
  begin
    if aString.Contains(fOptions[i].Option) then
    begin
      Index := i;
      Exit(True);
    end;
  end;
  Index := -1;
  Result := False;
end;

procedure TRodentOptions.ParseComments(const aSL: TStringList);
var
  i: Integer;
  OptIndex: Integer;
  lComment: string;
begin
  i := 0;
  // Discard the header comments
  while (i < aSL.Count) and (aSl[i].Trim.StartsWith(';')) do
    Inc(i);
  while (i < aSL.Count) do
  begin
    lComment := '';
    while aSL[i].Trim.StartsWith(';') do
    begin
      if lComment.IsEmpty then
        lComment := aSL[i]
      else
        lComment := lComment + sLineBreak + aSL[i];
      Inc(i);
    end;
    if not (lComment.IsEmpty) and (i < aSL.Count) then
    begin
      if MatchStringToOption(aSL[i], OptIndex) then
        fOptions[OptIndex].Comment := lComment;
    end;
    Inc(i);
  end;
end;

procedure TRodentOptions.ParseFile(const aFileName: string);
var
  lSL: TStringList;
  lLine: string;
begin
  lSL := TStringList.Create;
  try
    lSL.LoadFromFile(aFileName);
    for lLine in lSL do
    begin
      if lLine.Trim.StartsWith(';') then
      begin
        if fHeader.IsEmpty then
          fHeader := lLine.Trim
        else
          fHeader := fHeader + sLineBreak + lLine.Trim;
      end
      else
        Break;
    end;
    ParseMatch(RunRegex(lSL.Text));
    ParseComments(lSL);
  finally
    lSL.Free;
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
    Result := TRegEx.Matches(aText.Trim, CRodentOptionRegex, [roNotEmpty]);
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
begin
  if (AFileName <> '') and
      TPath.HasValidPathChars(AFileName, False) and
      TPath.HasValidFileNameChars(ExtractFileName(AFileName), False) then
  begin
    sl := TStringList.Create;
    try
      if not IsEmptyAsComment(fHeader) then
      begin
        sl.Text := fHeader;
        sl.Add(sLineBreak); // to separate header from option-specific comments
      end;
      for i := Low(fOptions) to High(fOptions) do
      begin
        if not IsEmptyAsComment(fOptions[i].Comment) then
          sl.Add(fOptions[i].Comment.Trim);
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

procedure TRodentOptions.SetComments(Index: Integer; const Value: string);
begin
  if (Index < Low(fOptions)) or (Index > High(fOptions)) then
    raise EArgumentOutOfRangeException.Create(CStrIndexOutOfRange);
  fOptions[Index].Comment := StringToComment(Value);
end;

procedure TRodentOptions.SetHeader(const Value: string);
begin
  fHeader := StringToComment(Value);
end;

procedure TRodentOptions.SetOptions(Index: Integer; const Value: string);
begin
  if (Index < Low(fOptions)) or (Index > High(fOptions)) then
    raise EArgumentOutOfRangeException.Create(CStrIndexOutOfRange);
  fOptions[Index].Option := Value;
end;

procedure TRodentOptions.SetValues(Index: Integer; const Value: string);
begin
  if (Index < Low(fOptions)) or (Index > High(fOptions)) then
    raise EArgumentOutOfRangeException.Create(CStrIndexOutOfRange);
  fOptions[Index].Value := Value;
end;

function TRodentOptions.StringToComment(const aString: string): string;
var
  slIn: TStringList;
  slOut: TStringList;
  line: string;
begin
  Result := '';
  slOut := nil;
  slIn := TStringList.Create;
  try
    slOut := TStringList.Create;
    slIn.Text := aString;
    for line in slIn do
      slOut.Add('; ' + line);
    Result := slOut.Text;
  finally
    slIn.Free;
    slOut.Free;
  end;
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
  fHeader := AExistingOptions.Header;
  for i := 0 to gGuidelines.Count - 1 do
  begin
    Found := False;
    for j := 0 to AExistingOptions.Count - 1 do
    begin
      if AExistingOptions.Options[j] = gGuidelines.Option[i] then
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
